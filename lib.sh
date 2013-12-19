#
# Library
#

set -x

function f_logAndExit() {
	echo $1;
	exit $2;
}

function f_logINFO() {
	echo "----------------------------------------"
	echo "-- $1"
	echo "----------------------------------------"
}

function f_mountImageAsLoopbackDevice() {
	local d=$(losetup -fv $1 | grep "Loop device is" | cut -d' ' -f4)
	echo "$d"
}

function f_umountLoopbackDevice() {
	sleep 5
	losetup -d $1
}

# arg1: size in bytes
# arg2: heads
# arg3: sectors
# arg4: bytes per sector
function f_computeDeviceGeometryCylinders() {
	echo "$1 / $2 / $3 / $4" | bc
}

function f_mountPartitionsAsLoopbackDevices() {
	local mapping=`sudo kpartx -av "$1"`
	ls -al /dev/mapper/
	local mappedCard=`echo "$mapping" | grep "add map" | head -n 1 | cut -d' ' -f3` 
	local cardp="/dev/mapper/${mappedCard:0:5}p"
	export cardboot=${cardp}1
	export cardroot=${cardp}2
	sleep 5
}

function f_umountPartitionsAsLoopbackDevices() {
	sleep 5
	sudo kpartx -d "$1" 
}

