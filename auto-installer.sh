#!/bin/bash

# Configuración del teclado
loadkeys es

# Conexión a Internet
wifi-menu # Si estás conectado a una red inalámbrica

# Actualizar la hora del sistema
timedatectl set-ntp true

# Crear partición para boot de 1GB
echo -e "n\np\n1\n\n+1G\nw" | fdisk /dev/sda
mkfs.ext4 /dev/sda1
parted /dev/sda set 1 boot on
# Crear partición para swap de 2GB
echo -e "n\np\n2\n\n+2G\nw" | fdisk /dev/sda
mkswap /dev/sda2
swapon /dev/sda2

# Crear partición para home con el resto del espacio disponible
echo -e "n\np\n3\n\n\nw" | fdisk /dev/sda
mkfs.ext4 /dev/sda3

# Montar particiones
mount /dev/sda3 /mnt
mkdir /mnt/boot /mnt/var
mount /dev/sda1 /mnt/boot
mkdir /mnt/home
mount /dev/sda3 /mnt/home

echo "Ya estan montaldas las particiones" 

# Configurar la zona horaria
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc

# Configurar el idioma
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" >> /etc/locale.conf

# Configurar el nombre del equipo
echo "arch-ayoub" >> /etc/hostname

# Configurar el archivo hosts
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 archayoub.localdomain archayoub" >> /etc/hosts

# Configurar la contraseña del root
passwd

# Crear un usuario y otorgarle permisos de sudo
useradd -m -g users -G wheel -s /bin/bash ayoub

# Configurar la contraseña del usuario
passwd ayoub

echo "ayoub ALL=(ALL) ALL" >> /etc/sudoers

# Instalar el cargador de arranque
pacman -S grub
grub-install --target=i386-pc --boot-directory=/mnt/boot /dev/sda
sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT=".*"|GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Instalación del kernel
pacman -S linux

#Indicamos el kernel de carga inicial
mkinitcpio -p linux

# Configurar la contraseña del root
passwd

# Configurar la contraseña del usuario
passwd ayoub

# Salir de chroot, desmontar las particiones y reiniciar
exit
umount -R /mnt

