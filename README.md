# DKMS Installer for Kvaser Linuxcan #

Installation instructions:

- If linuxcan is already installed:
  - `cd /usr/src/linuxcan`
  - `sudo make uninstall`
- Download and install:
  - `sudo apt-get install dkms`
  - `cd ~/Downloads`
  - `git clone https://github.com/JWhitleyAStuff/linuxcan-dkms`
  - `cd linuxcan-dkms`
  - `sudo ./dkmsify.sh`

Prerequisites:

- sed
- dkms
- Kernel headers (linux-headers-generic on Ubuntu)

**NOTE:** The installer expects linuxcan to be at /usr/src/linuxcan.
