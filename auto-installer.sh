#!/bin/bash

# Mensaje de bienvenida
echo "Bienvenido a la instalación automática de Arch Linux UEFI"

# Solicitar la cantidad de particiones a crear
read -p "¿Cuántas particiones desea crear? " num_partitions

# Si no se ingresó un número, salir del script
if ! [[ "$num_partitions" =~ ^[0-9]+$ ]]; then
    echo "Debe ingresar un número. Saliendo del script."
    exit 1
fi

# Solicitar el tamaño de la partición swap
read -p "Ingrese el tamaño de la partición swap en MB (por defecto: 4096MB): " swap_size

# Si no se ingresó un tamaño de partición swap, usar el valor predeterminado
if [[ -z "$swap_size" ]]; then
    swap_size=4096
fi

# Formatear el disco
echo "Formateando el disco..."
(
  echo o;
  echo n;
  echo;
  echo;
  for ((i=1;i<num_partitions;i+=1)); do
    echo n;
    echo;
    echo;
  done
  echo;
  echo t;
  echo 1;
  echo 1;
  for ((i=2;i<=num_partitions;i+=1)); do
    echo t;
    echo $i;
    echo $i;
  done
  echo w;
) | fdisk /dev/sda

# Crear y activar la partición swap
echo "Creando partición swap..."
mkswap /dev/sda2
swapon /dev/sda2

# Formatear las particiones y montar el sistema de archivos
echo "Formateando las particiones..."
for ((i=1;i<=num_partitions;i+=1)); do
    mkfs.ext4 /dev/sda$i
    mkdir /mnt/part$i
    mount /dev/sda$i /mnt/part$i
done

# Instalar el sistema base y generar el archivo fstab
echo "Instalando el sistema base..."
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

# Copiar el script de postinstalación al sistema instalado
cp postinstall.sh /mnt

# Chroot al sistema instalado y ejecutar el script de postinstalación
echo "Chroot al sistema instalado y ejecutando el script de postinstalación..."
arch-chroot /mnt /bin/bash -c "/postinstall.sh"
