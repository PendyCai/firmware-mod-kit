#!/bin/bash
BINDIR=`dirname $0`
. "$BINDIR/common.inc"

IMG="${1}"
DIR="${2}"

if [ "${DIR}" = "" ]; then
	DIR="fmk"
fi

# Need to extract file systems as ROOT
if [ "$(id -ru)" != "0" ]; then
	SUDO="sudo"
else
	SUDO=""
fi

IMG=$(readlink -f $IMG)
DIR=$(readlink -f $DIR)

# Make sure we're operating out of the FMK directory
cd $(dirname $(readlink -f $0))

# Source in/Import shared settings. ${DIR} MUST be defined prior to this!
. ./shared-ng.inc

printf "Firmware Mod Kit (extract) ${VERSION}, (c)2011-2013 Craig Heffner, Jeremy Collake\n\n"

# Check usage
#if [ "${IMG}" = "" ] || [ "${IMG}" = "-h" ]; then
#	printf "Usage: ${0} <firmware image>\n\n"
#	exit 1
#fi

#if [ ! -f "${IMG}" ]; then
#	echo "File does not exist!"
#	exit 1
#fi

#if [ -e "${DIR}" ]; then
#	echo "Directory ${DIR} already exists! Quitting..."
#	exit 1
#fi

Build_Tools

# Get the size, in bytes, of the target firmware image
FW_SIZE=$(ls -l "${IMG}" | cut -d' ' -f5)

# Create output directories
#mkdir -p "${DIR}/logs"
#mkdir -p "${DIR}/image_parts"

echo "Scanning firmware..."

# Log binwalk results to the ${BINLOG} file, disable default filters, exclude invalid results,
# and search only for trx, uimage, dlob, squashfs, and cramfs results.
#${BINWALK} -f "${BINLOG}" -d -x invalid -y trx -y uimage -y dlob -y squashfs -y cramfs "${IMG}"
${BINWALK}  "${IMG}"

exit 0
