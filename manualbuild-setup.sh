# Manual setup based on http://linux-sunxi.org/Manual_build_howto

echo Getting handy tools
sudo apt-get install unp bc kpartx

echo Getting build essentials
sudo apt-get install build-essential git  libncurses5-dev

echo Getting cross toolchain
sudo apt-get install gcc-arm-linux-gnueabi

echo Getting non cross compiler related tools for building sunxi kernel
sudo apt-get install debootstrap u-boot-tools 

echo Get bootloader for sunxi kernel
echo Doc: https://github.com/linux-sunxi/u-boot-sunxi/blob/sunxi/README

git clone https://github.com/linux-sunxi/u-boot-sunxi.git 

echo Get Allwinner hacking tools
git clone git://github.com/linux-sunxi/sunxi-tools.git

echo Get Sunxi boards sys_config
git clone git://github.com/linux-sunxi/sunxi-boards.git

echo Get Linux sunxi kernel
git clone https://github.com/linux-sunxi/linux-sunxi.git

echo Get rootfs
wget http://snapshots.linaro.org/ubuntu/images/nano/latest/linaro-raring-nano-20131203-571.tar.gz
