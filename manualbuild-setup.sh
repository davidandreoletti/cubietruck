#!/bin/bash
. lib.sh

logINFO "Getting handy tools"
sudo apt-get install unp bc kpartx cu

logINFO "Getting build essentials"
sudo apt-get install build-essential git libncurses5-dev

logINFO "Getting cross toolchain"
sudo apt-get install gcc-arm-linux-gnueabi

logINFO "Getting non cross compiler related tools for building sunxi kernel"
sudo apt-get install debootstrap u-boot-tools 

logINFO "Get bootloader for sunxi kernel"
git clone https://github.com/linux-sunxi/u-boot-sunxi.git 

logINFO "Get Allwinner hacking tools"
git clone git://github.com/linux-sunxi/sunxi-tools.git

logINFO "Get Sunxi boards sys_config"
git clone git://github.com/linux-sunxi/sunxi-boards.git

logINFO "Get Linux sunxi kernel"
git clone https://github.com/linux-sunxi/linux-sunxi.git

logINFO "Get Linux sunxi kernel"
git clone https://github.com/linux-sunxi/linux-sunxi.git

logINFO "Get Sunxi BSP"
git clone https://github.com/linux-sunxi/sunxi-bsp 

logINFO "Get rootfs"
wget "http://snapshots.linaro.org/ubuntu/images/nano/579/linaro-saucy-nano-20131210-579.tar.gz" 
