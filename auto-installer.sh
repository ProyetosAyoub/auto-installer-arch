#!/bin/bash

echo "¡Bienvenido al script de instalación de Arch Linux!"

# Preguntar si se desean eliminar particiones antiguas
echo "¿Desea eliminar particiones antiguas? (s/n)"
read answer
if [ "$answer" == "s" ]
then
  echo "Eliminando particiones antiguas..."
  wipefs -af /dev/sda
fi

# Preguntar por las particiones necesarias
echo "A continuación, deberá ingresar los datos para las particiones necesarias."
echo "Recuerde que el tamaño de la partición de boot será de 1G, la de swap será de 2G, y la de raíz será el resto del almacenamiento."
echo "Ingrese el nombre del disco en el que desea crear las particiones (ej. /dev/sda): "
read disk

echo "Creando partición para boot..."
echo "n
p
1

+1G
w" | fdisk $disk

echo "Creando partición para swap..."
echo "n
p
2

+2G
t
2
82
w" | fdisk $disk

echo "Creando partición para raíz..."
echo "n
p
3


w" | fdisk $disk

# Formatear particiones
mkfs.fat -F32 ${disk}1
mkswap ${disk}2
swapon ${disk}2
mkfs.ext4 ${disk}3

# Montar particiones
mount ${disk}3 /mnt
mkdir /mnt/boot
mount ${disk}1 /mnt/boot

# Instalar sistema base y network manager
pacstrap /mnt base linux linux-firmware networkmanager
genfstab -U /mnt >> /mnt/etc/fstab

# Configurar el bootloader
arch-chroot /mnt bash -c "pacman -S grub efibootmgr --noconfirm && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB && grub-mkconfig -o /boot/grub/grub.cfg"

# Preguntar si se desea reiniciar
echo "La instalación ha finalizado. ¿Desea reiniciar el sistema? (s/n)"
read answer
if [ "$answer" == "s" ]
then
  reboot
fi
