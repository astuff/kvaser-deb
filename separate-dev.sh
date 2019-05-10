#!/bin/bash

cp -r linuxcan/ linuxcan-dev/
cd linuxcan-dev

# Strip down to only canlib and linlib
rm 10-kvaser.rules
rm -r leaf/ mhydra/ pcican/ pcican2/ pciefd/ usbcanII/ virtualcan/ 
cp ../Makefile-dev Makefile
