#!/bin/bash

# Advertencia al usuario
echo "Este script instalará paquetes de programas. Continuar? (y/n)"
read answer
if [ "$answer" != "y" ]; then
    echo "Abortando instalación de programas."
    exit 1
fi

# Definir variables para programas
UTILS_PACKAGES="xorg xorg-xinit xterm dmenu feh pcmanfm code alacritty"

# Instalar paquetes de programas
echo "Instalando paquetes de programas..."
sudo pacman -S $UTILS_PACKAGES
