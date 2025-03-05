# QNAP GRUB Status

- [QNAP GRUB Status](#qnap-grub-status)
  - [Overview](#overview)
  - [Compilation](#compilation)
    - [Building using distro/other sources](#building-using-distroother-sources)
    - [Building using official GRUB source](#building-using-official-grub-source)
  - [Installation](#installation)
    - [Adding the module](#adding-the-module)
      - [System installation](#system-installation)
      - [Manual installation](#manual-installation)
    - [Configuring Linux](#configuring-linux)
  - [Removal](#removal)

## Overview

This is a small GRUB module that when inserted, it sets the status LED on supported QNAP NAS devices (devices that have the IT8528 or compatible EC) to blink a red-green alternating pattern to indicate system is booting. Once the system is booted, the status LED can be set back to solid green under a booted Linux OS using the [qnap8528] module.

## Compilation
There are two ways to compile the module, the first uses the official GRUB git repo to obtain the source code, the second (which I recommend if available) is to use the sources from the distribution you are using. 

The makefile attempts to detect the current GRUB version by checking the version string of `grub-install`. If this is not available or a different version is needed, `GRUB_VER=2.xx` can be provided to the `make` command to set the version (only GRUB2 is supported).

The makefile by default targets and configures GRUB for *x86_64* with EFI support, this can be changed in the Makefile.

Once the build process finishes, the module should be in the projects root directory with the name `qnap8528led.mod`.

Before building the module, the following packages should be installed `python3 gettext autopoint pkg-config build-essential autoconf automake bison flex`

### Building using distro/other sources
1. Clone this repository
2. Download your grub sources, extract to a directory named `grub2-2.xx` (`xx` is the minor version number) in the projects root directory. On debian based systems, this can be done with `apt source grub2`.
3. Run `make` it should alert `Using local GRUB source directory (<directory>). Skipping git checkout.` 

### Building using official GRUB source
1. Clone this repository recursively (`git clone --recurse-submodules ...`)
2. Run `make`, it should alert `Using GRUB git submodule. Checking out tag: <version>`

## Installation

The module can be either added directly to the `/boot/`

### Adding the module
>**Warning:** There are many ways GRUB can be installed and configured, which vary by system. Messing up GRUB can cause the system to not boot. Make sure you are familiar with GRUB, know the changes you are making and have a recovery plan. I do not bare any responsibility for your system.



#### System installation
>**Note:** Tested on a standard, headless, x64 Debian bookworm w/ UEFI.

1. Copy the module to `/usr/lib/grub/x86_64-efi/` (or whatever target you configured and have).
2. Update `/etc/default/grub` to automatically insert the module on boot by adding `GRUB_PRELOAD_MODULES="qnap8528led"` to the file
3. Reinstall GRUB using `grub-install`
4. Update the GRUB config using `update-grub`.  

#### Manual installation
1. Copy the module to the modules directory under `/boot/grub/x86_64-efi` (or whatever target you configured and have)
2. Add the line `insmod qnap8528led` to the beginning of `/boot/grub/grub.cfg` (or wherever you might want the indicator to start, for example, in the primary `menuentry`).

### Configuring Linux
Install qnap8528 (https://github.com/0xGiddi/qnap8528) and add a systemd service or script to run at the point you consider the device booted and ready and set `/sys/class/led/qnap8528::status/brightness` to `1`, this will set the LED to solid green. 

**TODO: Add here example service**

## Removal
If the module was manually added, or, for some reason boot is broken (if needed use a live CD / disk dock), remove the `insmod qnap8528led.mod` directive from `/boot/grub/grub.cfg`. If the module was installed using `grub-install`, revert the changes to the `/etc/default/grub` file and rerun `grub-install`. Optionally delete the module itself from `/boot/grub/x86_64-efi/` (or whatever target architecture you configured). 
