#!/bin/bash
#!/bin/bash

# Set up the disk
echo "Enter the disk to install Arch Linux to (e.g. /dev/sda):"
read disk

sgdisk -Z ${disk}
sgdisk -og ${disk}
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System Partition" ${disk}

echo "Enter the size for the root partition (e.g. 30G):"
read root_size

sgdisk -n 2:0:+${root_size} -t 2:8300 -c 2:"Root Partition" ${disk}

echo "Enter the size for the swap partition (e.g. 4G):"
read swap_size

sgdisk -n 3:0:+${swap_size} -t 3:8200 -c 3:"Swap Partition" ${disk}

sgdisk -p ${disk}

# Format the partitions
mkfs.fat -F32 ${disk}1
mkfs.ext4 ${disk}2
mkswap ${disk}3

# Mount the partitions
mount ${disk}2 /mnt
mkdir /mnt/boot
mount ${disk}1 /mnt/boot
swapon ${disk}3

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
pacman -S grub efibootmgr

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck

sed -i 's/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Exit the chroot and unmount the partitions
exit

umount -R /mnt

echo "Arch Linux has been installed successfully. You may now remove the installation media and reboot the system."
