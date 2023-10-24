#!/bin/bash

# Advertencia al usuario
echo "Este script instalará paquetes de programas. Continuar? (y/n)"
read answer
if [ "$answer" != "y" ]; then
    echo "Abortando instalación de programas."
    exit 1
fi

# Definir variables para paquetes de programas
WM_PACKAGES="bspwm sxhkd"
FONT_PACKAGES="ttf-dejavu ttf-liberation noto-fonts"
AUDIO_PACKAGES="alsa-utils pulseaudio pavucontrol"
POLYBAR_PACKAGE="polybar"

# Instalar paquetes de programas
echo "Instalando paquetes de programas..."
sudo pacman -S $WM_PACKAGES
sudo pacman -S $FONT_PACKAGES
sudo pacman -S $AUDIO_PACKAGES
sudo pacman -S $POLYBAR_PACKAGE
