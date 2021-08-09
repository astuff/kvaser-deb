#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$(realpath -s "$0")")"
OS_VER=$(lsb_release -cs)
SDK_COMMIT="$1"
VER_SUFFIX="$2"
UPLOAD="$3"

if [ -z "$SDK_COMMIT" ]; then
  SDK_COMMIT=master
fi

echo ""
echo "Remember to modify the changelog in debian-canlib to include the current release notes."
echo "If you need to modify it now, hit [CTRL+C]. Otherwise hit [ENTER] to continue."
read STUFF

cd "$SCRIPT_DIR"

# Check for required files/folders
if [ ! -e "canlib/debian-canlib" ]; then
  echo ""
  echo "debian-canlib directory not found in canlib folder. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "canlib/Makefile-canlib" ]; then
  echo ""
  echo "Makefile-canlib not found in canlib folder. Exiting..." 1>&2
  exit -1
fi

rm -rf BUILD/
mkdir BUILD
cd BUILD/

# Clone linuxcan folder
git clone --depth=1 --branch "$SDK_COMMIT" https://github.com/astuff/kvaser-linuxcan

mv kvaser-linuxcan/ kvaser-canlib/

# Get version of linuxcan
VERSION=$(cat kvaser-canlib/moduleinfo.txt | grep version | sed -e "s/version=//" -e "s/_/./g" -e "s/\r//g")
DEBIAN_VERSION=${VERSION}-0ubuntu0~ppa

if [ -n "$VER_SUFFIX" ]; then
  DEBIAN_VERSION=${DEBIAN_VERSION}$VER_SUFFIX
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
if [ "$UPLOAD" == "upload" ]; then
  echo "Uploading..."
  dput ppa:astuff/kvaser-linux kvaser-canlib-dev_${DEBIAN_VERSION}_source.changes
  echo "Upload complete"
else
  echo "Upload skipped"
fi

cd kvaser-canlib/
echo ""
echo "Building & installing locally for use with linlib ..."
debuild --build=binary -sa

cd ..
dpkg -i kvaser-canlib-dev_${DEBIAN_VERSION}_*.deb

echo "Done"