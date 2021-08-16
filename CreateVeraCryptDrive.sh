#!/bin/bash
clear
echo "USB-Drive-Encryption Preparation"

echo ""
[ "$UID" -eq 0 ] || echo "Hello $(whoami)! Root-privileges are required."
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

echo "Enter drive to encrypt (e.g. /dev/sdb)"
read drive

fdisk $drive -l
echo "Enter number of partitions to delete (e.g. 1)"
read partitionCnt

echo ""
echo "(1) Removing old partitions..."
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
mkfs -t vfat "$drive"1
elif [ "$methode" = "2" ]
then
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
veracrypt

exit 0
