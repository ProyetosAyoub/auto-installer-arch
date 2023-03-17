#!/bin/bash

# Pedir el disco
echo "Ingrese el disco a utilizar (ej: /dev/sda):"
read disk

# Crear particiones
while true; do
  echo "Ingrese el tamaño para la partición raíz (ej: 20G) (deje en blanco para continuar):"
  read root_size
  if [[ -z "$root_size" ]]; then
    echo "No se ha especificado el tamaño para la partición raíz."
    exit 1
  else
    break
  fi
done

while true; do
  echo "Ingrese el tamaño para la partición swap (ej: 2G) (deje en blanco para continuar):"
  read swap_size
  if [[ -z "$swap_size" ]]; then
    echo "No se ha especificado el tamaño para la partición swap."
    exit 1
  else
    break
  fi
done

fdisk ${disk} << EOF
o
n
p
1

+512M
t
1
b
n
p
2

+${root_size}
n
p
3

+${swap_size}
t
3
82
w
EOF

# Formatear particiones
mkfs.ext2 ${disk}1
mkfs.ext4 ${disk}3
mkswap ${disk}2

# Montar particiones
mount ${disk}3 /mnt
mkdir /mnt/boot
mount ${disk}1 /mnt/boot
swapon ${disk}2

# Instalar Arch Linux
pacstrap /mnt base base-devel linux linux-firmware

# Generar fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Crear el directorio para el root
mkdir /mnt/root

# Configuración del sistema
# ...

# Instalar y configurar el bootloader
pacman -S grub

grub-install --target=i386-pc --recheck ${disk}

sed -i 's/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /mnt/etc/default/grub
grub-mkconfig -o /mnt/boot/grub/grub.cfg

# Salir de chroot y desmontar particiones
umount -R /mnt
swapoff -a

echo "La instalación de Arch Linux se ha completado. Puede reiniciar el sistema y retirar el medio de instalación."
