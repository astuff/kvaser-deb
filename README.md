# DKMS Installer for Kvaser Linuxcan #

h2. Installation instructions

- If linuxcan is already installed (not as a DKMS module):
  - `$ cd /usr/src/linuxcan`
  - `$ sudo make uninstall`
- Download and install:
  - `$ sudo apt-get install dkms`
  - `$ cd ~/Downloads`
  - `$ git clone https://github.com/JWhitleyAStuff/linuxcan-dkms`
  - `$ cd linuxcan-dkms`
  - `wget https://www.kvaser.com/downloads-kvaser/?d_version_id=1193 (this is version 5.22.392)
  - `$ sudo ./dkmsify.sh`

Prerequisites:

- `sed`
- `dkms`
- Kernel headers (`linux-headers-generic` on Ubuntu)

h2. Reinstallation instructions

- If linuxcan was previously installed but is currently unable to detect connected hardware, it's required to rebuild the kernel modules:
  - `$ sudo dkms remove linuxcan/<digit-version-here> -k $(uname -r)`
  - `$ sudo dkms install linuxcan/<digit-version-here>`
