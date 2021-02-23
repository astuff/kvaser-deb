#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OS_VER=$(lsb_release -cs)
SDK_COMMIT="$1"
VER_SUFFIX="$2"

if [ -z "$SDK_COMMIT" ]; then
  SDK_COMMIT=master
fi

echo ""
echo "Remember to modify the changelog in linlib/debian-linlib to include the current release notes."
echo "If you need to modify it now, hit [CTRL+C]. Otherwise hit [ENTER] to continue."
read STUFF

cd "$SCRIPT_DIR"

# Check for required files/folders
if [ ! -e "linlib/debian-linlib" ]; then
  echo ""
  echo "debian-linlib directory not found in linlib folder. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "linlib/Makefile-linlib" ]; then
  echo ""
  echo "Makefile-linlib not found in linlib folder. Exiting..." 1>&2
  exit -1
fi

rm -rf BUILD/
mkdir BUILD
cd BUILD/

# Clone linuxcan folder
git clone --branch "$SDK_COMMIT" https://github.com/astuff/kvaser-linuxcan

mv kvaser-linuxcan/ kvaser-linlib/

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
dput ppa:astuff/kvaser-linux kvaser-linlib-dev_${DEBIAN_VERSION}_source.changes
echo "Done!"
