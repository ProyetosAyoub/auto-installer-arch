#!/bin/bash

# Variables
DEVICE="/dev/sda"
HOSTNAME="Ayoub_Arch"
USERNAME="Ayoub"
PASSWORD="at15Passw0rd"
TIMEZONE="Spain/Madrid"
LOCALE="en_ES.UTF-8"
KEYMAP="es"

# Verificar que se ejecuta como superusuario
if [ "$(whoami)" != "root" ]; then
  echo "Este script debe ser ejecutado como superusuario"
  exit 1
fi

# Actualizar el reloj del sistema
timedatectl set-ntp true

# Formatear la partición /boot
mkfs.ext4 ${DEVICE}1

# Formatear la partición raíz
mkfs.ext4 ${DEVICE}2

# Montar las particiones
mount ${DEVICE}2 /mnt
mkdir /mnt/boot
mount ${DEVICE}1 /mnt/boot

# Instalar el sistema base
pacstrap /mnt base base-devel linux linux-firmware vim grub dialog

# Generar el archivo fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configurar el sistema instalado
arch-chroot /mnt /bin/bash <<EOF

# Configurar el idioma y el teclado
echo "Configurando el idioma y el teclado..."
echo LANG=$LOCALE >> /etc/locale.conf
echo KEYMAP=$KEYMAP >> /etc/vconsole.conf
sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen
locale-gen

# Configurar la zona horaria
echo "Configurando la zona horaria..."
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Configurar el nombre del host
echo "Configurando el nombre del host..."
echo $HOSTNAME > /etc/hostname
echo "127.0.0.1	localhost" > /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "127.0.1.1	$HOSTNAME.localdomain	$HOSTNAME" >> /etc/hosts

# Establecer la contraseña de root
echo "Estableciendo la contraseña de root..."
echo "root:$PASSWORD" | chpasswd

# Crear un usuario y establecer su contraseña
echo "Creando usuario..."
useradd -m -G wheel $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Configurar GRUB
echo "Configurando GRUB..."
grub-install --target=i386-pc $DEVICE
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# Desmontar las particiones y reiniciar el sistema
umount -R /mnt
echo "La instalación ha finalizado con éxito. Reinicia el sistema."
