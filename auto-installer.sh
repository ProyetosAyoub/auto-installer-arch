#!/bin/bash

# Preguntamos al usuario si desea eliminar particiones existentes
read -p "¿Desea eliminar particiones existentes? (s/n): " eliminar

if [ "$eliminar" == "s" ]; then
    # Eliminamos particiones existentes
    umount -R /mnt
    wipefs -a /dev/sda
fi

# Pedimos al usuario que introduzca el tamaño en GB para la partición de /boot
read -p "Introduce el tamaño en GB para la partición /boot: " tamaño_boot

# Pedimos al usuario que introduzca el tamaño en GB para la partición de swap
read -p "Introduce el tamaño en GB para la partición swap: " tamaño_swap

# Pedimos al usuario que introduzca el tamaño en GB para la partición de root
read -p "Introduce el tamaño en GB para la partición root: " tamaño_root

# Creamos partición para /boot
parted --script /dev/sda \
    mklabel gpt \
    mkpart primary ext4 1MiB ${tamano_boot}GiB \
    set 1 boot on

# Creamos partición para swap
parted --script /dev/sda \
    mkpart primary linux-swap ${tamano_boot}GiB ${tamano_swap}GiB

# Creamos partición para root
parted --script /dev/sda \
    mkpart primary ext4 ${tamano_swap}GiB ${tamano_swap + tamano_root}GiB

# Formateamos las particiones
mkfs.ext4 /dev/sda1
mkswap /dev/sda2
mkfs.ext4 /dev/sda3

# Activamos swap
swapon /dev/sda2

# Montamos la partición de root
mount /dev/sda3 /mnt

# Instalamos el sistema base
pacstrap /mnt base linux linux-firmware

# Generamos el archivo fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copiamos el script de post-instalación al sistema que acabamos de instalar
cp post_installation_script.sh /mnt

# Chroot al sistema que acabamos de instalar
arch-chroot /mnt /bin/bash << EOF
# Instalamos y configuramos el bootloader GRUB
pacman -S grub efibootmgr dosfstools os-prober mtools
mkdir /boot/efi
mount /dev/sda1 /boot/efi
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Descargamos y habilitamos el network manager
pacman -S networkmanager
systemctl enable NetworkManager
EOF

# Eliminamos el script de post-instalación
rm /mnt/post_installation_script.sh

# Preguntamos al usuario si desea reiniciar el sistema
read -p "¿Desea reiniciar el sistema? (s/n): " reiniciar

if [ "$reiniciar" == "s" ]; then
    reboot
fi
