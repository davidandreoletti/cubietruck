WORKING_DIR=~/tdl/cubietruck
SCRIPT_DIR=${SCRIPT_DIR:-"/media/sf_SD_OS_SETUP_WORKSPACE"}

mkdir -pv ${WORKING_DIR}
cd ${WORKING_DIR}
bash -x ${SCRIPT_DIR}/manualbuild-setup.sh
bash -x ${SCRIPT_DIR}/manualbuild-build-sdcardimage.sh
bash -x ${SCRIPT_DIR}/manualbuild-setup-serialdevice.sh
cd -
