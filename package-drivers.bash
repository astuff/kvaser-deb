#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$(realpath -s "$0")")"
OS_VER=$(lsb_release -cs)
SDK_COMMIT="$1"
VER_SUFFIX="$2"

if [ -z "$SDK_COMMIT" ]; then
  SDK_COMMIT=master
fi

echo ""
echo "Remember to modify the changelog in drivers/kvaser-drivers-dkms-mkdsc/debian to include the current release notes."
echo "If you need to modify it now, hit CTRL+C. Otherwise hit enter to continue."
read STUFF

cd "$SCRIPT_DIR"

# Check for required files/folders
if [ ! -e "drivers/dkms.conf" ]; then
  echo ""
  echo "dkms.conf not found in drivers directory. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "drivers/mod-installscript.sh" ]; then
  echo ""
  echo "mod-installscript.sh not found in drivers directory. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "drivers/kvaser-drivers-dkms-mkdsc" ]; then
  echo ""
  echo "kvaser-drivers-dkms-mkdsc directory not found in drivers directory. Exiting..." 1>&2
  exit -1
fi

rm -rf BUILD/
mkdir BUILD
cd BUILD/

# Clone linuxcan folder
git clone --depth=1 --branch "$SDK_COMMIT" https://github.com/astuff/kvaser-linuxcan linuxcan

# Get version of linuxcan
VERSION=$(cat linuxcan/moduleinfo.txt | grep version | sed -e "s/version=//" -e "s/_/./g" -e "s/\r//g")
DEBIAN_VERSION=${VERSION}-0ubuntu0~ppa

if [ -n "$VER_SUFFIX" ]; then
  DEBIAN_VERSION=${DEBIAN_VERSION}$VER_SUFFIX
else
  DEBIAN_VERSION=${DEBIAN_VERSION}0
fi

OS_VER=$(lsb_release -cs)
INSTALL_DIR=/usr/src/kvaser-drivers-$VERSION

# Delete version-specific folders
if [ -d "/usr/src/kvaser-drivers-${VERSION}" ]; then
  rm -r /usr/src/kvaser-drivers-${VERSION}
  echo ""
  echo "kvaser-drivers-${VERSION} directory deleted"
fi

if [ -d "/var/lib/dkms/kvaser-drivers/${VERSION}" ]; then
  rm -r /var/lib/dkms/kvaser-drivers/${VERSION}
  echo ""
  echo "kvaser-drivers/${VERSION} dkms directory deleted"
fi

# Copy necessary files
echo ""
echo "Copying files..."
cp ../drivers/dkms.conf linuxcan/
cp ../drivers/mod-installscript.sh linuxcan/

# Modify dkms.conf with correct version
sed -i "s/PACKAGE_VERSION=\"\"/PACKAGE_VERSION=\"$VERSION\"/" linuxcan/dkms.conf

echo ""
echo "Editing install scripts and Makefiles to make compatible with module install..."
cd linuxcan/

# Remove canlib/linlib
rm -r canlib/ doc/ linlib/
rm include/canlib.h include/linlib.h include/obsolete.h

# Patch Makefile to not build canlib/linlib
patch < ../../drivers/Makefile.patch

# Modify installation scripts and makefiles
for d in */; do
  if [ -e "$d/installscript.sh" ] ; then
    cd $d

    # Create new install scripts that don't install the modules directly
    cat installscript.sh | sed -e "/install -D -m 644 \$MODNAME.ko \/lib\/modules\/\`uname -r\`\/kernel\/drivers\/usb\/misc\/\$MODNAME.ko/,+3d" -e "/install -D -m 644 \$MODNAME.ko \/lib\/modules\/\`uname -r\`\/kernel\/drivers\/usb\/misc/,+3d" -e "/install -m 644 \$MODNAME.ko \/lib\/modules\/\`uname -r\`\/kernel\/drivers\/char\//,+3d" > mod-installscript.sh
    chmod +x mod-installscript.sh

    if [ -e "Makefile" ] ; then
      # Fix bug that keeps modules from building with KERNELRELEASE argument
      sed -i '/^ifneq (\$(KERNELRELEASE),)$/ {N;N;N;N;s/ifneq (\$(KERNELRELEASE),)\n\tRUNDIR := \$(src)\nelse\n\tRUNDIR := \$(PWD)\nendif/RUNDIR := \$(PWD)/}' Makefile
    fi

    cd ..
  fi
done

cp -r ../../drivers/kvaser-drivers-dkms-mkdsc .

# Modify debian/changelog with correct OS and package versions
sed -i "s/stable/${OS_VER}/" kvaser-drivers-dkms-mkdsc/debian/changelog

cd ..

echo ""
echo "Moving linuxcan folder to $INSTALL_DIR..."

# Rename source folder to what DKMS expects
mv linuxcan $INSTALL_DIR

# Do the thing
echo ""
echo "Building DKMS source module..."
echo ""
dkms add kvaser-drivers/$VERSION
dkms mkdsc kvaser-drivers/$VERSION --source-only

# Proper DKMS Package Instructions: http://chrisarges.net/2013/09/05/building-proper-debian-source-package.html
mkdir dsc
cp -R /var/lib/dkms/kvaser-drivers/$VERSION/dsc/* dsc/
cd dsc

# Unpack the dsc
dpkg-source -x kvaser-drivers-dkms_$VERSION.dsc
cd kvaser-drivers-dkms-${VERSION}

# Fix permissions
chmod -x debian/co* debian/dirs debian/ch*

# Edit the package version
echo ""
echo "Editing auto-generated package..."
sed -i "s/$VERSION/$DEBIAN_VERSION/g" debian/changelog
echo 9 > debian/compat

cd kvaser-drivers-${VERSION}
debuild -S
cd ../..

# Upload
echo ""
echo "Uploading..."
dput ppa:astuff/kvaser-linux kvaser-drivers-dkms_${DEBIAN_VERSION}_source.changes
echo "Done!"
