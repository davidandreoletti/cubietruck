WORKING_DIR=${WORKING_DIR:-"`pwd`"}
SCRIPT_DIR=${SCRIPT_DIR:-"`pwd`"}

export ROOTFS_FILE_COMPRESSED="${WORKING_DIR}/rootfs.tar.gz"

mkdir -pv ${WORKING_DIR}
cd ${WORKING_DIR}
${SCRIPT_DIR}/manualbuild-setup.sh
${SCRIPT_DIR}/manualbuild-build-kernel-bootloader.sh
#${SCRIPT_DIR}/manualbuild-build-uboot.sh
#${SCRIPT_DIR}/manualbuild-build-kernel.sh
#${SCRIPT_DIR}/manualbuild-build-rootfs.sh
#${SCRIPT_DIR}/manualbuild-build-hwpack.sh
#${SCRIPT_DIR}/manualbuild-build-sdcardimage.sh
#${SCRIPT_DIR}/manualbuild-install-sdcardimage-on-device.sh
cd -
