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

main()
{
  echo ""
  echo "Remember to modify the changelog in drivers/kvaser-drivers-dkms-mkdsc/debian to include the current release notes."
  echo "If you need to modify it now, hit CTRL+C. Otherwise hit enter to continue."
  read STUFF

  cd "$SCRIPT_DIR"

  # if [ ! -e "drivers/installscript.sh" ]; then
  #   echo ""
  #   echo "installscript.sh not found in drivers directory. Exiting..." 1>&2
  #   exit -1
  # fi

  if [ ! -e "drivers/kvaser-drivers-dkms-mkdsc" ]; then
    echo ""
    echo "kvaser-drivers-dkms-mkdsc directory not found in drivers directory. Exiting..." 1>&2
    exit -1
  fi

  cleanup_previous_install

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

  modify_files

  # Copy necessary files
  echo ""
  echo "Copying files..."
  # cp -r "$SCRIPT_DIR/drivers/kvaser-drivers-dkms-mkdsc" linuxcan/

  # exit

  install_linuxcan_dkms

  cd "$SCRIPT_DIR/BUILD"

  # Copy debian folder template
  cp -r "$SCRIPT_DIR/drivers/kvaser-drivers-dkms-mkdsc" /usr/src/kvaser-drivers-$VERSION
  dkms mkdsc kvaser-drivers/$VERSION --source-only

  echo "DONE here"
  exit

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

  upload

  echo ""
  echo "Building debs locally for testing purposes ..."
  cd kvaser-drivers-dkms-${VERSION}/kvaser-drivers-${VERSION}
  debuild --build=binary -sa

  echo "Done"
}

cleanup_previous_install()
{
  # Delete dkms install
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
}

modify_files()
{
  # Modify debian/changelog with correct OS and package versions
  sed -i "s/stable/${OS_VER}/" "$SCRIPT_DIR/drivers/kvaser-drivers-dkms-mkdsc/debian/changelog"
  sed -i "s/MODULE_VERSION/${DEBIAN_VERSION}/" "$SCRIPT_DIR/drivers/kvaser-drivers-dkms-mkdsc/debian/changelog"
  sed -i "s/DATE_STAMP/$(LC_ALL=C date -R)/" "$SCRIPT_DIR/drivers/kvaser-drivers-dkms-mkdsc/debian/changelog"

  # Modify existing dkms.conf
  sed -i "s/PACKAGE_VERSION=.*/PACKAGE_VERSION=\"$VERSION\"/" linuxcan/dkms/dkms.conf
  sed -i 's/PACKAGE_NAME=.*/PACKAGE_NAME="kvaser-drivers"/' linuxcan/dkms/dkms.conf
}

install_linuxcan_dkms()
{
  cd "$SCRIPT_DIR/BUILD/linuxcan"

  # Install dkms module using kvaser's instructions
  make dkms
  KV_DKMS_TARBALL=kvaser-drivers-$VERSION-source-only.dkms.tar.gz
  echo ""
  echo "Adding $KV_DKMS_TARBALL ..."
  dkms add "$KV_DKMS_TARBALL"
  dkms status
}

upload()
{
  # Upload
  echo ""
  if [ "$UPLOAD" == "upload" ]; then
    echo "Uploading..."
    dput ppa:astuff/kvaser-linux kvaser-drivers-dkms_${DEBIAN_VERSION}_source.changes
    echo "Done!"
  else
    echo "Upload skipped"
  fi
}

main
