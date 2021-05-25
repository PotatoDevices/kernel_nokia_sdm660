#!/bin/bash
BUILD_START=$(date +"%s")

# Colours
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Kernel details
KERNEL_NAME="Quindecim"
DATE=$(date +"%d-%m-%Y-%I-%M")
DEVICE="DRG"
FINAL_ZIP=$KERNEL_NAME-$DATE-$DEVICE.zip
defconfig=nokia_defconfig

# Dirs
BASE_DIR=`pwd`/../
KERNEL_DIR=$BASE_DIR/sdm660
ANYKERNEL_DIR=$KERNEL_DIR/AnyKernel3
KERNEL_IMG=$KERNEL_DIR/outdir/arch/arm64/boot/Image.gz-dtb
UPLOAD_DIR=$BASE_DIR/$DEVICE

# Export
export PATH="$BASE_DIR/clang/bin:$BASE_DIR/arm64-gcc/bin:$BASE_DIR/arm-gcc/bin:${PATH}"
export ARCH=arm64

## Funtions
# Clean Compile
function clean_compile() {
echo "---------------------------------------"
make O=outdir clean
echo "---------------------------------------"
make O=outdir mrproper
echo "---------------------------------------"
make O=outdir ARCH=arm64 $defconfig

make -j$(nproc --all) O=outdir \
                      ARCH=arm64 \
                      CC=clang \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE=aarch64-linux-android- \
                      CROSS_COMPILE_ARM32=arm-linux-androideabi-
  if ! [ -a $KERNEL_IMG ];
  then
    echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
    exit 1
  fi
echo "---------------------------------------"
}

# Dity Compile
function dirty_compile() {
echo "---------------------------------------"
make O=outdir ARCH=arm64 $defconfig

make -j$(nproc --all) O=outdir \
                      ARCH=arm64 \
                      CC=clang \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE=aarch64-linux-android- \
                      CROSS_COMPILE_ARM32=arm-linux-androideabi-
  if ! [ -a $KERNEL_IMG ];
  then
    echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
    exit 1
  fi
echo "---------------------------------------"
}

# Regenerate defconfig
function regen() {
echo "---------------------------------------"
make O=outdir clean
echo "---------------------------------------"
make O=outdir mrproper
export ARCH=arm64
echo "---------------------------------------"
make $defconfig
echo "Done!"
echo "---------------------------------------"
}

# Zip Kernel
function make_zip() {
cp $KERNEL_IMG $ANYKERNEL_DIR
mkdir -p $UPLOAD_DIR
cd $ANYKERNEL_DIR
zip -r9 UPDATE-AnyKernel2.zip * -x README UPDATE-AnyKernel2.zip
mv $ANYKERNEL_DIR/UPDATE-AnyKernel2.zip $UPLOAD_DIR/$FINAL_ZIP
echo "---------------------------------------"
}

# Clean Up
function cleanup(){
rm -rf $ANYKERNEL_DIR/Image.gz-dtb
}

# Menu
function menu() {
echo "---------------------------------------"
echo -e "1. Dirty"
echo -e "2. Clean"
echo -e "3. Regenerate Defconfig"
echo -n "Choose :"
read choose

case $choose in
 1) dirty_compile
    make_zip ;;
 2) clean_compile
    make_zip ;;
 3) regen ;;
esac
}


menu
cleanup
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
