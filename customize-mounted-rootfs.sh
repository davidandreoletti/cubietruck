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

rsync --ignore-times -rv --chmod=ugo=rwX "${ROOTFS_CUSTOM_DIR}/" "${MNT_ROOTFS_DIR}" 

# Mount sys, proc and dev
for m in `echo 'sys dev proc'`; do sudo mount /$m ./$m -o bind; done

# chroot into your target filesystem
sudo LC_ALL=C chroot . /bin/bash -x <<'EOF'
USER_ADMIN_LOGIN=administrator""
USER_ADMIN_FULLNAME="Administrator"
# Install custom startup scripts
chmod +x /etc/init.d/host/cubian-*
update-rc.d cubian-firstrun defaults
# Get and install some packages
apt-get update
#apt-get -y install openssh-server vim
apt-get -y install locales
dpkg-reconfigure locales
export LANG=en_US.UTF-8
apt-get -y install openssh-server openssh-client vim wireless-tools wpasupplicant hwinfo
apt-get -y install rsync duplicity 
apt-get -y install cpufrequtils
apt-get -y install man
apt-get -y install ntp
apt-get -y install udev
apt-get -y install tree 
# Set timezone
mv -v etc/localtime etc/localtime.bkp
#ln -s /usr/share/zoneinfo/Asia/Taipei /etc/localtime 
ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
# Add user
useradd -s "/bin/bash" -U -m --comment "${USER_ADMIN_FULLNAME}" --expiredate "" --inactive "-1" "${USER_ADMIN_LOGIN}"
echo "${USER_ADMIN_LOGIN}:admin"|chpasswd 
adduser "${USER_ADMIN_LOGIN}" adm
adduser "${USER_ADMIN_LOGIN}" dialout 
adduser "${USER_ADMIN_LOGIN}" cdrom
adduser "${USER_ADMIN_LOGIN}" audio
adduser "${USER_ADMIN_LOGIN}" dip
adduser "${USER_ADMIN_LOGIN}" video
adduser "${USER_ADMIN_LOGIN}" plugdev
adduser "${USER_ADMIN_LOGIN}" admin
EOF

# Quit chroot
for m in `echo 'sys dev proc'`; do sudo umount ./$m; done
mv etc/resolv.conf.saved etc/resolv.conf

cd -




