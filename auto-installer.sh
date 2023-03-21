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

# Instalación del sistema base
pacstrap /mnt base base-devel linux linux-firmware nano

# Configurar fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot en el sistema instalado
arch-chroot /mnt

# Configurar el idioma y la zona horaria
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime # Reemplaza "Europe/Madrid" con tu zona horaria
hwclock --systohc
nano /etc/locale.gen # Descomenta la línea que corresponde a tu idioma y país
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf # Reemplaza "es_ES.UTF-8" con tu idioma y país

# Configurar la red
echo "archlinux" > /etc/hostname # Reemplaza "archlinux" con el nombre de tu sistema
nano /etc/hosts # Agrega "127.0.0.1  localhost.localdomain  localhost  archlinux" al archivo hosts

# Instalación de GRUB
pacman -S grub
grub-install --target=i386-pc --boot-directory=/mnt/boot /dev/sda
sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT=".*"|GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Instalación del kernel
pacman -S linux

# Crear usuario y contraseña
useradd -m -G wheel -s /bin/bash username # Reemplaza "username" con el nombre de usuario que desees
passwd username # Establece la contraseña del usuario
EDITOR=nano visudo # Descomenta la línea que permite a los usuarios del grupo wheel utilizar sudo

# Salir de chroot, desmontar las particiones y reiniciar
exit
umount -R /mnt

