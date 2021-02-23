#!/bin/bash
set -e

apt-get -qq update
apt-get -y install lsb-release git devscripts cppcheck debhelper dkms software-properties-common

# Add ppa since kvaser-linlib-dev depends on kvaser-canlib-dev
apt-add-repository ppa:astuff/kvaser-linux
apt-get -qq update
