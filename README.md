# USB-Drive-Encryption Preparation with VeraCrypt
This script will help you prepare a USB-Drive to store your encrypted data.\
It will remove all existing filesystems and partitions (no data override!) and\
(for VeraCrypt-Partitions)\
- create a small FAT32 partition containing VeraCrypt installer for Windows, Linux and Mac (with a little set of instructions)
- create an empty partition with the remaining disk space
	- select this partition in VeraCrypt to use as encrypted one
OR (for VeraCrypt-Container)
- create an exFAT partition containing the same installers and another set of instructions
	- store the VeraCrypt-Container on this partition

## Software that should be installed
- bash
- sudo
- VeraCrypt
- fdisk
- mkfs.vfat
- mkfs.exfat
- unzip

## How-To Use
- download all necessary VeraCrypt installers and their dependencies
- replace the placeholder-zip (export/VeraCrypt-1.24-Installer.zip) with an archive containing the installers
- make the SH-File executable
- (optional) create an DESKTOP-File as shortcut to the SH-File
- plug in a USB-Drive
- run the script and follow the instructions

## License
This script and READMEs are published under GNU GPL v3!\
VeraCrypt (https://www.veracrypt.fr) belongs to IDRIX (https://www.idrix.fr) with its own licence.
