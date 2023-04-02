#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ser ejecutado como root" 
   exit 1
fi

# Verificar la conexión a Internet
if ! ping -c 3 google.com; then
    echo "No se pudo establecer conexión a Internet."
    exit 1
fi

# Configurar la distribución de teclado para España
localectl set-keymap es

# Verificar la hora
timedatectl set-ntp true

# Verificar si la unidad de disco es la correcta (/dev/sda en este caso)
read -p "Introduce el nombre de la unidad de disco en la que deseas realizar las operaciones (ejemplo: sda): " disk_name
disk="/dev/${disk_name}"

if ! [[ -b "$disk" ]]; then
  echo "El nombre de la unidad de disco introducido no es válido."
  exit 1
fi

# Listar las particiones existentes en la unidad de disco especificada
echo "Las siguientes particiones existen en la unidad de disco $disk_name:"
fdisk -l $disk || true # Ignorar errores

# Solicitar la confirmación del usuario para continuar
read -p "¿Deseas eliminar todas las particiones en la unidad de disco $disk_name y eliminar los formatos existentes? (y/n): " confirm
if [ "$confirm" == "y" ]; then
    # Eliminar las particiones existentes
    echo "Eliminando particiones existentes..."
    for i in $(seq 1 4); do
        parted -s $disk rm $i || true
    done

    # Eliminar los formatos existentes
    echo "Eliminando formatos existentes..."
    for i in $(seq 1 4); do
        wipefs -af ${disk}$i || true
    done
    echo "¡Listo!"
else
    echo "Operación cancelada por el usuario."
    exit 1
fi

# Crear partición para boot de 1GB
echo -e "n\np\n1\n\n+1G\nt\n1\n82\nw" | fdisk $disk || true # Ignorar errores
mkfs.ext4 "${disk}1"
parted $disk set 1 boot on

# Crear partición para swap de 2GB
echo -e "n\np\n2\n\n+2G\n82\nw" | fdisk $disk || true # Ignorar errores
mkswap "${disk}2"
swapon "${disk}2"

# Crear partición para raiz de 40GB
echo -e "n\np\n3\n\n+40G\nw" | fdisk $disk || true # Ignorar errores
mkfs.ext4 "${disk}3"

# Crear partición para home con el resto del espacio disponible
echo -e "n\np\n4\n\n\nw" | fdisk $disk || true # Ignorar errores
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
read -p "Introduce el código del idioma (por ejemplo, es_ES): " language_code;
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

