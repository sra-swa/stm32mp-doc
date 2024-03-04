# STM32MP Development

## Setting up STM32MP Development environment

### Software Setup

#### Development PC prerequisites

A Linux® PC running Ubuntu® 22.04 LTS is recommended. Please follow the below link for more information on the pre-requisites.
(https://wiki.st.com/stm32mpu/wiki/PC_prerequisites)

Setup proxy in case behind a firewall. The following code could be executed on terminal or added to `.bashrc`

```bash
export http_proxy=http://<MyProxyLogin>:<MyProxyPassword>@<MyProxyServerUrl>:<MyProxyPort>
export https_proxy=http://<MyProxyLogin>:<MyProxyPassword>@<MyProxyServerUrl>:<MyProxyPort>
```

In case the password contains special characters it must be HTML encoded first 

```bash
read -sp "Enter Pwd: " MyProxyPassword
echo -n "$MyProxyPassword" | od -A n -t x1 -w128 | head -1 | tr " " "%"
echo
```

The proxy environment setup above may not be available for `sodo` commands, thus create an alias

```bash
alias sudo='sudo http_proxy=$http_proxy'
```

Install the dependencies as follows

```bash
 sudo apt update && sudo apt upgrade
 sudo apt install gawk wget git diffstat unzip texinfo gcc-multilib  chrpath socat cpio python3 python3-pip python3-pexpect 
 sudo apt install libssl-dev libgmp-dev libmpc-dev lz4 zstd
 sudo apt install build-essential libncurses-dev libyaml-dev libssl-dev 
 sudo apt install coreutils bsdmainutils sed curl bc lrzsz libarchive-zip-perl dos2unix texi2html libxml2-utils
```

Set valid `git` configuration

```bash
 git config --global user.name "Your Name"
 git config --global user.email "you@example.com"
```

#### Create bootable MPU SD Card Image

Download [OpenSTLinux starter package](https://www.st.com/en/embedded-software/stm32mp1starter.html) to create a bootable SD card with a base software configuration. Unzip the flash image 

```bash
tar xvf en.flash-stm32mp1-openstlinux-6.1-yocto-mickledore-mp1-v23.06.21.tar.gz
```

Follow the instructions on the STMicroelectronics wiki page [Populate the target and boot the image](https://wiki.st.com/stm32mpu/wiki/Getting_started/STM32MP1_boards/STM32MP157x-DK2/Let%27s_start/Populate_the_target_and_boot_the_image)

> Becuase the STM32CubeProgrammer is available on multiple platforms, you can use the starter package to create a bootable SD card even if you do not have access to a Linux machine, for example, using a Windows machine.

The above instructions talk about flashing the card mounted in the STM32MP board using the STM32CubeProgrammer.
The following method discusses about flashing the SD card directly by inserting it into a card reader/writer using the Linux PC. This faster but more involved (and risky if you don't know what you are doing). Instructions are given below: 

Create a Card Image file

```bash
cd stm32mp1-openstlinux-6.1-yocto-mickledore-mp1-v23.06.21/images/stm32mp1
chmod +x scripts/create_sdcard_from_flashlayout.sh 
scripts/create_sdcard_from_flashlayout.sh <path of flash_layout .tsv file>
# Example scripts/create_sdcard_from_flashlayout.sh flashlayout_st-image-weston/optee/FlashLayout_sdcard_stm32mp157f-dk2-optee.tsv
```

First identify the card device path of the SD card on your computer (**Critical Step**) using `lsblk` command, the card would be something like `/dev/sda`

```bash
# Unmount the partitions of the SD Card
sudo umount <card_device_path>
# Example sudo umount /dev/sdb/*

sudo dd if=<Flash_Image_file> of=<card_device_path> bs=8M conv=fdatasync status=progress
# Example: sudo dd if=FlashLayout_sdcard_stm32mp157f-dk2-optee.raw of=/dev/sdb bs=8M conv=fdatasync status=progress
```

View the console logs over UART (ST-Link) port of the MPU board

```bash
sudo screen /dev/ttyACM0 115200
```


#### Setup Development Environment

Download OpenSTLinux [Developer package](https://www.st.com/en/embedded-software/stm32mp1dev.html), there are 2 components 

- MP1-DEV-SRC: STM32MP1 OpenSTLinux Developer Package Sources
- Yocto_SDKx86: Yocto_SDKx86

Extract both of the packages and install the SDK using the following commands, run the same folder where the packages are downloaded.

```bash

tar xvf en.sources-stm32mp1-openstlinux-6.1-yocto-mickledore-mp1-v23.06.21.tar.gz
tar xvf en.SDK-x86_64-stm32mp1-openstlinux-6.1-yocto-mickledore-mp1-v23.06.21.tar.gz
mkdir -p ~/stmpu/ostl5.0/sdk
mkdir -p ~/stmpu/ostl5.0/src

cp -r stm32mp1-openstlinux-6.1-yocto-mickledore-mp1-v23.06.21/sources/arm-ostl-linux-gnueabi/linux-stm32mp-6.1.28-stm32mp-r1-r0/*  ~/stmpu/ostl5.0/src/

chmod +x stm32mp1-openstlinux-6.1-yocto-mickledore-mp1-v23.06.21/sdk/st-image-weston-openstlinux-weston-stm32mp1-x86_64-toolchain-4.2.1-openstlinux-6.1-yocto-mickledore-mp1-v23.06.21.sh

yes | ./stm32mp1-openstlinux-6.1-yocto-mickledore-mp1-v23.06.21/sdk/st-image-weston-openstlinux-weston-stm32mp1-x86_64-toolchain-4.2.1-openstlinux-6.1-yocto-mickledore-mp1-v23.06.21.sh -d ~/stmpu/ostl5.0/sdk/

chmod +x ~/stmpu/ostl5.0/sdk/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi

rm -r stm32mp1-openstlinux-6.1-yocto-mickledore-mp1-v23.06.21

echo 
echo "Linux sources are installed in ~/stmpu/ostl5.0/src"
echo
echo "SDK is installed in ~/stmpu/ostl5.0/sdk, you can run it using activate it using following command"
echo "source ~/stmpu/ostl5.0/sdk/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi"
echo 
```

#### Compiling the Linux Kernel

The following step would compile the Linux kernel and also create dtbs (device tree blobs) for a board

Navigate to `~/stmpu/ostl5.0/src`
create folder `ptch_<name of the package>` and copy the package specific patches and fragments there
e.g. `ptch_msp1`

Run the following script (*update the package name and board IP address in first 2 line*)
*Update the 3rd and 4th line* if your SDK or Linux sources are installed in some place other than indicated in this guide.

```bash
export PACKAGE_NAME=msp1
export BOARD_IP=192.168.10.127
cd ~/stmpu/ostl5.0/src
source ~/stmpu/ostl5.0/sdk/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi

# Extract Linux sources and rename folder specific to the package name
tar xvf linux-6.1.28.tar.xz
mv linux-6.1.28 linux-6.1.28_${PACKAGE_NAME}
cd linux-6.1.28_${PACKAGE_NAME}

# Apply patches 
for p in `ls -1 ../*.patch`; do patch -p1 < $p;done
for p in `ls -1 ../ptch_${PACKAGE_NAME}/*.patch`; do patch -p1 < $p;done

# Create build folder
echo "" > .scmversion
export OUTPUT_BUILD_DIR=../build_${PACKAGE_NAME}
rm -r ${OUTPUT_BUILD_DIR}
mkdir -p ${OUTPUT_BUILD_DIR}

# Update Kermel Configuration (from default config file and fragment files)
make ARCH=arm O="${OUTPUT_BUILD_DIR}" multi_v7_defconfig fragment*.config -j5
for f in `ls -1 ../fragment*.config`; do scripts/kconfig/merge_config.sh -m -r -O ${OUTPUT_BUILD_DIR} ${OUTPUT_BUILD_DIR}/.config $f; done
for f in `ls -1 ../ptch_${PACKAGE_NAME}/fragment*.config`; do scripts/kconfig/merge_config.sh -m -r -O ${OUTPUT_BUILD_DIR} ${OUTPUT_BUILD_DIR}/.config $f; done
(yes '' || true) | make ARCH=arm oldconfig O="${OUTPUT_BUILD_DIR}"

# Complile Kernel image, DTBS and Modules
# Run commands below this point only if you updated only some source / DTS files
make ARCH=arm uImage vmlinux dtbs LOADADDR=0xC2000040 O="${OUTPUT_BUILD_DIR}" -j6
make ARCH=arm modules O="${OUTPUT_BUILD_DIR}" -j6

# Copy of compiled artifacts to separate folder, remove extra debug information to reduce size 
make ARCH=arm INSTALL_MOD_PATH="${OUTPUT_BUILD_DIR}/install_artifact" modules_install O="${OUTPUT_BUILD_DIR}"
mkdir -p ${OUTPUT_BUILD_DIR}/install_artifact/boot/
cp ${OUTPUT_BUILD_DIR}/arch/arm/boot/uImage ${OUTPUT_BUILD_DIR}/install_artifact/boot/
cp ${OUTPUT_BUILD_DIR}/arch/arm/boot/dts/st*.dtb ${OUTPUT_BUILD_DIR}/install_artifact/boot
cd ${OUTPUT_BUILD_DIR}/install_artifact
rm lib/modules/*/source lib/modules/*/build
find . -name "*.ko" | xargs $STRIP --strip-debug --remove-section=.comment --remove-section=.note --preserve-dates

# Copy compiled files to the board over SCP, board must be connected on the same network
scp -r ./boot/* root@${BOARD_IP}:/boot/
scp -r ./lib/modules/* root@${BOARD_IP}:/lib/modules/
ssh root@${BOARD_IP} "/sbin/depmod -a"
ssh root@${BOARD_IP} "sync"
ssh root@${BOARD_IP} "reboot"
```
