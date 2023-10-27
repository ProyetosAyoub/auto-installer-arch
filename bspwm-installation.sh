#!/bin/bash

# Advertencia al usuario
echo "Este script instalará paquetes necesarios para BSPWM y Dmenu. Continuar? (y/n)"
read answer
if [ "$answer" != "y" ]; then
    echo "Abortando instalación."
    exit 1
fi

# Definir variables para los paquetes necesarios
WM_PACKAGES="bspwm sxhkd"
UTILS_PACKAGES="xorg dmenu"

# Instalar paquetes necesarios
echo "Instalando paquetes necesarios..."
sudo pacman -S $WM_PACKAGES
sudo pacman -S $UTILS_PACKAGES

# Configurar BSPWM (reemplaza con tus propias configuraciones)
echo "Configurando BSPWM..."
mkdir -p ~/.config/bspwm
mkdir -p ~/.config/sxhkd
cp /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/
cp /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/

# Abrir el archivo sxhkdrc en un editor de texto (puedes cambiar "nano" por tu editor preferido)
echo "Abriendo sxhkdrc en un editor de texto..."
nano ~/.config/sxhkd/sxhkdrc  # Puedes cambiar "nano" a tu editor preferido.
