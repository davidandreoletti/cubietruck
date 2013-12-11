#!/bin/bash
. lib.sh

SDCARD_DEVICE=${SDCARD_DEVICE:-"UNKNOWN"}
SDCARD_IMAGE_FILE=${SDCARD_IMAGE_FILE:-"sdcard.img"}

test -d "${SDCARD_DEVICE}" || logAndExit "NO_SD_CARD_DEVICE" 1
test -e "${SDCARD_IMAGE_FILE}" || logAndExit "NO_SD_CARD_IMAGE" 1 

logINFO "Copying ${SDCARD_IMAGE_FILE} over to ${SDCARD_DEVICE} ..."

time dd if="${SDCARD_IMAGE_FILE}" of="${SDCARD_DEVICE}" bs=1M || logAndExit "Failed to copy image onto device" 1
