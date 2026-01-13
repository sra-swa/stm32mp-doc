# STM32MP1 Development

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
 sudo apt install build-essential libncurses-dev libyaml-dev libssl-dev 
sudo apt-get install libncurses5-dev libncursesw5-dev libyaml-dev
sudo apt-get install u-boot-tools
sudo apt-get install libyaml-dev
```

Set valid `git` configuration

```bash
 git config --global user.name "Your Name"
 git config --global user.email "you@example.com"
 git config --global alias.lo "log --oneline --graph --decorate"
```

#### Create bootable MPU SD Card Image

Download [OpenSTLinux starter package](https://www.st.com/en/embedded-software/stm32mp1starter.html) to create a bootable SD card with a base software configuration. Unzip the flash image 

```bash
tar xvf FLASH-stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11.tar.gz
```

Follow the instructions on the STMicroelectronics wiki page [Populate the target and boot the image](https://wiki.st.com/stm32mpu/wiki/Getting_started/STM32MP1_boards/STM32MP157x-DK2/Let%27s_start/Populate_the_target_and_boot_the_image)

> Becuase the STM32CubeProgrammer is available on multiple platforms, you can use the starter package to create a bootable SD card even if you do not have access to a Linux machine, for example, using a Windows machine.

The above instructions talk about flashing the card mounted in the STM32MP board using the STM32CubeProgrammer.
The following method discusses about flashing the SD card directly by inserting it into a card reader/writer using the Linux PC. This faster but more involved (and risky if you don't know what you are doing). Instructions are given below: 

Create a Card Image file

```bash
cd stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11/images/stm32mp1
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
# Example: sudo dd if=FlashLayout_sdcard_stm32mp157f-dk-optee.raw of=/dev/sdb bs=8M conv=fdatasync status=progress
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

tar xvf SOURCES-stm32mp-openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11.tar.gz
tar xvf SDK-x86_64-stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11.tar.gz
mkdir -p ~/stmpu/ostl6.1/sdk-mp1
mkdir -p ~/stmpu/ostl6.1/src-mp1

cp -r cp -r stm32mp-openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11/sources/ostl-linux/linux-stm32mp-6.6.78-stm32mp-r2-r0/*  ~/stmpu/ostl6.1/src-mp1/

chmod +x stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11/sdk/st-image-weston-openstlinux-weston-stm32mp1.rootfs-x86_64-toolchain-5.0.8-openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11.sh

yes | stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11/sdk/st-image-weston-openstlinux-weston-stm32mp1.rootfs-x86_64-toolchain-5.0.8-openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11.sh -d ~/stmpu/ostl6.1/sdk-mp1/

rm -r stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11

echo 
echo "Linux sources are installed in ~/stmpu/ostl6.1/src-mp1"
echo
echo "SDK is installed in ~/stmpu/ostl6.1/sdk-mp1, you can run it using activate it using following command"
echo "source ~/stmpu/ostl6.1/sdk-mp1/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi"
echo 
```

#### Compiling the Linux Kernel

The following step would compile the Linux kernel and also create dtbs (device tree blobs) for a board

Navigate to `~/stmpu/ostl6.1/src-mp1`
create folder `ptch_<name of the package>` and copy the package specific patches and fragments there
e.g. `ptch_msp1`

Run the following script (*update the package name and board IP address in first 2 line*)
*Update the 3rd and 4th line* if your SDK or Linux sources are installed in some place other than indicated in this guide.

```bash
source /stmpu/ostl6.1/sdk-mp1/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi

export PARALLEL_JOBS=32
export PACKAGE_NAME="evg1"
export LINUX_VER="6.6.78"
export BOARD_IP="evg11.local"
export OUTPUT_BUILD_DIR=$PWD/../build_${PACKAGE_NAME}
[ "${ARCH}" = "arm" ] && imgtarget="uImage" || imgtarget="Image.gz"
export IMAGE_KERNEL=${imgtarget}
export LOAD_ADDRESS="0xC2000040"


# Extract Linux sources and rename folder specific to the package name
tar xf linux-${LINUX_VER}.tar.xz
mv linux-${LINUX_VER} linux-${LINUX_VER}_${PACKAGE_NAME}
cd linux-${LINUX_VER}_${PACKAGE_NAME}

# Init git, helps to track the changes in sources
test -d .git || git init . && git add . && git commit -m "linux-${LINUX_VER}" && git gc
git checkout -b WORKING


# Apply patches 
## using Git
# for p in `ls -1 ../*.patch`; do git am $p; done

## without using Git
for p in `ls -1 ../*.patch`; do patch -p1 < $p;done
for p in `ls -1 ../ptch_${PACKAGE_NAME}/*.patch`; do patch -p1 < $p;done

# Create build folder
echo "" > .scmversion
mkdir -p ${OUTPUT_BUILD_DIR}
echo "" > $OUTPUT_BUILD_DIR/.scmversion

# Update Kermel Configuration (from default config file and fragment files)
make O="${OUTPUT_BUILD_DIR}" defconfig fragment*.config

for f in `ls -1 ../fragment*.config`; do scripts/kconfig/merge_config.sh -m -r -O ${OUTPUT_BUILD_DIR} ${OUTPUT_BUILD_DIR}/.config $f; done
#for f in `ls -1 ../ptch_${PACKAGE_NAME}/fragment*.config`; do scripts/kconfig/merge_config.sh -m -r -O ${OUTPUT_BUILD_DIR} ${OUTPUT_BUILD_DIR}/.config $f; done

(yes '' || true) | make oldconfig O="${OUTPUT_BUILD_DIR}"

# Complile Kernel image, DTBS and Modules
# Run commands below this point only if you run for the first time, or updated some source / DTS files
make ${IMAGE_KERNEL} vmlinux dtbs LOADADDR=${LOAD_ADDRESS} O="${OUTPUT_BUILD_DIR}" -j$PARALLEL_JOBS

make modules O="${OUTPUT_BUILD_DIR}" -j$PARALLEL_JOBS
make INSTALL_MOD_PATH="${OUTPUT_BUILD_DIR}/install_artifact" modules_install O="${OUTPUT_BUILD_DIR}"

# Copy of compiled artifacts to separate folder, remove extra debug information to reduce size 
cp ${OUTPUT_BUILD_DIR}/arch/${ARCH}/boot/${IMAGE_KERNEL} ${OUTPUT_BUILD_DIR}/install_artifact/boot/
find ${OUTPUT_BUILD_DIR}/arch/${ARCH}/boot/dts/ -name 'st*.dtb' -exec cp '{}' ${OUTPUT_BUILD_DIR}/install_artifact/boot/ \;

mkdir -p ${OUTPUT_BUILD_DIR}/install_artifact/boot/
cd ${OUTPUT_BUILD_DIR}/install_artifact/
rm lib/modules/${LINUX_VER}/source lib/modules/${LINUX_VER}/build
find . -name "*.ko" | xargs $STRIP --strip-debug --remove-section=.comment --remove-section=.note --preserve-dates

# Generated files are :
# - $PWD/install_artifact/boot/[uImage|Image.gz]
# - $PWD/install_artifact/boot/<stm32-boards>.dtb

# Copy compiled files to the board over SCP, board must be connected on the same network
scp -r ./boot/* root@${BOARD_IP}:/boot/
scp -r ./lib/modules/* root@${BOARD_IP}:/lib/modules/
ssh root@${BOARD_IP} "/sbin/depmod -a"
ssh root@${BOARD_IP} "sync"
ssh root@${BOARD_IP} "reboot"
```
