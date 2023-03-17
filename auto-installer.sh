#!/bin/bash

# Verificación de los requisitos del sistema
if [[ $(id -u) -ne 0 ]]; then
    echo "Este script debe ser ejecutado como root"
    exit 1
fi

# Preguntar al usuario la cantidad de almacenamiento que se debe utilizar para la partición raíz
read -p "Introduzca la cantidad de almacenamiento que desea para la partición raíz (/) (ejemplo: 30G, 1T): " ROOT_SIZE

# Crear particiones y formatearlas
parted --script ${DISK} \
    mklabel msdos \
    mkpart primary ext4 1MiB ${ROOT_SIZE} \
    mkpart primary linux-swap ${ROOT_SIZE} 100% \
    set 1 boot on

mkfs.ext4 ${DISK}1
mkswap ${DISK}2
swapon ${DISK}2

# Montar particiones
mount ${DISK}1 /mnt

# Configuración de la zona horaria
timedatectl set-ntp true
timedatectl set-timezone America/New_York

# Instalación de paquetes del sistema base y del cargador de arranque GRUB
pacstrap /mnt base linux linux-firmware
pacstrap /mnt grub

# Generar fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configuración del cargador de arranque GRUB
arch-chroot /mnt grub-install --recheck ${DISK}
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Configuración del nombre de host
echo "Arch_Ayoub" > /mnt/etc/hostname

# Configuración de la contraseña de root
echo "root:at15Passw0rd" | arch-chroot /mnt chpasswd

# Configuración de la cuenta de usuario
arch-chroot /mnt useradd -m -G wheel -s /bin/bash Ayoub
echo "Ayoub:at15Passw0rd" | arch-chroot /mnt chpasswd
echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers

# Desmontar particiones
umount -R /mnt
swapoff ${DISK}2

# Mostrar mensaje de advertencia
echo "¡Instalación completada! Recuerde retirar el disco o USB antes de encender el sistema."

# Apagar el sistema
shutdown -P now
