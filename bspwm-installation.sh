#!/bin/bash

# Advertencia al usuario
echo "Este script realizará cambios en la configuración del sistema. Continuar? (y/n)"
read answer
if [ "$answer" != "y" ]; then
    echo "Abortando instalación."
    exit 1
fi

# Definir variables para programas
UTILS_PACKAGES="xorg xorg-xinit xterm dmenu feh pcmanfm code alacritty"

# Instalar paquetes de programas
echo "Instalando paquetes de programas..."
sudo pacman -S $UTILS_PACKAGES

# Configurar BSPWM (reemplaza con tus propias configuraciones)
echo "Configurando BSPWM..."
mkdir -p ~/.config/bspwm
mkdir -p ~/.config/sxhkd
cp /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/
cp /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/
