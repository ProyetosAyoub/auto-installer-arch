#!/bin/bash

# Eliminar particiones existentes
lsblk
read -p "¿Desea eliminar las particiones existentes? [s/n]: " DELETE_PARTITIONS

if [ $DELETE_PARTITIONS = "s" ]; then
  read -p "Escriba el nombre de la particion del disco (ej. /dev/sda): " DISK
  umount $DISK*
  wipefs -a $DISK
  parted -s $DISK mklabel gpt
fi

# Crear particiones
parted $DISK mkpart primary ext4 1MiB 512MiB
parted $DISK set 1 boot on
parted $DISK mkpart primary ext4 512MiB 100%

# Formatear particiones
mkfs.ext4 ${DISK}1
mkfs.ext4 ${DISK}2

# Montar particiones
mount ${DISK}2 /mnt
mkdir /mnt/boot
mount ${DISK}1 /mnt/boot

# Instalar el sistema base
pacstrap /mnt base linux linux-firmware base-devel

# Generar fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot en el sistema instalado
arch-chroot /mnt /bin/bash <<EOF

# Configurar la zona horaria
ln -sf /usr/share/zoneinfo/America/Bogota /etc/localtime
hwclock --systohc

# Configurar el idioma
echo "es_es.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=es_es.UTF-8" > /etc/locale.conf

# Configurar la red
echo "archlinux" > /etc/hostname
echo "127.0.0.1	localhost" >> /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "127.0.1.1	archlinux.localdomain	archlinux" >> /etc/hosts

# Configurar el gestor de arranque
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck
grub-mkconfig -o /boot/grub/grub.cfg

#!/bin/bash

read -p "¿Desea reiniciar el sistema? [s/n]: " RESTART

if [ $RESTART = "s" ]; then
  reboot
fi
