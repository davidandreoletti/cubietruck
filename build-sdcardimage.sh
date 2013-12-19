WORKING_DIR=${WORKING_DIR:-"`pwd`"}
SCRIPT_DIR=${SCRIPT_DIR:-"`pwd`"}

export WORKING_DIR="${WORKING_DIR}"
export SCRIPT_DIR="${SCRIPT_DIR}"
export ROOTFS_FILE_COMPRESSED="${WORKING_DIR}/rootfs.tar.gz"
export LINUX_SUNXI_GIT_URL="https://github.com/patrickhwood/linux-sunxi.git" 

mkdir -pv ${WORKING_DIR}
cd ${WORKING_DIR}
${SCRIPT_DIR}/prerequisites.sh
${SCRIPT_DIR}/build-kernel-bootloader.sh
#${SCRIPT_DIR}/build-uboot.sh
#${SCRIPT_DIR}/build-kernel.sh
#${SCRIPT_DIR}/build-rootfs.sh
#${SCRIPT_DIR}/build-hwpack.sh
#${SCRIPT_DIR}/build-sdcardimage.sh
#${SCRIPT_DIR}/install-sdcardimage-on-device.sh
cd -
