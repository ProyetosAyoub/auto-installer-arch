#!/bin/bash

# Verificar si el script se está ejecutando como root
if [[ $(id -u) -ne 0 ]]; then
   echo "Este script debe ser ejecutado como root"
   exit 1
fi

# Crear particiones.

# Variables
DEVICE="/dev/sda"
BOOT_SIZE="+512M"
SWAP_SIZE="+2G"
ROOT_SIZE=""

# Verificar que el dispositivo de destino es correcto
read -p "Este script creará particiones en ${DEVICE}. ¿Estás seguro? (y/n): " DEVICE_CONFIRM
if [ "$DEVICE_CONFIRM" != "y" ]; then
  echo "Operación cancelada"
  exit 1
fi

# Crear partición /boot
echo "Creando partición /boot..."
echo "n
p
1

${BOOT_SIZE}
w
" | fdisk $DEVICE

# Formatear partición /boot
echo "Formateando partición /boot..."
mkfs.ext4 ${DEVICE}1
mkdir /mnt/boot
mount ${DEVICE}1 /mnt/boot

# Crear partición swap
echo "Creando partición swap..."
echo "n
p
2

${SWAP_SIZE}
t
2
w
" | fdisk $DEVICE

# Formatear partición swap
echo "Formateando partición swap..."
mkswap ${DEVICE}2
swapon ${DEVICE}2

# Crear partición /
echo "Creando partición /..."
echo "n
p
3

w
" | fdisk $DEVICE

# Formatear partición /
echo "Formateando partición /..."
mkfs.ext4 ${DEVICE}3
mount ${DEVICE}3 /mnt

echo "Particiones creadas y montadas con éxito"

# Configurar el idioma y el teclado
echo "Configurando el idioma y el teclado..."
echo "es_ES.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf
echo ""

# Configurar la zona horaria
echo "Configurando la zona horaria..."
ln -sf /usr/share/zoneinfo/America/Argentina/Buenos_Aires /etc/localtime
hwclock --systohc
echo ""

# Configurar la red
echo "Configurando la red..."
read -p "Ingrese el nombre del equipo: " hostname
echo "$hostname" > /etc/hostname
echo "127.0.0.1	localhost" > /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "127.0.1.1	$hostname.localdomain	$hostname" >> /etc/hosts
systemctl enable dhcpcd.service
echo ""

# Configurar el gestor de arranque
echo "Configurando el gestor de arranque..."
pacman -S grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
echo ""

# Configurar la contraseña del usuario root
echo "Configurando la contraseña del usuario root..."
passwd
echo ""

# Crear un usuario
echo "Creando un usuario..."
read -p "Ingrese el nombre de usuario: " username
useradd -m $username
passwd $username
usermod -aG wheel,audio,video,optical,storage $username
echo ""

# Instalar los paquetes básicos
echo "Instalando los paquetes básicos..."
pacman -S xorg-server xorg-xinit xfce4 xfce4-goodies lightdm lightdm-gtk-greeter firefox
echo ""

# Activar el gestor de inicio
echo "Activando el gestor de inicio..."
systemctl enable lightdm.service
systemctl start lightdm.service
echo ""

# Fin de la instalación
echo "La instalación ha finalizado. Por favor, reinicie el equipo."
