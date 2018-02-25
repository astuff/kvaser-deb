# DKMS Installer for Kvaser Linuxcan #

h2. Installation instructions

- If linuxcan is already installed:
  - `$ cd /usr/src/linuxcan`
  - `$ sudo make uninstall`
- Download and install:
  - `$ sudo apt-get install dkms`
  - `$ cd ~/Downloads`
  - `$ git clone https://github.com/JWhitleyAStuff/linuxcan-dkms`
  - `$ cd linuxcan-dkms`
  - `$ sudo ./dkmsify.sh`

Prerequisites:

- `sed`
- `dkms`
- Kernel headers (`linux-headers-generic` on Ubuntu)

**NOTE:** The installer expects linuxcan to be at /usr/src/linuxcan.


h2. Reinstallation instructions

- If linuxcan was previously installed but is currently unable to detect connected hardware, it's required to rebuild the kernel modules:
  - `$ sudo dkms remove linuxcan/<digit-version-here> -k $(uname -r)`
  - `$ sudo dkms install linuxcan/<digit-version-here>`
