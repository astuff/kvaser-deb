# Debian Package Generation Scripts for Kvaser Linux Drivers and SDK

## Usage

- Download the Linuxcan (Kvaser Linux) Drivers and SDK from https://kvaser.com/download/
- Place the linuxcan.tar.gz file in the root of this repo
- For uploading to PPA jwhitleyastuff/linuxcan-dkms (one DKMS package for all of linuxcan):
  - `$ ./package-dkms.sh`
- For uploading to PPA jwhitleyastuff/kvaser-linux (separate packages for canlib, linlib, and drivers):
  - `$ ./package-canlib.sh`
  - `$ ./package-linlib.sh`
  - `$ ./package-drivers.sh`

The order of the above commands **does matter** as the dependencies trickle down. Drivers depends on linlib and canlib, linlib depends on canlib.

## Prerequisites

- `sed`
- `dkms`
- Kernel headers (`linux-headers-generic` on Ubuntu)

## Installation of the generated packages

- `jwhitleyastuff/linuxcan-dkms`:
  - `$ sudo apt-add-repository ppa:jwhitleyastuff/linuxcan-dkms`
  - `$ sudo apt install linuxcan-dkms`
- `jwhitleyastuff/kvaser-linux`:
  - `$ sudo apt-add-repository ppa:jwhitleyastuff/kvaser-linux`
  - `$ sudo apt install kvaser-canlib-dev kvaser-linlib-dev kvaser-drivers-dkms`
