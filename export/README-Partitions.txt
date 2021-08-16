Greetings!

You've just received an encrypted USB-Drive. This drive was encrypted with
VeraCrypt (https://www.veracrypt.fr) to ensure maximal platform independence.
It contains two separate partitions:
1. This FAT32-Partition your currently reading from.
2. An encrypted VeraCrypt-Volume that needs the VeraCrypt-Software to be opened.

If you've already installed VeraCrypt you can ignore this partition and proceed
with opening the second partition using the eparately transferred passphrase.
Otherwise, you can install VeraCrypt using the delivered installers on the first
partition (for offline usage) or download and install the latest version from
the official website (see above).

Installation Information
1. Microsoft WINDOWS
	The delivered EXE is a portable version of VeraCrypt compatible with
	Windows 8 and newer.
	The created files can be deleted after the usage without affecting any
	system files.
	If you're using VeraCrypt regularly, a version that will be installed to
	your system can be found on the VeraCrypt website.
2. Linux
	The tar.bz2-archive contains generic installers for the GUI an CMD-Only
	edition of VeraCrypt booth for 32- and 64-bit.
	You have to extract the archive to your hard drive, make the wanted
	installer executable and execute it.
3. MAC OS
	Requires Mojave and newer.
	In order to install VeraCrypt from the DMG you need to install MACFUSE
	first.

Opening the data
1. After installation, execute VeraCrypt
	- WIN: double-click the extracted EXE
	- Linux: Terminal: veracrypt
	- Mac: Open application
2. Select a mount point from the upper list
3. Click select drive (middle right)
	- Select the partition that your operating system is unable to open
4. Click mount and enter passphrase
5. double-click on mount point in list to open folder or use the folder browser

