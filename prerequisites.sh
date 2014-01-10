#!/bin/bash
SCRIPT_DIR=${SCRIPT_DIR:-`pwd`}
. ${SCRIPT_DIR}/lib.sh

ROOTFS_FILE_COMPRESSED_URL="http://snapshots.linaro.org/ubuntu/images/nano/573/linaro-raring-nano-20131205-573.tar.gz"
ROOTFS_FILE_COMPRESSED=${ROOTFS_FILE_COMPRESSED:-"rootfs.tar.gz"}
#LINUX_SUNXI_GIT_URL=${LINUX_SUNXI_GIT_URL:-"https://github.com/linux-sunxi/linux-sunxi.git"}
#LINUX_SUNXI_GIT_URL=${LINUX_SUNXI_GIT_URL:-"https://github.com/cubieboard2/linux-sunxi.git"}
LINUX_SUNXI_GIT_URL=${LINUX_SUNXI_GIT_URL:-"https://github.com/patrickhwood/linux-sunxi.git"}



f_logINFO "Getting some handy tools"
sudo apt-get install unp bc kpartx cu rsync wget git

f_logINFO "Getting some handy tools for rootfs customization"
sudo apt-get install qemu-user-static

f_logINFO "Getting build essentials"
sudo apt-get install build-essential libncurses5-dev

f_logINFO "Getting cross toolchain for ARMv6 (armel) and ARMv7 (armhf) architectures"
sudo apt-get install gcc-arm-linux-gnueabi gcc-arm-linux-gnueabihf

f_logINFO "Getting non cross compiler related tools for building sunxi kernel"
sudo apt-get install debootstrap u-boot-tools 

f_logINFO "Get bootloader for sunxi kernel"
git clone https://github.com/linux-sunxi/u-boot-sunxi.git 

f_logINFO "Get Allwinner hacking tools"
git clone git://github.com/linux-sunxi/sunxi-tools.git

f_logINFO "Get Sunxi boards sys_config"
git clone git://github.com/cubieboard/cubie_configs.git

f_logINFO "Get Linux sunxi kernel"
git clone "${LINUX_SUNXI_GIT_URL}" linux-sunxi

f_logINFO "Get Linux sunxi kernel"
git clone https://github.com/linux-sunxi/linux-sunxi.git

f_logINFO "Get Sunxi BSP"
git clone https://github.com/linux-sunxi/sunxi-bsp 

f_logINFO "Downloading ${ROOTFS_FILE_COMPRESSED_URL} as rootfs"
wget -o "${ROOTFS_FILE_COMPRESSED}" "${ROOTFS_FILE_COMPRESSED_URL}" 
