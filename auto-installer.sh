#!/bin/bash

# Verificar si el script se está ejecutando como root
if [[ $(id -u) -ne 0 ]]; then
   echo "Este script debe ser ejecutado como root"
   exit 1
fi

# Actualizar el sistema
echo "Actualizando el sistema..."
pacman -Syu --noconfirm
echo ""

# Instalar los paquetes necesarios para qtile
echo "Instalando los paquetes necesarios para qtile..."
pacman -S xorg xorg-xinit qtile dmenu picom --noconfirm
echo ""

# Crear el archivo de inicio de sesión de X11
echo "Creando el archivo de inicio de sesión de X11..."
echo "exec qtile" > ~/.xinitrc
echo ""

# Configurar el gestor de inicio
echo "Configurando el gestor de inicio..."
echo "[Seat:*]
autologin-guest=false
autologin-user=
autologin-user-timeout=0
autologin-session=lightdm-xsession
" > /etc/lightdm/lightdm.conf
echo ""

# Iniciar el gestor de inicio
echo "Iniciando el gestor de inicio..."
systemctl enable lightdm
systemctl start lightdm
echo ""

# Fin de la instalación
echo "La instalación ha finalizado. Ahora puedes iniciar qtile con el comando startx."
