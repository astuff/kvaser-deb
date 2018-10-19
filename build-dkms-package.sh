#!/bin/bash

PWD=$(pwd)

# Exit if any command fails
set -e

# Check for required files/folders
if [ ! -e "$PWD/linuxcan.tar.gz" ]; then
  echo ""
  echo "linuxcan.tar.gz must be placed in this folder. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "$PWD/dkms.conf" ]; then
  echo ""
  echo "dkms.conf not found in this directory. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "$PWD/mod-installscript.sh" ]; then
  echo ""
  echo "mod-installscript.sh not found in this directory. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "$PWD/linuxcan-dkms-mkdsc" ]; then
  echo ""
  echo "linuxcan-dkms-mkdsc directory not found. Exiting..." 1>&2
  exit -1
fi

# Delete existing directories if they exist
if [ -d "$PWD/linuxcan" ]; then
  rm -r linuxcan/
  echo ""
  echo "linuxcan directory deleted"
fi

if [ -d "$PWD/dsc" ]; then
  rm -r dsc/
  echo ""
  echo "dsc directory deleted"
fi

# Extract linuxcan folder
tar xf linuxcan.tar.gz

# Get version of linuxcan
VERSION=$(cat linuxcan/moduleinfo.txt | grep version | sed -e "s/version=//" -e "s/_/./g" -e "s/\r//g")
DEBIAN_VERSION=${VERSION}-0ubuntu0~ppa

if [ $# -gt 0 ]; then
  DEBIAN_VERSION=${DEBIAN_VERSION}$1
else
  DEBIAN_VERSION=${DEBIAN_VERSION}0
fi

OS_VER=$(lsb_release -cs)

INSTALL_DIR=/usr/src/linuxcan-$VERSION

# Delete version-specific folders
if [ -d "/usr/src/linuxcan-${VERSION}" ]; then
  sudo rm -r /usr/src/linuxcan-${VERSION}
  echo ""
  echo "linuxcan-${VERSION} directory deleted"
fi

if [ -d "/var/lib/dkms/linuxcan/${VERSION}" ]; then
  sudo rm -r /var/lib/dkms/linuxcan/${VERSION}
  echo ""
  echo "linuxcan/${VERSION} dkms directory deleted"
fi

# Copy necessary files
echo ""
echo "Copying files..."
cp dkms.conf linuxcan/
cp mod-installscript.sh linuxcan/

# Modify dkms.conf with correct version
sed -i "s/PACKAGE_VERSION=\"\"/PACKAGE_VERSION=\"$VERSION\"/" linuxcan/dkms.conf

echo ""
echo "Editing install scripts and Makefiles to make compatible with module install..."
cd linuxcan/

# Fix bug that keeps linlib from building in Makefile (gets built in post-install script anyway)
sed -i 's/USERLIBS  += linlib/#USERLIBS  += linlib/g' Makefile

# Modify installation scripts and makefiles
for d in */; do
  if [ -e "$d/installscript.sh" ] ; then
    cd $d

    # Create new install scripts that don't install the modules directly
    sudo cat installscript.sh | sed -e "/install -D -m 644 \$MODNAME.ko \/lib\/modules\/\`uname -r\`\/kernel\/drivers\/usb\/misc\/\$MODNAME.ko/,+3d" -e "/install -D -m 644 \$MODNAME.ko \/lib\/modules\/\`uname -r\`\/kernel\/drivers\/usb\/misc/,+3d" -e "/install -m 644 \$MODNAME.ko \/lib\/modules\/\`uname -r\`\/kernel\/drivers\/char\//,+3d" > mod-installscript.sh
    chmod +x mod-installscript.sh

    if [ -e "Makefile" ] ; then
      # Fix bug that keeps modules from building with KERNELRELEASE argument
      sed -i '/^ifneq (\$(KERNELRELEASE),)$/ {N;N;N;N;s/ifneq (\$(KERNELRELEASE),)\n\tRUNDIR := \$(src)\nelse\n\tRUNDIR := \$(PWD)\nendif/RUNDIR := \$(PWD)/}' Makefile
    fi

    cd ..
  fi
done

cp -r ../linuxcan-dkms-mkdsc .

# Modify debian/changelog with correct OS and package versions
sed -i "s/stable/${OS_VER}/" linuxcan-dkms-mkdsc/debian/changelog

cd ..

echo ""
echo "Moving linuxcan folder to $INSTALL_DIR..."

# Rename source folder to what DKMS expects
sudo mv linuxcan $INSTALL_DIR

# Do the thing
echo ""
echo "Building DKMS source module..."
echo ""
sudo dkms add linuxcan/$VERSION
sudo dkms mkdsc linuxcan/$VERSION --source-only

# Proper DKMS Package Instructions: http://chrisarges.net/2013/09/05/building-proper-debian-source-package.html
mkdir dsc
cp -R /var/lib/dkms/linuxcan/$VERSION/dsc/* dsc/
cd dsc

# Unpack the dsc
dpkg-source -x linuxcan-dkms_$VERSION.dsc
cd linuxcan-dkms-${VERSION}

# Fix permissions
chmod -x debian/co* debian/dirs debian/ch*

# Edit the package version
echo ""
echo "Editing auto-generated package..."
echo ""
sed -i "s/$VERSION/$DEBIAN_VERSION/g" debian/changelog
echo 9 > debian/compat

cd linuxcan-${VERSION}
debuild -S
cd ../..

# Upload
dput ppa:jwhitleyastuff/linuxcan-dkms linuxcan-dkms_${DEBIAN_VERSION}_source.changes
echo ""
echo "Done!"

exit
