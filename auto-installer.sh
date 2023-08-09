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

# Salir automáticamente si ocurre un error
set -e

# Función para validar la entrada del usuario
function validar_respuesta {
    read -p "¿Deseas eliminar todas las particiones en la unidad de disco $disk_name y eliminar los formatos existentes? (y/n): " respuesta
    while [[ ! "$respuesta" =~ ^[yn]$ ]]; do
        read -p "Por favor, ingresa 'y' para confirmar o 'n' para cancelar: " respuesta
    done
    echo "$respuesta"
}

# Comprobación de existencia de comandos
command -v parted >/dev/null 2>&1 || { echo >&2 "El comando 'parted' no está instalado. Abortando."; exit 1; }
command -v fdisk >/dev/null 2>&1 || { echo >&2 "El comando 'fdisk' no está instalado. Abortando."; exit 1; }
command -v mkfs.ext4 >/dev/null 2>&1 || { echo >&2 "El comando 'mkfs.ext4' no está instalado. Abortando."; exit 1; }

# Solicitar al usuario que ingrese el nombre del disco
read -p "Por favor, ingresa el nombre de la unidad de disco en la que deseas realizar las operaciones (ejemplo: sda): " disk_name
disk="/dev/${disk_name}"

# Verificar si el disco existe y es una unidad de disco válida
if [ ! -b "$disk" ]; then
    echo "El nombre de la unidad de disco introducido no es válido o no existe."
    exit 1
fi

# Listar las particiones existentes en la unidad de disco especificada
echo "Las siguientes particiones existen en la unidad de disco $disk_name:"
fdisk -l $disk || true # Ignorar errores

# Solicitar la confirmación del usuario para continuar
confirm=$(validar_respuesta)

if [ "$confirm" == "y" ]; then
    # Eliminar las particiones existentes con parted
    echo "Eliminando particiones existentes..."
    parted -s $disk mklabel gpt # Crear una nueva tabla de particiones GPT

    echo "¡Listo!"
else
    echo "Operación cancelada por el usuario."
    exit 1
fi

# Crear partición para boot de 1GB
echo -e "n\np\n1\n\n+1G\nt\n1\n82\nw" | fdisk $disk # Intentar crear partición y formatearla como swap
mkfs.ext4 -F "${disk}1" # -F para forzar el formateo sin preguntar

# Crear partición para swap de 2GB
echo -e "n\np\n2\n\n+2G\n82\nw" | fdisk $disk # Intentar crear partición y formatearla como swap
mkswap "${disk}2"
swapon "${disk}2"

# Crear partición para raíz de 40GB
echo -e "n\np\n3\n\n+40G\nw" | fdisk $disk # Intentar crear partición y formatearla como ext4
mkfs.ext4 -F "${disk}3" # -F para forzar el formateo sin preguntar

# Crear partición para home con el resto del espacio disponible
echo -e "n\np\n4\n\n\nw" | fdisk $disk # Intentar crear partición y formatearla como ext4
mkfs.ext4 -F "${disk}4" # -F para forzar el formateo sin preguntar

# Buscar los UUIDs de las particiones después de crearlas y formatearlas
uuid_boot=$(lsblk -no UUID ${disk}1)
uuid_swap=$(lsblk -no UUID ${disk}2)
uuid_root=$(lsblk -no UUID ${disk}3)
uuid_home=$(lsblk -no UUID ${disk}4)

# Montar particiones
mount "${disk}3" /mnt
mkdir /mnt/boot /mnt/var
mount "${disk}1" /mnt/boot
mkdir /mnt/home
mount "${disk}4" /mnt/home

echo "Las particiones han sido creadas y montadas correctamente."

echo "Ya están montadas las particiones."

echo "Actualizando los repositorios y el keyring de Arch Linux"
pacman -Sy archlinux-keyring

echo "Instalando el sistema base de Arch Linux"
pacstrap /mnt base linux linux-firmware

echo "Instalando paquetes adicionales para el sistema base"
packages=("base-devel" "nano" "grub" "dhcpcd" "networkmanager" "sudo" "grub-bios")
while true; do
    echo "Paquetes disponibles para instalar:"
    for ((i=0; i<${#packages[@]}; i++)); do
        echo "$i. ${packages[$i]}"
    done

    read -p "Seleccione un paquete para instalar (o 'q' para salir): " choice
    if [ "$choice" = "q" ]; then
        break
    elif [ "$choice" -ge 0 ] && [ "$choice" -lt ${#packages[@]} ]; then
        pacstrap /mnt "${packages[$choice]}"
        echo "Paquete ${packages[$choice]} instalado correctamente."
    else
        echo "Selección inválida. Inténtelo de nuevo."
    fi
done

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
grub-install $device;
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

