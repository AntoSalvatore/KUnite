#!/bin/sh
for x in $*
do
sed -e "s/#e95420/#E75727/g" $x > temp$x
mv temp$x $x
done
