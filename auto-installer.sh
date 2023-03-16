#!/bin/bash

# Definir variables
root_password="at15Passw0rd"   # Establecer la contraseña de root
hostname="ayoub_qtile"        # Establecer el nombre de host
username="ayoub"            # Establecer el nombre de usuario
user_password="at15Passw0rd"   # Establecer la contraseña del usuario

# Verificar si el sistema está conectado a Internet
if ! ping -c 1 google.com &> /dev/null
then
    echo "El sistema no está conectado a Internet. Conéctese a una red y vuelva a ejecutar el script."
    exit
fi

# Establecer la contraseña de root
echo "Estableciendo la contraseña de root"
echo "root:$root_password" | chpasswd

# Actualizar la lista de paquetes y realizar actualizaciones
echo "Actualizando el sistema"
pacman -Syu --noconfirm

# Instalar paquetes requeridos
echo "Instalando paquetes"
pacman -S xorg-server xorg-xinit xorg-xsetroot xterm qtile --noconfirm

# Crear el archivo de inicio de sesión para el usuario
echo "Creando el archivo .xinitrc"
echo "exec qtile" > /home/$username/.xinitrc
chown $username:$username /home/$username/.xinitrc

# Configurar el gestor de arranque GRUB
echo "Instalando GRUB en el disco"
pacman -S grub --noconfirm
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Configurar la red
echo "Configurando la red"
pacman -S networkmanager --noconfirm
systemctl enable NetworkManager.service

# Configurar la zona horaria
echo "Configurando la zona horaria"
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc --utc

# Configurar el nombre de host y el archivo de hosts
echo "Configurando el nombre de host y el archivo de hosts"
echo "$hostname" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts

# Crear un usuario
echo "Creando un usuario"
useradd -m $username
echo "$username:$user_password" | chpasswd

# Finalizar la instalación
echo "La instalación ha finalizado. Reiniciando el sistema."
shutdown
