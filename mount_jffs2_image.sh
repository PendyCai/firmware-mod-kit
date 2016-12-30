#!/bin/bash

if [ $# -ne 2 ]; then
  echo Uage : $0  jffs2-image mount-dir
  exit 0
fi

if [ ! -f $1 ]; then
  echo $1 not exist
  exit 0
fi

if [ ! -d $2 ]; then
  echo $2 not a dir
  exit 0
fi

if [ $UID -ne 0 ]; then
  echo "Need sudo $0"
  exit 0
fi



modprobe -v mtd
modprobe -v jffs2
modprobe -v mtdram total_size=1048576 #erase_size=65536
modprobe -v mtdchar
modprobe -v mtdblock

umount $2 2>/dev/null

dd if=$1 of=/dev/mtd0
mount -t jffs2 /dev/mtdblock0 $2
