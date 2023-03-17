#!/bin/bash

# Ask for disk name
echo "Please enter the name of the disk you want to install Arch Linux on (e.g. /dev/sda):"
read disk

# Ask for partition sizes
echo "Please enter the size of the root partition in GB (e.g. 20):"
read root_size

echo "Please enter the size of the home partition in GB (e.g. 50):"
read home_size

echo "Please enter the size of the swap partition in GB (e.g. 8):"
read swap_size

# Calculate partition sizes
root_end=$((root_size + home_size + swap_size + 1))GB
home_end=$((home_size + swap_size + 1))GB
swap_end=$((swap_size + 1))GB

# Create partitions
sgdisk -o ${disk}
sgdisk -n 1:2048:+512M -t 1:ef02 -c 1:"BIOS boot partition" ${disk}
sgdisk -n 2:0:${root_end} -t 2:8300 -c 2:"Linux root partition" ${disk}
sgdisk -n 3:0:${home_end} -t 3:8300 -c 3:"Linux home partition" ${disk}
sgdisk -n 4:0:${swap_end} -t 4:8200 -c 4:"Linux swap partition" ${disk}

# Make the boot partition bootable
sgdisk ${disk} -A 1:set:2

# Format partitions
mkfs.ext4 ${disk}2
mkfs.ext4 ${disk}3
mkswap ${disk}4
swapon ${disk}4

# Mount partitions
mount ${disk}2 /mnt
mkdir /mnt/home
mount ${disk}3 /mnt/home

# Install base system
pacstrap /mnt base base-devel linux linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt

# Set the timezone
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

# Set the locale
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Set the hostname
echo "Please enter the hostname for the system:"
read hostname
echo "${hostname}" > /etc/hostname

# Set the root password
echo "Please set the root password:"
passwd

# Install and configure the bootloader
pacman -S grub

grub-install --target=i386-pc --recheck ${disk}

sed -i 's/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Exit chroot and unmount partitions
exit

umount -R /mnt

echo "Arch Linux has been installed successfully. You may now remove the installation media and reboot the system."
