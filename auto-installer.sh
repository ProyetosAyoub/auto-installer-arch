#!/bin/bash

# Configure Keymap
loadkeys es

# Select Editor
EDITOR=nano
export EDITOR

# Create partition
fdisk /dev/sda <<EOF
o
n
p
1

+1G
n
p
2

+2G
n
p
3


t
2
82
w
EOF

# Format device
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda3
mkswap /dev/sda2
swapon /dev/sda2

# Install system base
mount /dev/sda1 /mnt
pacstrap /mnt base base-devel linux linux-firmware

# Configure fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configure hostname
echo "myhostname" > /mnt/etc/hostname

# Configure timezone
ln -sf /usr/share/zoneinfo/America/New_York /mnt/etc/localtime

# Configure hardware clock
hwclock --systohc --utc

# Configure locale
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
arch-chroot /mnt locale-gen

# Configure mkinitcpio
arch-chroot /mnt mkinitcpio -p linux

# Install/Configure bootloader
arch-chroot /mnt pacman -S --noconfirm grub
arch-chroot /mnt grub-install /dev/sda
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Configure mirrorlist
arch-chroot /mnt pacman -Sy --noconfirm reflector
arch-chroot /mnt reflector --latest 200 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Configure root password
arch-chroot /mnt passwd

# Install Desktop Environment and Display Manager (for example, Xfce and LightDM)
arch-chroot /mnt pacman -S --noconfirm xorg-server xfce4 lightdm lightdm-gtk-greeter

# Install Hardware Specific Drivers (for example, Nvidia graphics card drivers)
arch-chroot /mnt pacman -S --noconfirm nvidia nvidia-utils

# Print a message with remaining steps
echo "Installation complete. You may need to manually configure some additional settings depending on your system hardware and preferences, such as network configuration, sound settings, etc." 
