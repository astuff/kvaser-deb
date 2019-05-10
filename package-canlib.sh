#!/bin/bash

# Exit if any command fails
set -e

PWD=$(pwd)
OS_VER=$(lsb_release -cs)

echo ""
echo "Remember to modify the changelog in linuxcan-dkms-mkdsc/debian to include the current release notes."
echo "If you need to modify it now, hit CTRL+C. Otherwise hit enter to continue."
read STUFF

# Check for required files/folders
if [ ! -e "$PWD/linuxcan.tar.gz" ]; then
  echo ""
  echo "linuxcan.tar.gz must be placed in this folder. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "$PWD/linuxcan-dkms-mkdsc" ]; then
  echo ""
  echo "linuxcan-dkms-mkdsc directory not found. Exiting..." 1>&2
  exit -1
fi

# Delete existing directories if they exist
if [ -d "$PWD/canlib" ]; then
  rm -r canlib/
  echo ""
  echo "canlib directory deleted"
fi

if [ -d "$PWD/canlib-dsc" ]; then
  rm -r canlib-dsc/
  echo ""
  echo "canlib-dsc directory deleted"
fi

# Extract linuxcan folder
tar xf linuxcan.tar.gz

mv linuxcan/ canlib/

# Get version of linuxcan
VERSION=$(cat canlib/moduleinfo.txt | grep version | sed -e "s/version=//" -e "s/_/./g" -e "s/\r//g")
DEBIAN_VERSION=${VERSION}-0ubuntu0~ppa

# Strip down to only canlib
cd canlib/
rm 10-kvaser.rules
rm -r leaf/ linlib/ mhydra/ pcican/ pcican2/ pciefd/ usbcanII/ virtualcan/ 
cp ../Makefile-canlib Makefile

if [ $# -gt 0 ]; then
  DEBIAN_VERSION=${DEBIAN_VERSION}$1
else
  DEBIAN_VERSION=${DEBIAN_VERSION}0
fi

cp -r ../canlib-debian ./debian

# Modify debian/changelog with correct OS and package versions
sed -i "s/stable/${OS_VER}/" debian/changelog
