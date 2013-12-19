#!/bin/bash
set -x
SCRIPT_DIR=${SCRIPT_DIR:-`pwd`}
. ${SCRIPT_DIR}/lib.sh

MNT_ROOTFS_DIR=${1:-"/mnt"}
ROOTFS_CUSTOM_DIR=${2:-"${SCRIPT_DIR}/custom/rootfs"}

test -d "${MNT_ROOTFS_DIR}" || f_logAndExit "NO_MOUNTED_ROOTFS_DIR" 1
test -d "${ROOTFS_CUSTOM_DIR}" || f_logAndExit "NO_ROOTFS_CUSTOM_DIR" 1

f_logINFO "Customizing rootfs ..."

rsync -av "${ROOTFS_CUSTOM_DIR}/" "${MNT_ROOTFS_DIR}" 
