#!/bin/bash

# Verificar la conexión a Internet
ping -c 3 google.com

# Configurar la distribución de teclado para España
loadkeys es

# Verificar la hora
timedatectl set-ntp true

# Verificar si la unidad de disco es la correcta (/dev/sda en este caso)
lsblk

# Solicitar la unidad de disco en la que se realizarán las operaciones
read -p "Introduce la unidad de disco en la que deseas realizar las operaciones (ejemplo: /dev/sda): " drive

# Listar las particiones existentes en la unidad de disco especificada
echo "Las siguientes particiones existen en la unidad de disco $drive:"
fdisk -l $drive

# Solicitar la confirmación del usuario para continuar
read -p "¿Deseas eliminar todas las particiones en la unidad de disco $drive y eliminar los formatos existentes? (y/n): " confirm
if [ "$confirm" == "y" ]; then
    # Eliminar las particiones existentes
    echo "Eliminando particiones existentes..."
    parted $drive rm 1 || true
    parted $drive rm 2 || true
    parted $drive rm 3 || true
    parted $drive rm 4 || true

    # Eliminar los formatos existentes
    echo "Eliminando formatos existentes..."
    mkfs.ext4 -F $drive1 || true
    mkswap -f $drive2 || true
    mkfs.ext4 -F $drive3 || true
    mkfs.ext4 -F $drive4 || true
    echo "¡Listo!"
else
    echo "Operación cancelada por el usuario."
fi

# Crear partición para boot de 1GB
echo -e "n\np\n1\n\n+1G\nw" | fdisk /dev/sda
mkfs.ext2 /dev/sda1
parted /dev/sda set 1 boot on

# Crear partición para swap de 2GB
echo -e "n\np\n2\n\n+2G\nw" | fdisk /dev/sda
mkswap /dev/sda2
swapon /dev/sda2

# Crear partición para raiz de 40GB
echo -e "n\np\n3\n\n+40G\nw" | fdisk /dev/sda
mkfs.ext4 /dev/sda3

# Crear partición para home con el resto del espacio disponible
echo -e "n\np\n4\n\n\nw" | fdisk /dev/sda
mkfs.ext4 /dev/sda4

# Montar particiones
mount /dev/sda3 /mnt
mkdir /mnt/boot /mnt/var
mount /dev/sda1 /mnt/boot
mkdir /mnt/home
mount /dev/sda4 /mnt/home

echo "Ya estan montaldas las particiones"

#Instalamos el sistema

pacman -Sy archlinux-keyring
pacstrap /mnt base linux linux-firmware  base-devel
pacstrap /mnt grub-bios
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt
#Accederemos a la ruta montada

echo "Ya estas dentro y no hubo ningun problema de momento...."


hwclock -w
# Configurar el idioma
echo KEYMAP=es > /etc/vconsole.conf
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" >> /etc/locale.conf

# Configurar la zona horaria
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime

# Configurar el nombre del equipo
echo "arch-ayoub" >> /etc/hostname

# Configurar el archivo hosts
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 archayoub.localdomain archayoub" >> /etc/hosts

pacman -S dhcpcd

systemctl enable dhcpcd.service

# Configurar la contraseña del root
passwd

# Crear un usuario y otorgarle permisos de sudo
useradd -m -g users -G wheel -s /bin/bash ayoub

# Configurar la contraseña del usuario
passwd ayoub

echo "ayoub ALL=(ALL) ALL" >> /etc/sudoers

# Instalar el cargador de arranque
grub-install /dev/sda
grub-install --target=i386-pc --boot-directory=/mnt/boot /dev/sda
sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT=".*"|GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

nkinitcpio -p linux

pacman -S networkmanager

systemctl enable NetworkManager

umount /mnt/boot
umount -R /mnt

echo "Ya esta lista la instalacion a disfrutar!"
