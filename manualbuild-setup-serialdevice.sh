SERIAL_DEVICE=${SERIAL_DEVICE:-"/dev/ttyUSB0"} # Assuming Prolific PL2303 like chip

echo "Set write permission (temporary)"
sudo chmod 666 ${SERIAL_DEVICE}
ls -l ${SERIAL_DEVICE}
