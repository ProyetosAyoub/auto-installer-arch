#!/bin/bash

# Verificar la conexión a Internet
ping -c 3 google.com

# Configurar la distribución de teclado para España
loadkeys es

# Verificar si la unidad de disco es la correcta (/dev/sda en este caso)
lsblk

# Crear partición para boot de 1GB
echo -e "n\np\n1\n\n+1G\nw" | fdisk /dev/sda
mkfs.ext4 /dev/sda1

# Crear partición para swap de 2GB
echo -e "n\np\n2\n\n+2G\nw" | fdisk /dev/sda
mkswap /dev/sda2
swapon /dev/sda2

# Crear partición para root de 100GB
echo -e "n\np\n3\n\n+100G\nw" | fdisk /dev/sda
mkfs.ext4 /dev/sda3

# Crear partición para home con el resto del espacio disponible
echo -e "n\np\n4\n\n\nw" | fdisk /dev/sda
mkfs.ext4 /dev/sda4

# Montar particiones
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir /mnt/home
mount /dev/sda4 /mnt/home

# Actualizar el archivo fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configurar el idioma para España
echo "es_ES.UTF-8 UTF-8" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=es_ES.UTF-8" > /mnt/etc/locale.conf

# Configurar la zona horaria para España
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
arch-chroot /mnt hwclock --systohc

# Configurar el nombre del equipo
echo "myhostname" > /mnt/etc/hostname
echo "127.0.0.1 localhost" >> /mnt/etc/hosts
echo "::1 localhost" >> /mnt/etc/hosts
echo "127.0.1.1 myhostname.localdomain myhostname" >> /mnt/etc/hosts

# Instalar y configurar el gestor de arranque GRUB
arch-chroot /mnt pacman -S grub
arch-chroot /mnt grub-install /dev/sda
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Configurar el kernel de carga inicial
echo "default arch" > /mnt/boot/loader/loader.conf
echo "timeout 3" >> /mnt/boot/loader/loader.conf

# Instalar NetworkManager
arch-chroot /mnt pacman -S networkmanager

# Habilitar NetworkManager
arch-chroot /mnt systemctl enable NetworkManager.service

# Salir del arch-chroot y limpiar el sistema
umount -R /mnt
rmdir /mnt/boot
rmdir /mnt/home

echo "La instalación ha finalizado con éxito"
