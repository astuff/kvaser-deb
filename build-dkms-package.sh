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

for d in */; do
  if [ -e "$d/installscript.sh" ] ; then
    cd $d

    # Create new install scripts that don't install the modules directly
    sudo cat installscript.sh | sed -e "/install -D -m 644 \$MODNAME.ko \/lib\/modules\/\`uname -r\`\/kernel\/drivers\/usb\/misc\/\$MODNAME.ko/,+3d" -e "/install -D -m 644 \$MODNAME.ko \/lib\/modules\/\`uname -r\`\/kernel\/drivers\/usb\/misc/,+3d" -e "/install -m 644 \$MODNAME.ko \/lib\/modules\/\`uname -r\`\/kernel\/drivers\/char\//,+3d" > mod-installscript.sh
    chmod +x mod-installscript.sh

    # Fix bug that keeps modules from building with KERNELRELEASE argument
    if [ -e "Makefile" ] ; then
        cat Makefile | sed '/^ifneq (\$(KERNELRELEASE),)$/ {N;N;N;N;s/ifneq (\$(KERNELRELEASE),)\n\tRUNDIR := \$(src)\nelse\n\tRUNDIR := \$(PWD)\nendif/RUNDIR := \$(PWD)/}' > Makefile-temp
        mv Makefile-temp Makefile
    fi

    cd ..
  fi
done

cp -r ../linuxcan-dkms-mkdsc .

# Modify debian/changelog with correct OS version
sed -i "s/stable/${OS_VER}/" linuxcan-dkms-mkdsc/debian/changelog

cd ..

echo ""
echo "Moving linuxcan folder to /usr/src/linuxcan-$VERSION..."

# Rename source folder to what DKMS expects
sudo mv linuxcan $INSTALL_DIR

# Do the thing
echo ""
echo "Building DKMS source module..."
sudo dkms add linuxcan/$VERSION
sudo dkms mkdsc linuxcan/$VERSION --source-only

mkdir dsc
cp -R /var/lib/dkms/linuxcan/$VERSION/dsc/* dsc/
cd dsc
debsign -k"Joshua Whitley <jwhitley@autonomoustuff.com>" linuxcan-dkms_${VERSION}_source.changes
dput ppa:jwhitleyastuff/linuxcan-dkms linuxcan-dkms_${VERSION}_source.changes
echo ""
echo "Done!"

exit
