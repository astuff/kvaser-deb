# Debian Package Generation Scripts for Kvaser Linux Drivers and SDK

## Usage

- Download the Linuxcan (Kvaser Linux) Drivers and SDK from https://kvaser.com/download/
- Place the `linuxcan.tar.gz` file in the root of this repo
- For uploading to PPA astuff/kvaser-linux (separate packages for `canlib`, `linlib`, and `drivers`):
  - `$ ./package-canlib.sh`
  - `$ ./package-linlib.sh`
  - `$ ./package-drivers.sh`

The order of the above commands **does matter** as `linlib` depends on `canlib`.

## Prerequisites

- `sed`
- `dkms`
- Kernel headers (`linux-headers-generic` on Ubuntu)

## Installation of the generated packages

- `astuff/kvaser-linux`:
  - `$ sudo apt-add-repository ppa:astuff/kvaser-linux`
  - `$ sudo apt install kvaser-canlib-dev kvaser-linlib-dev kvaser-drivers-dkms`
