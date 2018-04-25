#!/bin/bash

PWD=$(pwd)

# Exit if any command fails
set -e

# Check for root user
if [[ "$EUID" -ne 0 ]] ;
then
  echo "This script must be run as root (sudo) user. Exiting..." 1>&2
  exit -1
fi

# Check for required files/folders
if [ ! -e "$PWD/linuxcan.tar.gz" ]; then
  echo "linuxcan.tar.gz must be placed in this folder. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "$PWD/dkms.conf" ]; then
  echo "dkms.conf not found in this directory. Exiting..." 1>&2
  exit -1
fi

if [ ! -e "$PWD/mod-installscript.sh" ]; then
  echo "mod-installscript.sh not found in this directory. Exiting..." 1>&2
  exit -1
fi

# Extraact linuxcan folder
tar xvf linuxcan.tar.gz

# Get version of linuxcan
VERSION=$(cat linuxcan/moduleinfo.txt | grep version | sed -e "s/version=//" -e "s/_/./g" -e "s/\r//g")

# Copy necessary files
echo "Copying files..."
cp dkms.conf linuxcan/
cp mod-installscript.sh linuxcan/

# Modify dkms.conf with correct version
sed -i "s/PACKAGE_VERSION=\"\"/PACKAGE_VERSION=\"$VERSION\"/" linuxcan/dkms.conf

echo "Renaming linuxcan folder to linuxcan-$VERSION..."
# Rename source folder to what DKMS expects
mv linuxcan/ linuxcan-$VERSION/
cd linuxcan-$VERSION/

echo "Editing install scripts and Makefiles to make compatible with module install..."
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

echo "Moving linuxcan folder into /usr/src..."
sudo mv linuxcan-$VERSION/ /usr/src

# Do the thing
echo "Building and installing DKMS module..."
dkms remove linuxcan/$VERSION --all
dkms add linuxcan/$VERSION
dkms build linuxcan/$VERSION
dkms install --force linuxcan/$VERSION
echo "Done!"

exit
