#!/bin/bash

# Advertencia al usuario
echo "Este script instalará paquetes y realizará cambios en la configuración del sistema. Continuar? (y/n)"
read answer
if [ "$answer" != "y" ]; then
    echo "Abortando instalación."
    exit 1
fi

# Definir variables para programas
WM_PACKAGES="qtile xterm code firefox rofi which nitrogen"
FONT_PACKAGES="ttf-dejavu ttf-liberation noto-fonts"
AUDIO_PACKAGES="pulseaudio pavucontrol pamixer"
UTILS_PACKAGES="arandr udiskie ntfs-3g network-manager-applet volumeicon cbtticon xorg-xinit base-devel git thunar ranger glib2 gvfs lxappearance picom geeqie vlc"

# Instalar paquetes de programas
echo "Instalando paquetes de programas..."
sudo pacman -S $WM_PACKAGES && \
sudo pacman -S $FONT_PACKAGES && \
sudo pacman -S $AUDIO_PACKAGES && \
sudo pacman -S $UTILS_PACKAGES

# Mensaje final
echo "La instalación de programas ha finalizado correctamente. Recuerda verificar la configuración y realizar cualquier otro paso manualmente si es necesario."
