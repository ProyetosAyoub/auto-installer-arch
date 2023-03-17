#!/bin/bash

# Set up the disk
echo "Enter the disk to install Arch Linux to (e.g. /dev/sda):"
read disk

fdisk ${disk} << EOF
o
n
p
1

+512M
a
1
n
p
2


t
2
82
w
EOF

# Format the partitions
mkfs.ext4 ${disk}2
mkswap ${disk}1

# Mount the partitions
swapon ${disk}1
mount ${disk}2 /mnt

# Install Arch Linux
pacstrap /mnt base base-devel linux linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt

# Set the time zone
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

# Set the locale
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Set the hostname
echo "Enter the hostname for the system:"
read hostname

echo "${hostname}" >> /etc/hostname

# Set the root password
echo "Set the root password:"
passwd

# Install and configure the bootloader
pacman -S grub

grub-install --recheck ${disk}

sed -i 's/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Exit the chroot and unmount the partitions
exit

umount -R /mnt

echo "Arch Linux has been installed successfully. You may now remove the installation media and reboot the system."
