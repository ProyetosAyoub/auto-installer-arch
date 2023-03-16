#Instalacion completo de arch mediante script.

#!/bin/bash

# Verificar si el script se está ejecutando como root
if [[ $(id -u) -ne 0 ]]; then
   echo "Este script debe ser ejecutado como root"
   exit 1
fi

# Configurar el idioma y el teclado
echo "Configurando el idioma y el teclado..."
echo "es_ES.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=es_AR.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf
echo ""

# Configurar la zona horaria
echo "Configurando la zona horaria..."
ln -sf /usr/share/zoneinfo/Europe/Spain/Madrid /etc/localtime
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


# Fin de la instalación
echo "La instalación ha finalizado. Por favor, reinicie el equipo."
