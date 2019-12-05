#!/bin/bash

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"

# Paths1
HOME=/home/danny/eas
KERNEL_DIR="$HOME/kernel"
KERNEL_OUTPUT="$KERNEL_DIR/out"
KERNEL_FILE="Image.gz-dtb"
TOOLCHAIN_DIR="$HOME/Toolchains"
AK3_DIR="$HOME/AnyKernel3"
ZIP_MOVE="$HOME"

# OP6 [OOS]
###########
VER="r5"
DEFCONFIG="mcd_defconfig"

# Set Toolchain
export CROSS_COMPILE=$TOOLCHAIN_DIR/arm64-gcc-9.2.1/bin/aarch64-linux-gnu-
# vDSO Toolchain (32-Bit)
export CROSS_COMPILE_ARM32=$TOOLCHAIN_DIR/arm32-gcc-9.2.1/bin/arm-linux-gnueabi-

# Vars
export ARCH=arm64
export SUBARCH=arm64
export LOCALVERSION=~mcd-`echo "$VER"`
export KBUILD_BUILD_USER=mcdachpappe
export KBUILD_BUILD_HOST=vmbox
export KBUILD_BUILD_VERSION=1

# Use CCACHE
CCACHE=ccache
export USE_CCACHE=1
export CCACHE_DIR=/mnt/hgfs/Android/.ccache
export CCACHE_MAX_SIZE=10G
ccache -M $CCACHE_MAX_SIZE

# Paths2
KERNEL_FILE_DIR="$KERNEL_OUTPUT/arch/$ARCH/boot"
CHANGELOG_FILE=$HOME/changelog-$VER.txt

# Kernel zip name
VARIANT="mcd-kernel"
KERNEL_ZIP_NAME="$VARIANT-$VER"

# Functions
function clean_all {
	rm -rf $AK3_DIR/$KERNEL_FILE
	cd $KERNEL_DIR
	make O=$KERNEL_OUTPUT clean && make O=$KERNEL_OUTPUT mrproper
	cd $HOME
}

function make_kernel {
	cd $KERNEL_DIR
	mkdir -p ${KERNEL_OUTPUT}
        make O=${KERNEL_OUTPUT} $DEFCONFIG
	#make O=${KERNEL_OUTPUT} menuconfig
        make O=${KERNEL_OUTPUT} $THREAD # &> build.log
	cd $HOME
}

function make_zip {
	cp $KERNEL_FILE_DIR/$KERNEL_FILE $AK3_DIR/$KERNEL_FILE
	cd $AK3_DIR
	zip -r9 $KERNEL_ZIP_NAME.zip * -x .git README.md LICENSE *placeholder
	mv *.zip $ZIP_MOVE
	cd $HOME
}

function changelog {
	if [ -f $CHANGELOG_FILE ]; then
		rm -f $CHANGELOG_FILE
	fi

	touch $CHANGELOG_FILE

	for i in $(seq 14);
	do
		export After_Date=`date --date="$i days ago" +%F`
		k=$(expr $i - 1)
		export Until_Date=`date --date="$k days ago" +%F`
		echo "====================" >> $CHANGELOG_FILE;
		echo "     $Until_Date    " >> $CHANGELOG_FILE;
		echo "====================" >> $CHANGELOG_FILE;
		cd $KERNEL_DIR
		git log --after=$After_Date --until=$Until_Date --pretty=tformat:"%h  %s  [%an]" --abbrev-commit --abbrev=7 >> $CHANGELOG_FILE
		echo "" >> $CHANGELOG_FILE;
	done

	sed -i 's/project/ */g' $CHANGELOG_FILE
	sed -i 's/[/]$//' $CHANGELOG_FILE
}

echo
echo -e "${green}"
echo "  ########################"
echo
echo "   Kernel creation script"
echo
echo "  ########################"
echo -e "${restore}"

DATE_START=$(date +"%s")

echo

while read -p "  1. Clean up working dir's? [y/n] : " achoice
do
case "$achoice" in
    y|Y )
	echo -e "${green}"
	echo "     ------------------"
	echo
	echo "     Start cleaning..."
	echo
	echo "     ------------------"
	echo -e "${restore}"

        clean_all

	echo
        echo -e "${green}"
	echo "     All cleaned up."
	echo "     ---------------"
	echo -e "${restore}"
        break
        ;;
    n|N )
        break
        ;;
    * )
	echo
	echo -e "${red}"
        echo "     Invalid input, try again!"
        echo -e "${restore}"
        ;;
    esac
done

echo

while read -p "  2. Build kernel? [y/n] : " bchoice
do
case "$bchoice" in
    y|Y )
	echo -e "${green}"
	echo "     ------------------"
	echo
	echo "     Start compiling..."
	echo
	echo "     ------------------"
	echo -e "${restore}"

	# delete previous kernel image - if present
	if [ -e $KERNEL_FILE_DIR/$KERNEL_FILE ]; then
		rm $KERNEL_FILE_DIR/$KERNEL_FILE
	fi

	DATE_START=$(date +"%s")

	make_kernel

	DATE_END=$(date +"%s")

	# if kernel image does not exist, exit processing
	if [ ! -e $KERNEL_FILE_DIR/$KERNEL_FILE ]; then		
		echo
		echo -e ${red}
		echo "     #########################################"
		echo -e ${blink_red}
		echo "     Compiling was NOT successful !! Aborting."
		echo -e ${red}
		echo "     #########################################"
		echo -e ${restore}
		exit
	fi

	DIFF=$(($DATE_END - $DATE_START))
	echo
        echo -e "${green}"
	echo "     ---------------------------"
	echo
	echo "     Compiling completed in:"
	echo -e "${restore}"
	echo "     $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
	echo -e "${green}"
	echo "     ---------------------------"
	echo -e "${restore}"
	
	
	break
	;;
    n|N )
	break
	;;
    * )
	echo
	echo -e "${red}"
	echo "     Invalid input, try again!"
	echo -e "${restore}"
	;;
    esac
done

echo

while read -p "  3. ZIP kernel? [y/n] : " cchoice
do
case "$cchoice" in
    y|Y )
	echo -e "${green}"
	echo "     -----------------"
	echo
	echo "     Zipping kernel..."
	echo
	echo "     -----------------"
	echo -e "${restore}"

	make_zip

	echo
        echo -e "${green}"
	echo "     All zipped."
	echo "     -----------"
	echo -e "${restore}"
	break
	;;
    n|N )
	break
	;;
    * )
	echo
	echo -e "${red}"
	echo "     Invalid input, try again!"
	echo -e "${restore}"
	;;
    esac
done

echo

while read -p "  4. Generate a changelog? [y/n] : " dchoice
do
case "$dchoice" in
    y|Y )
	changelog

	echo
        echo -e "${green}"
	echo "     Changelog generated."
	echo "     --------------------"
	echo -e "${restore}"
	break
	;;
    n|N )
	break
	;;
    * )
	echo
	echo -e "${red}"
	echo "     Invalid input, try again!"
	echo -e "${restore}"
	;;
    esac
done

echo
