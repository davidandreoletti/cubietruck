#!/bin/bash
SCRIPT_DIR=${SCRIPT_DIR:-`pwd`}
. ${SCRIPT_DIR}/lib.sh

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
U_BOOT_SUNXI_BOARD_MODEL="Cubietruck"
U_BOOT_SUNXI_DIR=${U_BOOT_SUNXI_DIR:-"`pwd`/u-boot-sunxi"}
U_BOOT_SUNXI_BOARD_FEX_ORIG_FILE="`pwd`/sunxi-boards/sys_config/a20/cubietruck.fex"
U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE="${OUTPUT_DIR}/cubietruck.fex"
U_BOOT_SUNXI_BOARD_FEX_BIN_FILE=${OUTPUT_DIR}/${SCRIPT_BIN_FILE}
U_BOOT_SUNXI_BOARD_UBOOT_WITH_SPL_BIN_FILE=${U_BOOT_SUNXI_BOARD_UBOOT_WITH_SPL_BIN_FILE:-"${U_BOOT_SUNXI_DIR}/u-boot-sunxi-with-spl.bin"}
U_BOOT_SUNXI_BOARD_UBOOTSPL_BIN_FILE=${U_BOOT_SUNXI_BOARD_UBOOTSPL_BIN_FILE:-"${U_BOOT_SUNXI_DIR}/spl/u-boot-spl.bin"}
U_BOOT_SUNXI_BOARD_UBOOT_BIN_FILE=${U_BOOT_SUNXI_BOARD_UBOOT_BIN_FILE:-"${U_BOOT_SUNXI_DIR}/u-boot.bin"}
U_BOOT_SUNXI_PULL=${U_BOOT_SUNXI_PULL:-false}
U_BOOT_SUNXI_CLEAN=${U_BOOT_SUNXI_CLEAN:-false}
U_BOOT_SUNXI_BUILD_SKIP=${U_BOOT_SUNXI_BUILD_SKIP:-false}
MAC_ETH0=${MAC_ETH0:-"000000000000"}
LINUX_SUNXI_DIR=${LINUX_SUNXI_DIR:-"`pwd`/linux-sunxi"}
LINUX_SUNXI_KERNEL_BRANCH_NAME=${LINUX_SUNXI_KERNEL_BRANCH_NAME:-"sunxi-3.4"}
LINUX_SUNXI_KERNEL_DEFAULT_CONFIG=${LINUX_SUNXI_KERNEL_DEFAULT_CONFIG:-"sun7i_defconfig"}
LINUX_SUNXI_KERNEL_BOOT_ARGS=${LINUX_SUNXI_KERNEL_BOOT_ARGS:-"console=ttyS0,115200 console=tty0 root=/dev/mmcblk0p2 rootwait panic=10 loglevel=8 rootfstype=ext4 rootflags=discard"}
LINUX_SUNXI_KERNEL_BOOT_ARGS_EXTRA=${LINUX_SUNXI_KERNEL_BOOT_ARGS_EXTRA:-""}
LINUX_SUNXI_PULL=${LINUX_SUNXI_PULL:-false}
LINUX_SUNXI_CLEAN=${LINUX_SUNXI_CLEAN:-false}
LINUX_SUNXI_BUILD_SKIP=${LINUX_SUNXI_BUILD_SKIP:-false}
LINUX_SUNXI_CONFIG_SKIP=${LINUX_SUNXI_CONFIG_SKIP:-false}
SDCARD_IMG_FILE="${OUTPUT_DIR}/sdcard.img"
SDCARD_IMG_SIZE=${SDCARD_IMG_SIZE:-"4096"} # 4Gb (for dd's count parameters)
SDCARD_LOOPBACK_DEVICE="UNDEFINED"
ROOTFS_FILE_COMPRESSED=${ROOTFS_FILE_COMPRESSED:-"UNDEFINED"}
BOOT_PARTITION_SIZE=64
BOOT_PARTITION_TYPE=vfat
ROOT_PARTITION_TYPE=ext4

function mountImageAsLoopbackDevice() {
	local d=$(losetup -fv $1 | grep "Loop device is" | cut -d' ' -f4)
	echo "$d"
}

function umountLoopbackDevice() {
	sleep 5
	losetup -d $1
}

# arg1: size in bytes
# arg2: heads
# arg3: sectors
# arg4: bytes per sector
function computeDeviceGeometryCylinders() {
	echo "$1 / $2 / $3 / $4" | bc
}

function mountPartitionsAsLoopbackDevices() {
	local mapping=`sudo kpartx -av "$1"`
	ls -al /dev/mapper/
	local mappedCard=`echo "$mapping" | grep "add map" | head -n 1 | cut -d' ' -f3` 
	local cardp="/dev/mapper/${mappedCard:0:5}p"
	export cardboot=${cardp}1
	export cardroot=${cardp}2
	sleep 3
}

function umountPartitionsAsLoopbackDevices() {
	sudo kpartx -d "$1" 
}

${OUTPUT_CLEAN} && rm -rf "${OUTPUT_DIR}"
mkdir "${OUTPUT_DIR}"

logINFO "Build bootloader u-boot-sunxi"

if ! ${U_BOOT_SUNXI_BUILD_SKIP} ;
then
	cd ${U_BOOT_SUNXI_DIR}
	${U_BOOT_SUNXI_PULL} && git pull
	${U_BOOT_SUNXI_CLEAN} && make clean
	make distclean CROSS_COMPILE="${TOOLCHAIN}"
	time make "${U_BOOT_SUNXI_BOARD_MODEL}" CROSS_COMPILE="${TOOLCHAIN}"
	test -e "${U_BOOT_SUNXI_BOARD_UBOOTSPL_BIN_FILE}" || logAndExit NO_FILE 1
	test -e "${U_BOOT_SUNXI_BOARD_UBOOT_BIN_FILE}" || logAndExit NO_FILE 1
	cd -
fi

logINFO "Update sys_config for ${U_BOOT_SUNXI_BOARD_MODEL}"

rm -v "${U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE}" 
cp -v "${U_BOOT_SUNXI_BOARD_FEX_ORIG_FILE}" "${U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE}" || logINFO NO_FEX_COPIED 1
echo [dynamic] >> "${U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE}" # http://linux-sunxi.org/EMAC
echo MAC = "${MAC_ETH0}" >> "${U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE}"

logINFO "Create ${U_BOOT_SUNXI_BOARD_FEX_BIN_FILE} from ${U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE}" 

test -e ${FEX2BIN_EXEC_FILE};
cd ${SUNXI_TOOLS_DIR}
make fex2bin
cd -
${FEX2BIN_EXEC_FILE} "${U_BOOT_SUNXI_BOARD_FEX_CUSTOM_FILE}" "${U_BOOT_SUNXI_BOARD_FEX_BIN_FILE}"

logINFO "Build kernel"

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
	${LINUX_SUNXI_CONFIG_SKIP} || make ARCH=arm CROSS_COMPILE="${TOOLCHAIN}" menuconfig
	echo "Build kernel image and modules"
	nCores=`grep -c ^processor /proc/cpuinfo`
	nJobs=`echo ${nCores}*2 | bc`
	time make -j${nJobs} ARCH=arm CROSS_COMPILE="${TOOLCHAIN}" uImage modules
fi

KERNEL_VERSION=`make kernelversion`
KERNEL_OUTPUT_MODULES_VERSION_DIR="${KERNEL_OUTPUT_MODULES_DIR}/${KERNEL_VERSION}"
echo "Install kernel's full module tree"
test -d "${KERNEL_OUTPUT_MODULES_VERSION_DIR}"* || make ARCH=arm CROSS_COMPILE="${TOOLCHAIN}" INSTALL_MOD_PATH="${MODULES_PATH}" modules_install
cp -v "${KERNEL_IMG}" "${OUTPUT_DIR}/" || logAndExit NO_KERNEL_UIMAGE 1
test -d "${KERNEL_OUTPUT_MODULES_VERSION_DIR}"* || logAndExit NO_KERNEL_MODULES 1
cd -

logINFO "Create virtual SD card device" 

if [ ! -f "${SDCARD_IMG_FILE}" ]
then
	dd if=/dev/zero of="${SDCARD_IMG_FILE}" bs=1M count=${SDCARD_IMG_SIZE}
else
	logAndExit "NO_SDCARD_IMAGE_FILE"
fi

# sudo losetup -v "${SDCARD_LOOPBACK_DEVICE}" "${SDCARD_IMG_FILE}"
card=$(mountImageAsLoopbackDevice "${SDCARD_IMG_FILE}")
umountLoopbackDevice "${card}"

logINFO "Cleaning SD Card"

card=$(mountImageAsLoopbackDevice "${SDCARD_IMG_FILE}")
sudo dd if=/dev/zero of=$card bs=1M count=1 || logAndExit "Failed to clean SD Card" 1
umountLoopbackDevice "${card}"


logINFO "Partitioning SD Card"

deviceSize=$(stat -c%s ${SDCARD_IMG_FILE})
deviceHeads=255
deviceSectors=63
deviceBytesPerSector=512
deviceCylinders=$(computeDeviceGeometryCylinders ${deviceSize} ${deviceHeads} ${deviceSectors} ${deviceBytesPerSector})

card=$(mountImageAsLoopbackDevice "${SDCARD_IMG_FILE}")
x=$(expr $BOOT_PARTITION_SIZE \* 2048)
sudo sfdisk --force --in-order -L -uS -H ${deviceHeads} -S ${deviceSectors} -C ${deviceCylinders} ${card} <<-EOT
2048,$x,c
,,L
EOT
[ $? -eq 0 ] || logAnExit "Partitionning failed" 1
umountLoopbackDevice "${card}"

card=$(mountImageAsLoopbackDevice "${SDCARD_IMG_FILE}")
sudo sfdisk --force -L -R ${card} || logAndExit "Cannot reload media"
umountLoopbackDevice "${card}"

logINFO "Formatting partitions"

mountPartitionsAsLoopbackDevices "${SDCARD_IMG_FILE}"

sudo mkfs.${BOOT_PARTITION_TYPE} -n BOOT ${cardboot}
sudo mkfs.${ROOT_PARTITION_TYPE} -L ROOTFS ${cardroot}

umountPartitionsAsLoopbackDevices "${SDCARD_IMG_FILE}"

logINFO "Installing bootloader on SD Card" 
# http://linux-sunxi.org/Bootable_SD_card#SD_Card_Layout

card=$(mountImageAsLoopbackDevice "${SDCARD_IMG_FILE}")
# Make MMC 0 detected
sudo dd if="${U_BOOT_SUNXI_BOARD_UBOOT_WITH_SPL_BIN_FILE}" of=$card bs=1024 seek=8
# Does not make MMC 0 detected
#sudo dd if="${U_BOOT_SUNXI_BOARD_UBOOTSPL_BIN_FILE}" of=$card bs=1024 seek=8
#sudo dd if="${U_BOOT_SUNXI_BOARD_UBOOT_BIN_FILE}" of=$card bs=1024 seek=32
umountLoopbackDevice "${card}"

mountPartitionsAsLoopbackDevices "${SDCARD_IMG_FILE}"

logINFO "Installing Kernel"

sudo mount -t ${BOOT_PARTITION_TYPE} ${cardboot} /mnt
sudo cp linux-sunxi/arch/arm/boot/uImage /mnt/
sudo cp "${U_BOOT_SUNXI_BOARD_FEX_BIN_FILE}" /mnt/
sudo umount /mnt/

BOOT_CMD_FILE="/mnt/boot.cmd"
BOOT_SCR_FILE="/mnt/boot.src"
BOOT_UENV_FILE="/mnt/uEnv.txt"

logINFO "Generating ${BOOT_UENV_FILE}"

sudo mount -t ${BOOT_PARTITION_TYPE} ${cardboot} /mnt
sudo echo "setenv bootargs ${LINUX_SUNXI_KERNEL_BOOT_ARGS} ${LINUX_SUNXI_KERNEL_BOOT_ARGS_EXTRA}" >> ${BOOT_UENV_FILE} 
# Display U-Boot env variables
sudo echo "printenv" >> ${BOOT_UENV_FILE} 
# Load kernel and script.bin from partition
sudo echo "fatload mmc 0 0x43000000 script.bin || ext2load mmc 0 0x43000000 boot/script.bin fatload mmc 0 0x48000000 uImage || ext2load mmc 0 0x48000000 uImage boot/uImage bootm 0x48000000" >> ${BOOT_UENV_FILE}
ls -al /mnt/
sudo umount /mnt

#logINFO "Generating boot.cmd"
#
#sudo mount -t ${BOOT_PARTITION_TYPE} ${cardboot} /mnt
#sudo echo "setenv bootargs ${LINUX_SUNXI_KERNEL_BOOT_ARGS} ${LINUX_SUNXI_KERNEL_BOOT_ARGS_EXTRA}" >> ${BOOT_CMD_FILE} 
## Display U-Boot env variables
#sudo echo "printenv" >> ${BOOT_CMD_FILE} 
## Load kernel and script.bin from partition
#sudo echo "fatload mmc 0 0x43000000 script.bin || ext2load mmc 0 0x43000000 boot/script.bin fatload mmc 0 0x48000000 uImage || ext2load mmc 0 0x48000000 uImage boot/uImage bootm 0x48000000" >> ${BOOT_CMD_FILE} 
#sudo umount /mnt

#logINFO "Generate boot.src"
#	
#sudo mount -t ${BOOT_PARTITION_TYPE} ${cardboot} /mnt
#sudo mkimage -C none -n "${U_BOOT_SUNXI_BOARD_MODEL} - U-Boot script image" -A arm -T script -d ${BOOT_CMD_FILE} ${BOOT_SCR_FILE} 
#ls -al /mnt
#sudo umount /mnt

logINFO "Installing kernel into rootfs"

sudo mount -t ${ROOT_PARTITION_TYPE} ${cardroot} /mnt
sudo mkdir -p /mnt/lib/modules
sudo rm -rf /mnt/lib/modules/
sudo cp -r "${KERNEL_OUTPUT_LIB_DIR}" /mnt/
sudo umount /mnt

logINFO "Installing rootfs"

sudo mount -t ${ROOT_PARTITION_TYPE} ${cardroot} /mnt
TMP_DIR=`mktemp -d`
cd "${TMP_DIR}"
unp "${ROOTFS_FILE_COMPRESSED}" > /dev/null
cd -
cd "${TMP_DIR}/binary"
cp -r ./ /mnt
cd -
rm -rf ${TMP_DIR}
ls -al /mnt/
sudo umount /mnt

logINFO "SD Card Image done! Copy it over to a real SD Card and boot !".

umountPartitionsAsLoopbackDevices "${SDCARD_IMG_FILE}"

echo 'DONE :)' 
