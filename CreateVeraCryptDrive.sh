#!/bin/bash
clear
echo "USB-Drive-Encryption Preparation"

echo ""
#make sure script was executed as root
[ "$UID" -eq 0 ] || echo "Hello $(whoami)! Root-privileges are required."
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

echo "Enter drive to encrypt (e.g. /dev/sdb)"
read drive

fdisk $drive -l
echo "Enter number of partitions to delete (e.g. 1)"
read partitionCnt

echo ""
echo "(1) Removing old partitions..."
#use while-loop to remove all partitions on the drive with fdisk-utility
i=1
while [ $i -le $partitionCnt ]
do
fdisk $drive <<EEOF
d

w
EEOF
((i++))
done

echo ""
echo "Please remove and reconnect the USB-Drive. Hit [ENTER] afterwards."
read

echo "Preselect VeraCrypt-Methode"
echo " - for additional information visit https://www.veracrypt.fr"
echo "  1. Create encrypted partition (recommended)"
echo "  2. Create encrypted container [an file that will be mounted as drive] (more simple)"
echo "Enter number"
read methode

echo ""
echo "(2) Creating new partition(s) and filesystem(s)..."
if [ "$methode" = "1" ]
then
#use fdisk-utility to create 2 primary partitions - first using 64M to store the installers, second using the remainig space to be encrypted later on
fdisk $drive <<EEOF
n
p
1

+64M
y
t
b
a
n
p
2


w
EEOF
#create filesystem FAT32 on first partition
mkfs -t vfat "$drive"1
elif [ "$methode" = "2" ]
then
#use fdisk-utility to create a new primary partition on the drive, that uses the whole disk space
fdisk $drive <<EEOF
n
p
1


y
t
7
a
w
EEOF
#create filesystem exFAT on partition
mkfs -t exfat "$drive"1
else
echo "Invalid input! [ENTER] to exit"
read
exit 1
fi

df -h

echo ""
echo "The new partition(s) and its/their mount point(s) should be visible. If not, open drive from desktop/ mount it manually."
echo "Enter 'Mounted on'-Path of $drive"
read path
echo
echo "(3) Copying installers..."
unzip export/VeraCrypt-1.24-Installer.zip -d "$path"
if [ "$methode" = "1" ]
then
cp export/README-Partitions.txt "$path/README.txt"
else
cp export/README-File.txt "$path/README.txt"
fi

echo
echo "(4) Opening VeraCrypt..."
echo "Do you want to encrypt the drive right now (y/n)?"
read startvc
if [ "$startvc" = "y" ]
then
if [ "$methode" = "1" ]
then
#open veracrypt cli to encrypt partition
veracrypt -t -c "$drive"2
else
#open veracrypt cli to create encrypted container
veracrypt -t -c "$path/data.hc"
fi
fi

exit 0
