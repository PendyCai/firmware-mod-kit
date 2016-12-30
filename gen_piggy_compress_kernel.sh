#!/bin/bash


IN=$1
OUT=$2

#echo $IN

if [ ! -f "$IN" ]; then
  echo Usage : $0 in_file out_file
  echo 
  exit 1
fi

if [ "_$OUT" = "_" ]; then

  OUT=$IN.bin

fi

head -c 16 $IN | grep "piggy" >/dev/null  && echo "It seems already contains piggy header. end.." && exit 0

head -c 10 $IN                                > $OUT
sed -i 's/\x1f\x8b\x08\x00/\x1f\x8b\x08\x08/g'  $OUT
sed -i 's/\x02\x03/\x02\x03piggy\x00/g'         $OUT
tail -c +11 $IN                              >> $OUT

echo end...

