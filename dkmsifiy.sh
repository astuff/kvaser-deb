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
if [ ! -d "/usr/src/linuxcan" ]; then
    echo "The linuxcan source was not found at /usr/src/linuxcan. Exiting..." 1>&2
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

# Get version of linuxcan
VERSION=$(cat /usr/src/linuxcan/moduleinfo.txt | grep version | sed -e "s/version=//" -e "s/_/./g")

# Copy necessary files
echo "Copying files..."
cp dkms.conf /usr/src/linuxcan/
cp mod-installscript.sh /usr/src/linuxcan/

# Modify dkms.conf with correct version
sed -i "s/PACKAGE_VERSION=\"\"/PACKAGE_VERSION=\"$VERSION\"/" /usr/src/linuxcan/dkms.conf

echo "Renaming linuxcan folder to linuxcan-$VERSION..."
# Rename source folder to what DKMS expects
mv /usr/src/linuxcan/ /usr/src/linuxcan-$VERSION/
cd /usr/src/linuxcan-$VERSION/

echo "Editing install scripts and Makefiles to make compatible with module install..."
for d in */; do
    if [ -e "$d/installscript.sh" ] ; then
        cd $d

        # Create new install scripts that don't install the modules directly
        cat installscript.sh | sed -e "s/install -D -m 700 \$MODNAME.ko \/lib\/modules\/\`uname -r\`\/kernel\/drivers\/usb\/misc\/\$MODNAME.ko//" -e "s/install -D -m 700 \$MODNAME.ko \/lib\/modules\/\`uname -r\`\/kernel\/drivers\/usb\/misc//" -e "s/install -m 600 \$MODNAME.ko \/lib\/modules\/\`uname -r\`\/kernel\/drivers\/char\///" > mod-installscript.sh
        chmod +x mod-installscript.sh

        # Fix bug that keeps modules from building with KERNELRELEASE argument
        if [ -e "Makefile" ] ; then
            cat Makefile | sed '/^ifneq (\$(KERNELRELEASE),)$/ {N;N;N;N;s/ifneq (\$(KERNELRELEASE),)\n\tRUNDIR := \$(src)\nelse\n\tRUNDIR := \$(PWD)\nendif/RUNDIR := \$(PWD)/}' > Makefile-temp
            mv Makefile-temp Makefile
        fi

        cd ..
    fi
done

# Do the thing
echo "Building and installing DKMS module..."
dkms add linuxcan/$VERSION
dkms build linuxcan/$VERSION
dkms install linuxcan/$VERSION
echo "Done!"

exit
