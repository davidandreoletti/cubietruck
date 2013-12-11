WORKING_DIR=~/tdl/cubietruck
SCRIPT_DIR=${SCRIPT_DIR:-"/media/sf_SD_OS_SETUP_WORKSPACE"}

mkdir -pv ${WORKING_DIR}
cd ${WORKING_DIR}
bash -x ${SCRIPT_DIR}/manualbuild-setup.sh
bash -x ${SCRIPT_DIR}/manualbuild-build-uboot.sh
bash -x ${SCRIPT_DIR}/manualbuild-build-kernel.sh
bash -x ${SCRIPT_DIR}/manualbuild-build-rootfs.sh
bash -x ${SCRIPT_DIR}/manualbuild-build-hwpack.sh
bash -x ${SCRIPT_DIR}/manualbuild-build-sdcardimage.sh
bash -x ${SCRIPT_DIR}/manualbuild-install-sdcardimage-on-device.sh
cd -
