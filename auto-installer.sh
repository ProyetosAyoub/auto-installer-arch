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

#Instalamos el sistema

pacstrap /mnt base linux linux-firmware base-devel
pacman -Sy archlinux-keyring
pacstrap /mnt grub-bios
genfstab -p /mnt >> /mnt/etc/fstab

#Accederemos a la ruta montada

echo "Ya estas dentro y no hubo ningun problema de momento...."

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

# Instalar el cargador de arranque
pacman -S grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Crear un usuario y otorgarle permisos de sudo
useradd -m -G wheel -s /bin/bash ayoub
echo "ayoub ALL=(ALL) ALL" >> /etc/sudoers

# Configurar la contraseña del usuario
passwd ayoub

#Indicamos el kernel de carga inicial
mkinitcpio -p linux

#NetworkManager instalacion
pacman -S networkmanager
systemctl enable NetwworkManager
echo "Ya casi esta hecho la instalacion"




