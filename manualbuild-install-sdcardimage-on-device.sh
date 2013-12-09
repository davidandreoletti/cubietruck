SDCARD_DEVICE=${SDCARD_DEVICE:-"UNKNOWN"}
SDCARD_IMAGE_FILE=${SDCARD_IMAGE_FILE:-"sdcard.img"}

test -d "${SDCARD_DEVICE}" || exit 1
test -e "${SDCARD_IMAGE_FILE}" || exit 1

echo "Copying ${SDCARD_IMAGE_FILE} over to ${SDCARD_DEVICE} ..."
time dd if="${SDCARD_IMAGE_FILE}" of="${SDCARD_DEVICE}"  bs=1M || echo "Failed.
