#!/bin/bash

# Configuración de variables de entorno
HOSTNAME="my-arch-system"   # nombre de host para el sistema
ROOT_PASSWORD="myrootpwd"   # contraseña para la cuenta root
USERNAME="myuser"           # nombre de usuario para la cuenta de usuario
USER_PASSWORD="mypwd"       # contraseña para la cuenta de usuario
TIMEZONE="America/New_York" # zona horaria para el sistema
LOCALE="en_US.UTF-8"        # configuración regional del sistema
DISK="/dev/sda"             # dispositivo de almacenamiento donde se instalará Arch

# Verificación de los requisitos del sistema
if [[ $(id -u) -ne 0 ]]; then
    echo "Este script debe ser ejecutado como root"
    exit 1
fi

if [[ ! -d /sys/firmware/efi/efivars ]]; then
    echo "Este script solo se puede ejecutar en sistemas BIOS"
    exit 1
fi

# Crear particiones y formatearlas
parted --script ${DISK} \
    mklabel msdos \
    mkpart primary ext4 1MiB 50% \
    mkpart primary ext4 50% 100% \
    set 1 boot on

mkfs.ext4 ${DISK}1
mkfs.ext4 ${DISK}2

# Montar particiones
mount ${DISK}1 /mnt
mkdir /mnt/home
mount ${DISK}2 /mnt/home

# Configuración de la zona horaria
ln -sf /usr/share/zoneinfo/${TIMEZONE} /mnt/etc/localtime
hwclock --systohc --utc --noadjfile

# Configuración regional
echo "${LOCALE} UTF-8" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=${LOCALE}" > /mnt/etc/locale.conf

# Configuración del nombre de host
echo "${HOSTNAME}" > /mnt/etc/hostname

# Configuración de la contraseña de root
echo "root:${ROOT_PASSWORD}" | arch-chroot /mnt chpasswd

# Instalación del sistema base y del cargador de arranque GRUB
pacstrap /mnt base
pacstrap /mnt grub
arch-chroot /mnt grub-install --recheck ${DISK}
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Configuración de la cuenta de usuario
arch-chroot /mnt useradd -m -G wheel -s /bin/bash ${USERNAME}
echo "${USERNAME}:${USER_PASSWORD}" | arch-chroot /mnt chpasswd
echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers

# Desmontar particiones
umount -R /mnt

# Mostrar mensaje de advertencia
echo "¡Instalación completada! Recuerde retirar el disco o USB antes de encender el sistema."

# Apagar el sistema
shutdown -P now
