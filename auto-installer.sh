#!/bin/bash

# Mostrar mensaje de bienvenida
echo "Bienvenido al script de instalación de Arch Linux"

# Preguntar al usuario si desea eliminar las particiones previas
echo "¿Desea eliminar las particiones previas? (s/n)"
read eliminar_particiones_previas

if [[ $eliminar_particiones_previas == "s" ]]; then
  # Eliminar las particiones previas
  echo "Eliminando las particiones previas"
  umount -R /mnt
  wipefs -a /dev/sda
  echo "Particiones previas eliminadas"
fi

# Mostrar las particiones actuales
echo "Particiones actuales:"
lsblk

# Preguntar por la partición root
echo "Ingrese la partición para el sistema raíz (/):"
read particion_root

# Validar la partición root
while ! [[ -e $particion_root ]]; do
  echo "La partición ingresada no existe. Ingrese una partición válida:"
  read particion_root
done

# Preguntar por la partición de intercambio (swap)
echo "Ingrese la partición para la memoria de intercambio (swap):"
read particion_swap

# Validar la partición de intercambio (swap)
while ! [[ -e $particion_swap ]]; do
  echo "La partición ingresada no existe. Ingrese una partición válida:"
  read particion_swap
done

# Formatear las particiones
echo "Formateando particiones"
mkfs.ext4 $particion_root
mkswap $particion_swap
swapon $particion_swap
echo "Particiones formateadas"

# Montar la partición root
echo "Montando partición root"
mount $particion_root /mnt
echo "Partición root montada"

# Instalar el sistema base
echo "Instalando sistema base"
pacstrap /mnt base base-devel
echo "Sistema base instalado"

# Generar el archivo fstab
echo "Generando archivo fstab"
genfstab -U /mnt >> /mnt/etc/fstab
echo "Archivo fstab generado"

# Copiar el script post-instalación
echo "Copiando el script post-instalación"
cp postinstall.sh /mnt
echo "Script post-instalación copiado"

# Cambiar al sistema instalado
echo "Cambie al nuevo sistema usando 'arch-chroot /mnt' y ejecute el script post-instalación después de eso."
echo "¿Desea reiniciar el sistema ahora? (s/n)"
read reiniciar

if [[ $reiniciar == "s" ]]; then
  reboot
fi
