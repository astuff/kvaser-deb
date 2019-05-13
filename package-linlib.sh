#!/bin/bash

# Exit if any command fails
set -e

PWD=$(pwd)
OS_VER=$(lsb_release -cs)

echo ""
echo "Remember to modify the changelog in linlib/debian-linlib to include the current release notes."
echo "If you need to modify it now, hit [CTRL+C]. Otherwise hit [ENTER] to continue."
read STUFF

# Check for required files/folders
if [ ! -e "$PWD/linuxcan.tar.gz" ]; then
  echo ""
  echo "linuxcan.tar.gz must be placed in this folder. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "$PWD/linlib/debian-linlib" ]; then
  echo ""
  echo "debian-linlib directory not found in linlib folder. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "$PWD/linlib/Makefile-linlib" ]; then
  echo ""
  echo "Makefile-linlib not found in linlib folder. Exiting..." 1>&2
  exit -1
fi

# Delete BUILD directory if it exists
if [ -d "$PWD/BUILD" ]; then
  rm -r BUILD/
fi

mkdir BUILD
cd BUILD/

# Extract linuxcan folder
tar xf ../linuxcan.tar.gz

mv linuxcan/ kvaser-linlib/

# Get version of linuxcan
VERSION=$(cat kvaser-linlib/moduleinfo.txt | grep version | sed -e "s/version=//" -e "s/_/./g" -e "s/\r//g")
DEBIAN_VERSION=${VERSION}-0ubuntu0~ppa

if [ $# -gt 0 ]; then
  DEBIAN_VERSION=${DEBIAN_VERSION}$1
else
  DEBIAN_VERSION=${DEBIAN_VERSION}0
fi

# Strip down to only linlib
cd kvaser-linlib/
rm 10-kvaser.rules
rm -r canlib/ leaf/ mhydra/ pcican/ pcican2/ pciefd/ usbcanII/ virtualcan/ 
cp ../../linlib/Makefile-linlib Makefile

# Modify Makefiles for DEB install
sed -i "1s/^/prefix = \/usr\n/" linlib/Makefile
sed -i "s/install \(.*\)\/usr/install -D \1\$(DESTDIR)\$(prefix)/g" linlib/Makefile
sed -i "s/mkdir \(.*\)\/usr/mkdir \1\$(DESTDIR)\$(prefix)/g" linlib/Makefile
sed -i "s/cp \(.*\)\/usr/cp \1\$(DESTDIR)\$(prefix)/g" linlib/Makefile
sed -i "s/ln \(.*\)\/usr/ln \1\$(DESTDIR)\$(prefix)/g" linlib/Makefile
# Have to run 3 times due to combined "rm" lines
sed -i "s/rm \(.*\)\/usr/rm \1\$(DESTDIR)\$(prefix)/g" linlib/Makefile
sed -i "s/rm \(.*\)\/usr/rm \1\$(DESTDIR)\$(prefix)/g" linlib/Makefile
sed -i "s/rm \(.*\)\/usr/rm \1\$(DESTDIR)\$(prefix)/g" linlib/Makefile
sed -i "s/^.*\/sbin\/ldconfig.*$//g" linlib/Makefile

# Create original tarball
tar cfJ ../kvaser-linlib-dev_${VERSION}.orig.tar.xz .

# Modify debian files with correct OS and package versions
cp -r ../../linlib/debian-linlib/ debian/
sed -i "s/unstable/${OS_VER}/" debian/changelog
sed -i "s/MODULE_VERSION/${DEBIAN_VERSION}/" debian/changelog
sed -i "s/DATE_STAMP/$(LC_ALL=C date -R)/" debian/changelog
sed -i "s/DATE_STAMP/$(LC_ALL=C date -R)/" debian/README.Debian

# Build the package
debuild -S -sa
cd ..

# Upload
echo ""
echo "Uploading..."
dput ppa:jwhitleyastuff/kvaser-linux kvaser-linlib-dev_${DEBIAN_VERSION}_source.changes
echo "Done!"
