#!/bin/bash
BINDIR=`dirname $0`
. "$BINDIR/common.inc"

DIR="$1"
NEXT_PARAM=""

if [ "$1" == "-h" ]; then
	echo "Usage: $0 [FMK directory] [-nopad | -min]"
	exit 1
fi

if [ "$DIR" == "" ] || [ "$DIR" == "-nopad" ] || [ "$DIR" == "-min" ]; then
	DIR="fmk"
	NEXT_PARAM="$1"
else
	NEXT_PARAM="$2"
fi

# Need to extract file systems as ROOT
if [ "$UID" != "0" ]; then
        SUDO="sudo"
else
        SUDO=""
fi

DIR=$(readlink -f $DIR)

# Make sure we're operating out of the FMK directory
cd $(dirname $(readlink -f $0))

# Order matters here!
eval $(cat shared-ng.inc)
eval $(cat $CONFLOG)
FSOUT="$DIR/new-filesystem.$FS_TYPE"

printf "Firmware Mod Kit (build) ${VERSION}, (c)2011-2013 Craig Heffner, Jeremy Collake\n\n"

if [ ! -d "$DIR" ]; then
	echo -e "Usage: $0 [build directory] [-nopad]\n"
	exit 1
fi

# Always try to rebuild, let make decide if necessary
Build_Tools

echo "Building new $FS_TYPE file system... (this may take several minutes!)"

# Clean up any previously created files
rm -rf "$FWOUT" "$FSOUT"

# Build the appropriate file system
case $FS_TYPE in
	"squashfs")
		# Check for squashfs 4.0 realtek, which requires the -comp option to build lzma images.
		if [ "$FS_COMPRESSION" == "lzma" ]; then
			if [ "$(echo $MKFS | grep 'squashfs-4.0-realtek')" != "" ] || [ "$(echo $MKFS | grep 'squashfs-4.2')" != "" ]; then
				COMP="-comp lzma"
			else
				COMP=""
			fi
		fi

		# Mksquashfs 4.0 tools don't support the -le option; little endian is built by default
		if [ "$(echo $MKFS | grep 'squashfs-4.')" != "" ] && [ "$ENDIANESS" == "-le" ];	then
			ENDIANESS=""
		fi
		
		# Increasing the block size minimizes the resulting image size (larger dictionary). Max block size of 1MB.
		if [ "$NEXT_PARAM" == "-min" ];	then
			echo "Blocksize override (-min). Original used $((FS_BLOCKSIZE/1024))KB blocks. New firmware uses 1MB blocks."
			FS_BLOCKSIZE="$((1024*1024))"
		fi

		# if blocksize var exists, then add '-b' parameter
                if [ "$FS_BLOCKSIZE" != "" ]; then
			BS="-b $FS_BLOCKSIZE"
			HR_BLOCKSIZE="$(($FS_BLOCKSIZE/1024))"
			echo "Squahfs block size is $HR_BLOCKSIZE Kb"
		fi
		$SUDO $MKFS "$ROOTFS" "$FSOUT" $ENDIANESS $BS $COMP -all-root
		;;
	"cramfs")
		$SUDO $MKFS "$ROOTFS" "$FSOUT"
		if [ "$ENDIANESS" == "-be" ]; then
			mv "$FSOUT" "$FSOUT.le"
			./src/cramfsswap/cramfsswap "$FSOUT.le" "$FSOUT"
			rm -f "$FSOUT.le"
		fi
		;;
	*)
		echo "Unsupported file system '$FS_TYPE'!"
		;;
esac

if [ ! -e $FSOUT ]; then
	echo "Failed to create new file system! Quitting..."
	exit 1
fi

echo `pwd`
# Calculate and create any filler bytes required between the end of the file system and the footer / EOF.
CUR_SIZE=$(ls -l $FSOUT | awk '{print $5}')

SZ=`printf %08x $CUR_SIZE`
b0=${SZ:0:2}
b1=${SZ:2:2}
b2=${SZ:4:2}
b3=${SZ:6:2}

F=$FWOUT-noheader.bin
echo $F
printf "\nRemove 360 C301 header : $F \n"
tail -c +65 $HEADER_IMAGE | head -c -16 > $F

echo -n -e "\x$b0\x$b1\x$b2\x$b3\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0" >> $F

$SUDO cat  $FSOUT >> $F

cd $DIR
../bin/seama -i $F -v -m "dev=/dev/mtdblock/1" -m "type=firmware"

printf "\nNew firmware image has been saved to: $F\n"

exit 0



