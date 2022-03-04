# Debian Package Generation Scripts for Kvaser Linux Drivers and SDK

## Usage

The scripts in this repo are meant to be used inside a docker container.
Before releasing new versions of anything, update the following changelogs:
- canlib/debian-canlib/changelog
- linlib/debian-linlib/changelog
- drivers/kvaser-drivers-dkms-mkdsc

The information for the changelog updates can be found in the [kvaser-linuxcan](https://github.com/astuff/kvaser-linuxcan) source under `doc/ReleaseNotes`.

Once the changelogs are updated, you are ready to perform the release:

1. After starting a container of your choosing, first install all required dependencies:

        bash install_dependencies.bash

1. Release kvaser-canlib-dev:

        bash package-canlib.bash [optional version tag/commit] [optional version suffix] [optional 'upload' flag]
        example:
        bash package-canlib.bash 5.35.477 0 upload

1. Release kvaser-linlib-dev:

        bash package-linlib.bash [optional version tag/commit] [optional version suffix] [optional 'upload' flag]
        example:
        bash package-linlib.bash 5.35.477 0 upload

1. Release kvaser-drivers-dkms:

        bash package-drivers.bash [optional version tag/commit] [optional version suffix] [optional 'upload' flag]
        example:
        bash package-drivers.bash 5.35.477 0 upload


The order of the above commands **does matter** as `linlib` depends on `canlib`.

**NOTE:** dput seems flakey with ftp uploads.
If the `dput` upload seems to stall, you may want to try running dput outside of the docker container from the `kvaser-deb/BUILD` directory.
You may also consider configuring dput to use sftp instead of ftp.

## Installation of the generated packages

- `astuff/kvaser-linux`:
  - `$ sudo apt-add-repository ppa:astuff/kvaser-linux`
  - `$ sudo apt install kvaser-canlib-dev kvaser-linlib-dev kvaser-drivers-dkms`

## Related Documentation

Debian package files:
https://www.debian.org/doc/manuals/maint-guide/dreq.en.html
https://www.debian.org/doc/manuals/maint-guide/dother.en.html

Ubuntu Launchpad packaging details:
https://help.launchpad.net/Packaging/PPA/BuildingASourcePackage
