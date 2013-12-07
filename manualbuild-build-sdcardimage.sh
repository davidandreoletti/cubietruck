# Output dir for all generated files for the board (kernel, bin, etc)
OUTPUT_DIR="`pwd`/output"
OUTPUT_CLEAN=${OUTPUT_CLEAN:-true}
# Toolchain: http://linux-sunxi.org/Toolchain
TOOLCHAIN="arm-linux-gnueabi-"
SCRIPT_BIN_FILE="script.bin"
SUNXI_TOOLS_DIR=${SUNXI_TOOLS_DIR:-"`pwd`/sunxi-tools"}
FEX2BIN_EXEC_FILE="${SUNXI_TOOLS_DIR}/fex2bin"
# Board Name
# Value: https://github.com/linux-sunxi/u-boot-sunxi/blob/sunxi/boards.cfg
U_BOOT_SUNXI_BOARD_MODEL="cubietruck"
U_BOOT_SUNXI_DIR=${U_BOOT_SUNXI_DIR:-"`pwd`/u-boot-sunxi"}
U_BOOT_SUNXI_BOARD_FEX_ORIG_FILE="`pwd`/sunxi-boards/sys_config/a20/cubietruck.fex"
U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE="${OUTPUT_DIR}/cubietruck.fex"
U_BOOT_SUNXI_BOARD_FEX_BIN_FILE=${OUTPUT_DIR}/${SCRIPT_BIN_FILE}
U_BOOT_SUNXI_BOARD_UBOOTSPL_BIN_FILE=${U_BOOT_SUNXI_BOARD_UBOOTSPL_BIN_FILE:-"${U_BOOT_SUNXI_DIR}/spl/u-boot-spl.bin"}
U_BOOT_SUNXI_BOARD_UBOOT_BIN_FILE=${U_BOOT_SUNXI_BOARD_UBOOT_BIN_FILE:-"${U_BOOT_SUNXI_DIR}/u-boot.bin"}
U_BOOT_SUNXI_PULL=${U_BOOT_SUNXI_PULL:-false}
U_BOOT_SUNXI_CLEAN=${U_BOOT_SUNXI_CLEAN:-false}
U_BOOT_SUNXI_BUILD_SKIP=${U_BOOT_SUNXI_BUILD_SKIP:-false}
MAC_ETH0=${MAC_ETH0:-"000000000000"}
LINUX_SUNXI_DIR=${LINUX_SUNXI_DIR:-"`pwd`/linux-sunxi"}
LINUX_SUNXI_KERNEL_BRANCH_NAME=${LINUX_SUNXI_KERNEL_BRANCH_NAME:-"sunxi-3.4"}
LINUX_SUNXI_KERNEL_DEFAULT_CONFIG=${LINUX_SUNXI_KERNEL_DEFAULT_CONFIG:-"sun7i_defconfig"}
LINUX_SUNXI_PULL=${LINUX_SUNXI_PULL:-false}
LINUX_SUNXI_CLEAN=${LINUX_SUNXI_CLEAN:-false}
LINUX_SUNXI_BUILD_SKIP=${LINUX_SUNXI_BUILD_SKIP-:false}
SDCARD_IMG_FILE="${OUTPUT_DIR}/sdcard.img"
#SDCARD_IMG_FILE="`pwd`/sdcard.img"
SDCARD_IMG_SIZE=${SDCARD_IMG_SIZE:-"4096"} # 4Gb (for dd's count parameters)
SDCARD_LOOPBACK_DEVICE="UNDEFINED"
ROOTFS_FILE_COMPRESSED=${ROOTFS_FILE_COMPRESSED:-"`pwd`/linaro-raring-nano-20131205-573.tar.gz"}

function logAndExit() {
	echo $1;
	exit $2;
}

function logINFO() {
	echo "----------------------------------------"
	echo $1
	echo "----------------------------------------"
}

logINFO "Setup"

{
	${OUTPUT_CLEAN} && rm -rf "${OUTPUT_DIR}"
	mkdir "${OUTPUT_DIR}"
}

logINFO "Build bootloader u-boot-sunxi"

{
	if ! ${U_BOOT_SUNXI_BUILD_SKIP} ;
	then
		cd ${U_BOOT_SUNXI_DIR}
		${U_BOOT_SUNXI_PULL} && git pull
		${U_BOOT_SUNXI_CLEAN} && make clean
		make distclean CROSS_COMPILE="${TOOLCHAIN}"
		time make "${U_BOOT_SUNXI_BOARD_MODEL}" CROSS_COMPILE="${TOOLCHAIN}"
		test -e spl/u-boot-spl.bin || logAndExit NO_FILE 1
		test -e u-boot.bin || logAndExit NO_FILE 1
		cd -
	fi
}

# http://linux-sunxi.org/EMAC
logINFO "Update sys_config for ${U_BOOT_SUNXI_BOARD_MODEL}"

{
	rm -v "${U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE}" 
	cp -v "${U_BOOT_SUNXI_BOARD_FEX_ORIG_FILE}" "${U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE}"
	echo [dynamic] >> "${U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE}"
	echo MAC = "${MAC_ETH0}" >> "${U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE}"
}

logINFO "Create ${U_BOOT_SUNXI_BOARD_FEX_BIN_FILE} from ${U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE}" 

{
	test -e ${FEX2BIN_EXEC_FILE};
	cd ${SUNXI_TOOLS_DIR}
	make fex2bin
	cd -
	${FEX2BIN_EXEC_FILE} "${U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE}" "${U_BOOT_SUNXI_BOARD_FEX_BIN_FILE}"
}

logINFO "Build kernel"

{
	MODULES_PATH="${OUTPUT_DIR}"
	KERNEL_IMG="arch/arm/boot/uImage"
	KERNEL_OUTPUT_LIB_DIR="${MODULES_PATH}/lib"
	KERNEL_OUTPUT_MODULES_DIR="${KERNEL_OUTPUT_LIB_DIR}/modules"
	cd ${LINUX_SUNXI_DIR} 
	if ! ${LINUX_SUNXI_BUILD_SKIP} ;
	then
		${LINUX_SUNXI_PULL} && git pull && git checkout -b "${LINUX_SUNXI_KERNEL_BRANCH_NAME}"
		${LINUX_SUNXI_CLEAN} && make distclean
		echo "Load default kernel config"
		make ARCH=arm CROSS_COMPILE="${TOOLCHAIN}" "${LINUX_SUNXI_KERNEL_DEFAULT_CONFIG}"
		echo "Manually configure kernel config"
		make ARCH=arm CROSS_COMPILE="${TOOLCHAIN}" menuconfig
		echo "Build kernel image and modules"
		nCores=`grep -c ^processor /proc/cpuinfo`
		nJobs=`echo ${nCores}*2 | bc`
		time make -j${nJobs} ARCH=arm CROSS_COMPILE="${TOOLCHAIN}" uImage modules
		KERNEL_VERSION=`make kernelversion`
	fi
	KERNEL_OUTPUT_MODULES_VERSION_DIR="${KERNEL_OUTPUT_MODULES_DIR}/${KERNEL_VERSION}/"
	echo "Install kernel's full module tree"
	test -d "${KERNEL_OUTPUT_MODULES_VERSION_DIR}" || make ARCH=arm CROSS_COMPILE="${TOOLCHAIN}" INSTALL_MOD_PATH="${MODULES_PATH}" modules_install
	cp -v "${KERNEL_IMG}" "${OUTPUT_DIR}/" || logAndExit NO_KERNEL_UIMAGE 1
	test -d "${KERNEL_OUTPUT_MODULES_VERSION_DIR}" || logAndExit NO_KERNEL_MODULES 1
	#make kernelrelease
	#make image_image 
	cd -
}

logINFO "Create virtual SD card" 

SDCARD_LOOPBACK_DEVICE=`sudo losetup -f`

{
	if [ ! -f "${SDCARD_IMG_FILE}" ]
	then
		dd if=/dev/zero of="${SDCARD_IMG_FILE}" bs=1M count=${SDCARD_IMG_SIZE}
	fi
	sudo losetup -v "${SDCARD_LOOPBACK_DEVICE}" "${SDCARD_IMG_FILE}" 
}

logINFO "Identifying SD Card"

export card=${SDCARD_LOOPBACK_DEVICE}	

export cardSize=`sudo fdisk -l ${card} | grep Disk | awk '{print $5}'`
export cardTracks=63
export cardSectorSize=512
export cardHeads=255
export cardCylinders=`echo ${cardSize}/${cardHeads}/${cardTracks}/${cardSectorSize}| bc`
echo "SD Card Device      : ${card}"
echo "SD Card Size        : ${cardSize}"
echo "SD Card #Heads      : ${cardHeads}"
echo "SD Card #Cylinders  : ${cardCylinders}"
echo "SD Card #Tracks     : ${cardTracks}"
echo "SD Card Sector size : ${cardSectorSize}"

logINFO "Cleaning SD Card"

{
	sudo dd if=/dev/zero of=$card bs=1M count=1
	sudo sfdisk -u S -l ${card}
}

logINFO "Installing bootloader on SD Card" 
# http://linux-sunxi.org/Bootable_SD_card#SD_Card_Layout
{
	sudo dd if="${U_BOOT_SUNXI_BOARD_UBOOTSPL_BIN_FILE}" of=$card bs=1024 seek=8
	sudo dd if="${U_BOOT_SUNXI_BOARD_UBOOT_BIN_FILE}" of=$card bs=1024 seek=40
}

logINFO "Partitioning SD Card"

{
sudo sfdisk -f -R $card
cat <<EOT | sudo sfdisk --in-order -uM $card
1,16,c
,,L
EOT
	sudo losetup -v -d "${SDCARD_LOOPBACK_DEVICE}"
	sudo sfdisk -u S -l ${card}
}



{
	mapping=`sudo kpartx -av "${SDCARD_IMG_FILE}"`
	mappedCard=`echo "$mapping" | grep "add map" | head -n 1 | cut -d' ' -f3` 
	export cardp="/dev/mapper/${mappedCard:0:5}p"
	sudo mkfs.vfat -n BOOT ${cardp}1
	sudo mkfs.ext4 -L ROOTFS ${cardp}2

}

export cardroot=${cardp}2

logINFO "Installing Kernel"

{
	sudo mount ${cardp}1 /mnt/
	cp linux-sunxi/arch/arm/boot/uImage /mnt/
	cp "${U_BOOT_SUNXI_BOARD_FEX_BIN_FILE}" /mnt/
	sudo umount /mnt/
}

logINFO "Mount rootfs"

{
	sudo mount ${cardroot} /mnt/
	#tar -C /mnt/ -xjpf "${ROOTFS_FILE_COMPRESSED}"
	cd /mnt/
	unp "${ROOTFS_FILE_COMPRESSED}"
	cd -
	sudo umount /mnt
}

BOOT_CMD_FILE="/mnt/boot.cmd"
BOOT_SCR_FILE="/mnt/boot.scr"

logINFO "Create boot.cmd"
{
	sudo mount ${cardp}1 /mnt
	# U-boot will pass bootargs content to the Linux kernel as boot arguments (aka command line)
	## http://www.denx.de/wiki/view/DULG/UBootEnvVariables
	# Kernel boot arguments:
	## Most are documented here: https://www.kernel.org/doc/Documentation/kernel-parameters.txt
	### /dev/mmcblk0pX: https://www.kernel.org/doc/Documentation/mmc/mmc-dev-parts.txt
	sudo echo "setenv bootargs console=ttyS0,115200 console=tty0 root=/dev/mmcblk0p2 rootwait panic=10 ${extra}" >> ${BOOT_CMD_FILE} 
	# Display U-Boot env variables
	sudo echo "printenv" >> ${BOOT_CMD_FILE} 
	# Load kernel and script.bin from partition
	sudo echo "fatload mmc 0 0x43000000 script.bin || ext2load mmc 0 0x43000000 boot/script.bin fatload mmc 0 0x48000000 uImage || ext2load mmc 0 0x48000000 uImage boot/uImage bootm 0x48000000" >> ${BOOT_CMD_FILE} 
	sudo umount /mnt
}

logINFO "Generate boot.src"
{
	sudo mount ${cardp}1 /mnt
	sudo mkimage -C none -n "${U_BOOT_SUNXI_BOARD_MODEL} - U-Boot script image" -A arm -T script -d ${BOOT_CMD_FILE} ${BOOT_SCR_FILE} 
	sudo umount /mnt
}

logINFO "Installing kernel into rootfs"

{
	sudo mount ${cardroot} /mnt
	sudo mkdir -p /mnt/lib/modules
	sudo rm -rf /mnt/lib/modules/
	sudo cp -rv "${KERNEL_OUTPUT_LIB_DIR}" /mnt/
	sudo umount /mnt
}

logINFO "SD Card Image done! Copy it over to a real SD Card and boot !".

{
	sudo kpartx -d "${SDCARD_IMG_FILE}" 
}

echo 'DONE :)' 
