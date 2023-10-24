#!/bin/bash

# Advertencia al usuario
echo "Este script instalará BSPWM, SXHKD, y realizará cambios en la configuración del sistema. Continuar? (y/n)"
read answer
if [ "$answer" != "y" ]; then
    echo "Abortando instalación y configuración de BSPWM y SXHKD."
    exit 1
fi

# Instalar BSPWM y SXHKD
echo "Instalando BSPWM y SXHKD..."
sudo pacman -S bspwm sxhkd

# Configurar BSPWM
echo "Configurando BSPWM..."
mkdir -p ~/.config/bspwm
mkdir -p ~/.config/sxhkd
cp /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/
cp /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/

# Abrir el archivo sxhkdrc en un editor de texto (puedes cambiar "nano" por tu editor preferido)
echo "Abriendo sxhkdrc en un editor de texto..."
nano ~/.config/sxhkd/sxhkdrc  # Puedes cambiar "nano" a tu editor preferido.
