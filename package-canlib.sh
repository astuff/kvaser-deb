#!/bin/bash

# Exit if any command fails
set -e

PWD=$(pwd)
OS_VER=$(lsb_release -cs)

echo ""
echo "Remember to modify the changelog in canlib-debian to include the current release notes."
echo "If you need to modify it now, hit [CTRL+C]. Otherwise hit [ENTER] to continue."
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
if [ -d "$PWD/kvaser-canlib" ]; then
  rm -r kvaser-canlib/
  echo ""
  echo "kvaser-canlib directory deleted"
fi

# Extract linuxcan folder
tar xf linuxcan.tar.gz

mv linuxcan/ kvaser-canlib/

# Get version of linuxcan
VERSION=$(cat kvaser-canlib/moduleinfo.txt | grep version | sed -e "s/version=//" -e "s/_/./g" -e "s/\r//g")
DEBIAN_VERSION=${VERSION}-0ubuntu0~ppa

if [ $# -gt 0 ]; then
  DEBIAN_VERSION=${DEBIAN_VERSION}$1
else
  DEBIAN_VERSION=${DEBIAN_VERSION}0
fi

# Strip down to only canlib
cd kvaser-canlib/
rm 10-kvaser.rules
rm -r leaf/ linlib/ mhydra/ pcican/ pcican2/ pciefd/ usbcanII/ virtualcan/ 
cp ../Makefile-canlib Makefile

# Modify Makefiles for DEB install
sed -i "1s/^/prefix = \/usr\n/" canlib/Makefile
sed -i "s/install \(.*\)\/usr/install -D \1\$(DESTDIR)\$(prefix)/g" canlib/Makefile
sed -i "s/mkdir \(.*\)\/usr/mkdir \1\$(DESTDIR)\$(prefix)/g" canlib/Makefile
sed -i "s/cp \(.*\)\/usr/cp \1\$(DESTDIR)\$(prefix)/g" canlib/Makefile
sed -i "s/ln \(.*\)\/usr/ln \1\$(DESTDIR)\$(prefix)/g" canlib/Makefile
# Have to run 3 times due to combined "rm" lines
sed -i "s/rm \(.*\)\/usr/rm \1\$(DESTDIR)\$(prefix)/g" canlib/Makefile
sed -i "s/rm \(.*\)\/usr/rm \1\$(DESTDIR)\$(prefix)/g" canlib/Makefile
sed -i "s/rm \(.*\)\/usr/rm \1\$(DESTDIR)\$(prefix)/g" canlib/Makefile
sed -i "s/^.*\/sbin\/ldconfig.*$//g" canlib/Makefile

sed -i "1s/^/prefix = \/usr\n/" canlib/examples/Makefile
sed -i "s/mkdir \(.*\)\/usr/mkdir \1\$(DESTDIR)\$(prefix)/g" canlib/examples/Makefile
sed -i "s/cp \(.*\)\/usr/cp \1\$(DESTDIR)\$(prefix)/g" canlib/examples/Makefile
sed -i "s/rm \(.*\)\/usr/rm \1\$(DESTDIR)\$(prefix)/g" canlib/examples/Makefile

# Create original tarball
tar cfJ ../kvaser-canlib-dev_${VERSION}.orig.tar.xz .

# Modify debian files with correct OS and package versions
cp -r ../canlib-debian/ debian/
sed -i "s/unstable/${OS_VER}/" debian/changelog
sed -i "s/MODULE_VERSION/${DEBIAN_VERSION}/" debian/changelog
sed -i "s/DATE_STAMP/$(LC_ALL=C date -R)/" debian/changelog
sed -i "s/DATE_STAMP/$(LC_ALL=C date -R)/" debian/README.Debian

# Build the package
debuild -S -sa
cd ..

# Upload
dput ppa:jwhitleyastuff/kvaser-linux kvaser-canlib-dev_${DEBIAN_VERSION}_source.changes
echo ""
echo "Uploaded."

# Clean-up
rm -r kvaser-canlib*
echo "Done!"
