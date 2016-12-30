#!/bin/bash

f=$1
if [ -z $f ]; then
  echo Usage: $0  image
  exit 0
fi
if [ ! -f $f  ]; then
   echo $f no exist....
   exit 0
fi

./bin/seama -i $f -v -m "dev=/dev/mtdblock/1" -m "type=firmware"


