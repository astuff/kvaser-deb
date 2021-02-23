#!/bin/bash
set -e

apt-get -qq update
apt-get -y install lsb-release git devscripts cppcheck debhelper dkms
