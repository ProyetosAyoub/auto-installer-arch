#!/bin/bash

# Establecer la contraseña del usuario root
echo "Estableciendo la contraseña de root"
passwd <<EOF
myrootpassword
myrootpassword
EOF

# Actualizar la lista de paquetes y realizar actualizaciones
echo "Actualizando el sistema"
pacman -Syu --noconfirm

# Instalar paquetes requeridos
echo "Instalando paquetes"
pacman -S xorg-server xorg-xinit xorg-xsetroot xterm qtile --noconfirm

# Crear el archivo de inicio de sesión para el usuario
echo "Creando el archivo .xinitrc"
echo "exec qtile" > ~/.xinitrc

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
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
hwclock --systohc --utc

# Configurar el nombre de host y el archivo de hosts
echo "Configurando el nombre de host y el archivo de hosts"
echo "myhostname" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 myhostname.localdomain myhostname" >> /etc/hosts

# Crear un usuario
echo "Creando un usuario"
useradd -m myuser
passwd myuser

# Finalizar la instalación
echo "La instalación ha finalizado. Reiniciando el sistema."
reboot
