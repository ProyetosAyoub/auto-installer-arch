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
# Verificar si se ha proporcionado el nombre de la unidad de disco
if [ -z '$1' ]; then
  echo "Debes especificar el nombre de la unidad de disco (ejemplo: sda)."
  exit 1
fi

disk="/dev/$1"

# Verificar si la unidad de disco es válida
if ! [[ -b "$disk" ]]; then
  echo "El nombre de la unidad de disco introducido no es válido."
  exit 1
fi

# Preguntar al usuario si desea eliminar las particiones existentes
read -p "¿Deseas eliminar todas las particiones en la unidad de disco $1 y eliminar los formatos existentes? (y/n): " confirm
if [ "$confirm" == "y" ]; then
  # Detener cualquier proceso que esté usando las particiones
  umount -R /dev/$1* 2> /dev/null
  swapoff -a

  # Eliminar las particiones existentes
  echo "Eliminando particiones existentes..."
  parted -s $disk mklabel msdos
  echo "¡Listo!"
else
  echo "Operación cancelada por el usuario."
  exit 1
fi

# Preguntar al usuario el tamaño de las particiones
read -p "Introduce el tamaño de la partición para /boot en MB (ejemplo: 1024): " boot_size
read -p "Introduce el tamaño de la partición para swap en MB (ejemplo: 2048): " swap_size
read -p "Introduce el tamaño de la partición para / en MB (ejemplo: 40960): " root_size

# Crear partición para /boot
echo -e "n\np\n1\n\n+${boot_size}M\nw" | fdisk $disk
mkfs.ext4 "${disk}1"
parted $disk set 1 boot on

# Crear partición para swap
echo -e "n\np\n2\n\n+${swap_size}M\nw" | fdisk $disk
mkswap "${disk}2"
swapon "${disk}2"

# Crear partición para /
echo -e "n\np\n3\n\n+${root_size}M\nw" | fdisk $disk
mkfs.ext4 "${disk}3"

# Crear partición para /home con el resto del espacio disponible
echo -e "n\np\n4\n\n\nw" | fdisk $disk
mkfs.ext4 "${disk}4"

# Montar particiones
mount "${disk}3" /mnt
mkdir /mnt/boot /mnt/var
mount "${disk}1" /mnt/boot
mkdir /mnt/home
mount "${disk}4" /mnt/home

echo "Ya están montadas las particiones."
echo "Actualizando los repositorios y el keyring de Arch Linux"
pacman -Sy archlinux-keyring

echo "Instalando el sistema base de Arch Linux"
pacstrap /mnt base linux linux-firmware

echo "Instalando paquetes adicionales para el sistema base"
pacstrap /mnt base-devel nano grub dhcpcd networkmanager sudo

echo "Generando el archivo fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Entrando en el entorno chroot"
arch-chroot /mnt /bin/bash -c '
echo "Configurando el idioma";
read -p "Introduce el código del idioma (por ejemplo, es): " language_code;
echo "KEYMAP=$language_code" > /etc/vconsole.conf;
echo "$language_code.UTF-8 UTF-8" >> /etc/locale.gen;
locale-gen;
echo "LANG=$language_code.UTF-8" > /etc/locale.conf;
echo "Configurando la zona horaria";
read -p "Introduce la zona horaria (por ejemplo, Europe/Madrid): " timezone;
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime;
echo "Configurando el nombre del equipo";
read -p "Introduce el nombre del equipo: " hostname;
echo "$hostname" > /etc/hostname;
echo "Configurando el archivo hosts";
read -p "Introduce la dirección IP (por ejemplo, 127.0.0.1): " ip_address;
echo "$ip_address    localhost" >> /etc/hosts;
echo "::1    localhost" >> /etc/hosts;
echo "$ip_address    $hostname.localdomain    $hostname" >> /etc/hosts;
echo "Configurando el gestor de red";
systemctl enable NetworkManager.service;
echo "Configurando el gestor de arranque GRUB";
read -p "Introduce el dispositivo donde instalar GRUB (por ejemplo, /dev/sda): " device;
grub-install --target=i386-pc $device;
grub-mkconfig -o /boot/grub/grub.cfg;
mkinitcpio -P linux;
echo "Creando un usuario nuevo";
read -p "Introduce el nombre de usuario que deseas crear: " username;
useradd -m -G wheel -s /bin/bash $username;
while true; do
    read -s -p "Introduce la contraseña para $username: " password;
    echo
    read -s -p "Vuelve a introducir la contraseña: " password2
    echo
    if [ "$password" = "$password2" ]; then
        echo "$username:$password" | chpasswd
        break
    else
        echo "Las contraseñas no coinciden. Inténtalo de nuevo.";
    fi
done
echo "$username ALL=(ALL) ALL" >> /etc/sudoers
'

echo "Saliendo del entorno chroot"

umount -R /mnt

echo "¡La instalación se ha completado con éxito! Reinicia tu sistema y disfruta de tu nuevo sistema Arch Linux."

