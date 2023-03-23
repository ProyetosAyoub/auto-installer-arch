#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ser ejecutado como root" 
   exit 1
fi

# Verificar la conexión a Internet
ping -c 3 google.com

# Configurar la distribución de teclado para España
localectl set-keymap es

# Verificar la hora
timedatectl set-ntp true

# Verificar si la unidad de disco es la correcta (/dev/sda en este caso)
lsblk
read -p "Introduce el nombre de la unidad de disco en la que deseas realizar las operaciones (ejemplo: sda): " disk_name
disk="/dev/${disk_name}"

if ! [[ -b "$disk" ]]; then
  echo "El nombre de la unidad de disco introducido no es válido."
  exit
fi

# Listar las particiones existentes en la unidad de disco especificada
echo "Las siguientes particiones existen en la unidad de disco $disk_name:"
fdisk -l /dev/$disk_name

# Solicitar la confirmación del usuario para continuar
read -p "¿Deseas eliminar todas las particiones en la unidad de disco $disk_name y eliminar los formatos existentes? (y/n): " confirm
if [ "$confirm" == "y" ]; then
    # Eliminar las particiones existentes
    echo "Eliminando particiones existentes..."
    for i in $(seq 1 4); do
        parted $disk rm $i || true
    done

    # Eliminar los formatos existentes
    echo "Eliminando formatos existentes..."
    for i in $(seq 1 4); do
        wipefs -af ${disk}$i || true
    echo "¡Listo!"
    done
else
    echo "Operación cancelada por el usuario."
    exit 1
fi

# Crear partición para boot de 1GB
echo -e "n\np\n1\n\n+1G\nw" | fdisk -t ext4 $disk
mkfs.ext4 "${disk}1"
parted $disk set 1 boot on

# Crear partición para swap de 2GB
echo -e "n\np\n2\n\n+2G\nw" | fdisk -t linux-swap $disk
mkswap "${disk}2"
swapon "${disk}2"

# Crear partición para raiz de 40GB
echo -e "n\np\n3\n\n+40G\nw" | fdisk -t ext4 $disk
mkfs.ext4 "${disk}3"

# Crear partición para home con el resto del espacio disponible
echo -e "n\np\n4\n\n\nw" | fdisk -t ext4 $disk
mkfs.ext4 "${disk}4"

# Montar particiones
mount "${disk}3" /mnt
mkdir /mnt/boot /mnt/var
mount "${disk}1" /mnt/boot
mkdir /mnt/home
mount "${disk}4" /mnt/home

echo "Ya están montadas las particiones."

#Instalamos el sistema

pacman -Sy archlinux-keyring 
pacstrap /mnt base linux linux-firmware base-devel
pacstrap /mnt grub
genfstab -p /mnt >> /mnt/etc/fstab

echo "Configuración de la contraseña del root:"
passwd

echo "Configuración de la cuenta de usuario:"
read -p "Introduce el nombre de usuario que deseas crear: " username
useradd -m -g users -aG wheel -s /bin/bash $username

while true; do
  passwd $username
  if [ $? -eq 0 ]; then
    break
  else
    echo "Las contraseñas no coinciden. Inténtalo de nuevo."
  fi
done
fi
echo "$username ALL=(ALL) ALL" >> /etc/sudoers

arch-chroot /mnt /bin/bash <<EOF
pacman -S nano 
hwclock --systohc
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
# Instalar el cargador de arranque
pacman -S grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -p linux
pacman -S networkmanager 
systemctl enable NetworkManager
pacman -S sudo 
EOF

umount -R /mnt

echo "Ya esta lista la instalacion a disfrutar!"
