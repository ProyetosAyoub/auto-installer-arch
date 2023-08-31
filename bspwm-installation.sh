#!/bin/bash

# Advertencia al usuario
echo "Este script instalará paquetes y realizará cambios en la configuración del sistema. Continuar? (y/n)"
read answer
if [ "$answer" != "y" ]; then
    echo "Abortando instalación."
    exit 1
fi

# Definir variables para programas y paquetes
WM_PACKAGES="bspwm sxhkd"
FONT_PACKAGES="ttf-dejavu ttf-liberation noto-fonts"
AUDIO_PACKAGES="alsa-utils pulseaudio pavucontrol"
UTILS_PACKAGES="xorg xorg-xinit xterm dmenu feh pcmanfm code alacritty"
POLYBAR_PACKAGE="polybar"

# Instalar paquetes de programas
echo "Instalando paquetes de programas..."
sudo pacman -S $WM_PACKAGES && \
sudo pacman -S $FONT_PACKAGES && \
sudo pacman -S $AUDIO_PACKAGES && \
sudo pacman -S $UTILS_PACKAGES && \
sudo pacman -S $POLYBAR_PACKAGE

# Configurar BSPWM (reemplaza con tus propias configuraciones)
echo "Configurando BSPWM..."
mkdir -p ~/.config/bspwm
mkdir -p ~/.config/sxhkd
cp /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/
cp /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/

# Mensaje final
echo "La instalación de BSPWM y las aplicaciones adicionales ha finalizado correctamente. Recuerda verificar la configuración y realizar cualquier otro paso manualmente si es necesario."
