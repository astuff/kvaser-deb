#!/bin/bash

# Exit if any command fails
set -e

PWD=$(pwd)
OS_VER=$(lsb_release -cs)

echo ""
echo "Remember to modify the changelog in debian-canlib to include the current release notes."
echo "If you need to modify it now, hit [CTRL+C]. Otherwise hit [ENTER] to continue."
read STUFF

# Check for required files/folders
if [ ! -e "$PWD/canlib/debian-canlib" ]; then
  echo ""
  echo "debian-canlib directory not found in canlib folder. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "$PWD/canlib/Makefile-canlib" ]; then
  echo ""
  echo "Makefile-canlib not found in canlib folder. Exiting..." 1>&2
  exit -1
fi

# Delete BUILD directory if it exists
if [ -d "$PWD/BUILD" ]; then
  rm -r BUILD/
fi

mkdir BUILD
cd BUILD/

# Clone linuxcan folder
git clone https://github.com/astuff/kvaser-linuxcan

mv kvaser-linuxcan/ kvaser-canlib/

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
cp ../../canlib/Makefile-canlib Makefile

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
cp -r ../../canlib/debian-canlib/ debian/
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
dput ppa:astuff/kvaser-linux kvaser-canlib-dev_${DEBIAN_VERSION}_source.changes
echo "Done!"
