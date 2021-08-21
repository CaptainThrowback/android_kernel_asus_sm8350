#!/bin/bash

Defconfig_Folder=arch/arm64/configs
Kernel_Root=~/android/build/kernel/asus/ZS590KS
Android_Build=~/android/build/AOSP/android-11
Clang_Google=prebuilts/clang/host
Prebuilt_Clang=clang-r383902
GCC_Google_Arm64=prebuilts/gcc/linux-x86/aarch64
GCC_Google_Arm32=prebuilts/gcc/linux-x86/arm
Kernel_Output_Path=out/arch/arm64/boot

echo
echo "Clean Build Directory?"
echo 
PS3='Selection: '
select yn in "Yes" "No"; do
	case $yn in
		Yes)
			echo 
			make clean && make mrproper
			break
			;;
		No)
			break
			;;
	esac
done

echo
echo "Issue Build Commands"
echo

mkdir -p out
export ARCH=arm64
export SUBARCH=arm64
export CLANG_PREBUILT_BIN=$Android_Build/$Clang_Google/linux-x86/$Prebuilt_Clang/bin
export PATH=${CLANG_PREBUILT_BIN}:${PATH}
export DTC_EXT=$Kernel_Root/dtc-aosp
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=$Android_Build/$GCC_Google_Arm64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-
export CROSS_COMPILE_COMPAT=$Android_Build/$GCC_Google_Arm32/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export LINUX_GCC_CROSS_COMPILE_PREBUILTS_BIN=$Android_Build/$GCC_Google_Arm64/aarch64-linux-android-4.9/bin
export LINUX_GCC_CROSS_COMPILE_ARM32_PREBUILTS_BIN=$Android_Build/$GCC_Google_Arm32/arm-linux-androideabi-4.9/bin/

export FILES="
arch/arm64/boot/Image.gz
arch/arm64/boot/Image
vmlinux
System.map
"

export CLANG_AR=$CLANG_PREBUILT_BIN/llvm-ar
export CLANG_CC=$CLANG_PREBUILT_BIN/clang
export CLANG_CCXX=$CLANG_PREBUILT_BIN/clang++
export CLANG_LD=$CLANG_PREBUILT_BIN/ld.lld
export CLANG_LDLTO=$CLANG_PREBUILT_BIN/ld.lld
export CLANG_NM=$CLANG_PREBUILT_BIN/llvm-nm
export CLANG_STRIP=$CLANG_PREBUILT_BIN/llvm-strip
export CLANG_OC=$CLANG_PREBUILT_BIN/llvm-objcopy
export CLANG_OD=$CLANG_PREBUILT_BIN/llvm-objdump
export CLANG_OS=$CLANG_PREBUILT_BIN/llvm-size
export CLANG_RE=$CLANG_PREBUILT_BIN/llvm-readelf

export CC=$CLANG_CC
export HOST_CC=$CLANG_CC
export LD=$CLANG_LD

export ASUS_BUILD_PROJECT=SAKE

echo
echo "Choose DEFCONFIG"
echo 

DEFCONFIG=($(find $Defconfig_Folder -iname '*config*' -type f -exec echo '{}' \; | awk -F'configs/' '{print $NF}'))
select choice in "${DEFCONFIG[@]}"; do
    make LLVM=1 CC=$CLANG_CC LD=$CLANG_LD AR=$CLANG_AR STRIP=$CLANG_STRIP OBJCOPY=$CLANG_OC NM=$CLANG_NM OBJDUMP=$CLANG_OD OBJSIZE=$CLANG_OS READELF=$CLANG_RE HOSTCC=$CLANG_CC HOSTCXX=$CLANG_CCXX HOSTAR=$CLANG_AR HOSTLD=$CLANG_LD O=out "$choice"
	break
done

echo
echo "Build The Good Stuff"
echo 

time make LLVM=1 CC=$CLANG_CC LD=$CLANG_LD AR=$CLANG_AR STRIP=$CLANG_STRIP OBJCOPY=$CLANG_OC NM=$CLANG_NM OBJDUMP=$CLANG_OD OBJSIZE=$CLANG_OS READELF=$CLANG_RE HOSTCC=$CLANG_CC HOSTCXX=$CLANG_CCXX HOSTAR=$CLANG_AR HOSTLD=$CLANG_LD O=out -j$(($(nproc) * 2))

if [ -e $Kernel_Output_Path/Image ]; then
	echo
	echo "Compress Kernel Image"
	echo 
	gzip -9 -k -f $Kernel_Output_Path/Image
	echo
	echo "Compile DTBs"
	echo
	find $Kernel_Output_Path/dts -name '*.dtb' -exec cat {} + > $Kernel_Output_Path/dtb.img
	echo
	echo "Build Complete!"
	echo
else
	echo
	echo "Build Failed. See above error(s) for details."
	echo
fi
