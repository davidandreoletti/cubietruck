#!/bin/bash
set -x
SCRIPT_DIR=${SCRIPT_DIR:-`pwd`}
. ${SCRIPT_DIR}/lib.sh

MNT_ROOTFS_DIR=${1:-"/mnt"}
ROOTFS_CUSTOM_DIR=${2:-"${SCRIPT_DIR}/custom/rootfs"}

test -d "${MNT_ROOTFS_DIR}" || f_logAndExit "NO_MOUNTED_ROOTFS_DIR" 1
test -d "${ROOTFS_CUSTOM_DIR}" || f_logAndExit "NO_ROOTFS_CUSTOM_DIR" 1

f_logINFO "Customizing rootfs ..."

cd "${MNT_ROOTFS_DIR}"

cp /usr/bin/qemu-arm-static usr/bin/

# Setup network settings properly 
mv etc/resolv.conf etc/resolv.conf.saved
cp /etc/resolv.conf etc/resolv.conf

# Mount sys, proc and dev
for m in `echo 'sys dev proc'`; do sudo mount /$m ./$m -o bind; done

# chroot into your target filesystem
sudo LC_ALL=C chroot . /bin/bash -x <<'EOF'
# Get and install some packages
apt-get update
#apt-get -y install openssh-server vim
apt-get -y install openssh-server openssh-client vim wireless-tools wpasupplicant hwinfo
apt-get -y install rsync duplicity 
apt-get -y install cpufrequtils
apt-get -y install man
apt-get -y install ntp
# Set timezone
mv -v etc/localtime etc/localtime.bkp
#ln -s /usr/share/zoneinfo/Asia/Taipei /etc/localtime 
ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
# Add user
useradd -s "/bin/bash" -U -m --comment "administrator" --expiredate "" --inactive "-1" myadmin
echo "myadmin:admin"|chpasswd 
adduser myadmin adm
adduser myadmin dialout 
adduser myadmin cdrom
adduser myadmin audio
adduser myadmin dip
adduser myadmin video
adduser myadmin plugdev
adduser myadmin admin
EOF

# Quit chroot
for m in `echo 'sys dev proc'`; do sudo umount ./$m; done
mv etc/resolv.conf.saved etc/resolv.conf

cd -

rsync --ignore-times -rv --chmod=ugo=rwX "${ROOTFS_CUSTOM_DIR}/" "${MNT_ROOTFS_DIR}" 


