#!/bin/bash
SCRIPT_DIR=${SCRIPT_DIR:-`pwd`}
. ${SCRIPT_DIR}/lib.sh

SDCARD_DEVICE=${SDCARD_DEVICE:-"UNKNOWN"}
SDCARD_IMAGE_FILE=${SDCARD_IMAGE_FILE:-"`pwd`/sdcard.img"}

test -d "${SDCARD_DEVICE}" || f_logAndExit "NO_SD_CARD_DEVICE" 1
test -e "${SDCARD_IMAGE_FILE}" || f_logAndExit "NO_SD_CARD_IMAGE" 1 

f_logINFO "Copying ${SDCARD_IMAGE_FILE} over to ${SDCARD_DEVICE} ..."

time dd if="${SDCARD_IMAGE_FILE}" of="${SDCARD_DEVICE}" bs=1M || f_logAndExit "Failed to copy image onto device" 1
