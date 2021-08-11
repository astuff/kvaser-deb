#!/bin/bash
set -e

apt-get -qq update
DEBIAN_FRONTEND=noninteractive apt-get -y install lsb-release git devscripts cppcheck debhelper dkms software-properties-common usbutils
