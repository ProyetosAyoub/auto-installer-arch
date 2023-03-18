#!/bin/bash

# Configure keymap
loadkeys es

# Select editor
EDITOR=nano

# Automatic configure mirrorlist
pacman -Syy
pacman -S reflector
reflector --country Spain --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Create partitions
# En este ejemplo se crearán tres particiones: /dev/sda1 para boot, /dev/sda2 para swap y /dev/sda3 para root
echo -e "o\nn\np\n1\n\n+500M\nn\np\n2\n\n+2G\nn\np\n3\n\n\nw" | fdisk /dev/sda

# Format devices
mkfs.ext4 /dev/sda1
mkswap /dev/sda2
mkfs.ext4 /dev/sda3

# Install system base
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
swapon /dev/sda2
pacstrap /mnt base linux linux-firmware

# Configure fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configure hostname
echo "myhostname" > /mnt/etc/hostname

# Configure timezone
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
arch-chroot /mnt hwclock --systohc

# Configure locale
echo "es_ES.UTF-8 UTF-8" > /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=es_ES.UTF-8" > /mnt/etc/locale.conf

# Configure mkinitcpio
arch-chroot /mnt mkinitcpio -P

# Install/Configure bootloader
arch-chroot /mnt pacman -S grub
arch-chroot /mnt grub-install /dev/sda
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Configure mirrorlist
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# Configure root password
arch-chroot /mnt passwd

echo "¡La instalación de Arch Linux ha finalizado con éxito!
Faltan por instalar los siguientes componentes:
- Entorno gráfico
- Gestor de inicio (por ejemplo, LightDM)
- Drivers de hardware específicos (por ejemplo, drivers de tarjeta gráfica o de red)" 
