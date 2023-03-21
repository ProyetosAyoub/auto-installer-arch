#!/bin/bash
clear
for ((x=0; x<$(tput cols)-40; x++));do ncols+="-"; done
intro (){
cat << "EOF"
Bienvenido al automatizador de instalaciones de Arch Linux
                   -`
                  .o+`
                 `ooo/
                `+oooo:
               `+oooooo:
               -+oooooo+:
             `/:-:++oooo+:
            `/++++/+++++++:
           `/++++++++++++++:
          `/+++ooooooooooooo/`
         ./ooosssso++osssssso+`
        .oossssso-````/ossssss+`
       -osssssso.      :ssssssso.
      :osssssss/        osssso+++.
     /ossssssss/        +ssssooo/-
   `/ossssso+/:-        -:/+osssso+-
  `+sso+:-`                 `.-/+oso:
 `++:.                           `-/+/
 .`                                 `
 By CONFUGIRADORES®
EOF
}
 intro
 echo $ncols
 sleep 3
 #COLORS
 nc="\e[m"
 #RESULTS
 error="\e[0;31m[ERROR]\e[m"
 ok="\e[1;32m[OK]\e[m"
 skip="\e[1;33m[SKIP]\e[m"
 warn="\e[1;33m[WARN]\e[m"
 installed="\e[1;32m[INSTALLED]\e[m"
 ##CONST
 ueficheck=$(efibootmgr 2>&1 | grep supported)
 discos=$(ls /dev/?d? /dev/nvme0n? 2>/dev/null)
 ohmyzshlink="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
 basepack=('base' 'linux' 'linux-firmware')
 bichopack=('dhcpcd' 'git' 'nano' 'wget' 'sudo' 'neofetch' 'htop' 'neovim' 'conky' 'networkmanager' 'discord' 'obs-studio')
 aurpackages=('yay' 'pikaur' 'trizen')
 displayservers=('xorg')
 desktops=('xfce4' 'gnome' 'cinnamon' 'plasma' 'mate' 'deepin')
 dms=('lightdm' 'lxdm' 'sddm')
 lightdm_greeters=('lightdm-gtk-greeter' 'lightdm-webkit2-greeter')
 wms=('i3' 'i3-gaps' 'awesome' 'xmonad')
 terminales=('alacritty' 'konsole' 'kitty' 'yakuake' 'terminator')
 shells=('zsh' 'ksh' 'fish')
 fms=('dolphin' 'konqueror' 'nautilus' 'krusader')
 navegadores=('firefox' 'vivaldi' 'chromium' 'opera' 'qutebrowser')
 ##FUNCIONES
 error_handler () {
   if [[ $? -eq 0 ]]
   then
     echo -e "${ok}"
   else
     echo -e "${error}"
     read whaterver #borrar
   fi
 }
 allcaps () {
   input=$1
   input=${input^^}
   echo $input
 }
 empty_lines () {
   clear
   echo ""
   echo $ncols
 }
discos_conectados () {
		echo ""
	 	echo "Tienes los siguientes discos conectados"
	 	n=1
    disk_array=()
	 	for discof in $discos
		 	do
        sizef=$(lsblk $discof | head -n2 | tail -n1 | awk '{print $4}')
        if [[ ! -z $ueficheck ]] && [[ $discof == /dev/nvme0n? ]]
        then
          echo -e "${n}.${discof} [${sizef}] ${warn}"
          dwarn=True
        else
          echo "${n}.${discof} [${sizef}]"
        fi
        sizeconver ${sizef}
        disk_array+=("${nsize}")
        ((n=n+1))
		 	done
		echo""
	 	echo "---------------------------------------"
	 }
sizeconver () {
  osize=$1
  if [[ $osize == *.* ]]
  then
    dsize=$(echo ${osize} | rev | cut -c 2- | rev | cut -f1 -d".")
    decsize=.$(echo ${osize} | cut -f2 -d"." | rev | cut -c 2-)
  else
    dsize=$(echo ${osize} | rev | cut -c 2- | rev)
    decsize=0
  fi
  case $(echo ${osize} | rev | cut -c1) in
    "T")
      nsize=$(($dsize * 1048576))
      decsize=$(echo "$decsize*1.048.576" | bc | cut -f1 -d"." )
      nsize=$(($nsize + $decsize))
      ;;
    "G")
       nsize=$(($dsize * 1024))
       decsize=$(echo "$decsize*1024" | bc | cut -f1 -d"." )
       nsize=$(($nsize + $decsize))
       ;;
    "M")
      nsize=${dsize}
    ;;
    "K")
      nsize=$(($dsize / 1024))
    ;;
    "B")
      nsize=$(($dsize / 1048576))
    ;;
    *)
    nsize=${osize}
  esac
}
fdisk_repair (){
  if [[ $prm == 3 ]]
  then
    opciones+=('nbsp')
  else
  	for o in $(seq 1 2)
  	do
  		opciones+=('nbsp')
  	done
  fi
}
partition_list () {
  for disco in $discos
  do
    if [[ $1 == "vfat" ]]
    then
      partitions=$(lsblk -f $disco | tail +3 | cut -f1,2 -d' ' | grep vfat)
      if [[ $(echo $partitions | wc -l) -gt 0 ]]
      then
        echo "----${disco}"
      fi
    elif [[ $1 == "mpoint" ]]
    then
      partitions=$(lsblk -f $disco | tail +3 | tr -s " " | cut -f1,7 -d' ')
      echo "----${disco}"
    else
      echo "----${disco}"
      partitions=$(lsblk -f $disco | tail +3 | cut -f1,2 -d' ')
    fi
    echo "$partitions"
    echo ""
  done
}
size_test () {
  test_size=-1
  until [[ $test_size -ge 0 ]]
  do
    echo ""
    echo "Que tamaño quieres que tenga la particion."
    echo "Introduce una cifra acompañada de la unidad (T)erabyte (G)igabyte (M)egabyte o (K)ilobyte o pulsa enter para utilizar el resto."
    read psize
    if [[ ! -z $psize ]]
    then
      if [[ ! $psize =~ ^[0-9]{1,5}[GMTK]{1}$ ]] || [[ $psize =~ ^0{1,5}[GMTK]{1}$ ]]
      then
        echo -e "${error} El tamaño no cumple los requisitos necesarios, debe ser un número de máximo 5 cifras y una letra MAYUSCULA."
        echo "Por ej: 12345M"
      else
        sizeconver ${psize}
        if [[ $q2 =~ [LX]{1} ]]
        then
          test_size=$(($extsize - $nsize))
        else
          test_size=$((${disk_array[${dn}]} - $nsize))
        fi
        if [[ $test_size -lt 0 ]]
        then
          echo -e "${error} Tamaño superior al espacio libre del disco."
        else
          opciones+=(+"$psize")
        fi
      fi
    else
      if [[ $q2 == E ]]
      then
        extsize=${disk_array[${dn}]}
      fi
      test_size=0
      opciones+=('nbsp')
      if [[ $ext == "False" ]]
      then
        full=True
      fi
    fi
  done
}
invalid_opt () {
  if [[ ! -z $q2 ]]
  then
    echo -e "${error} Introduce una opción valida."
  fi
}
locales_list () {
  i=0
  locales=()
  for local in $(cat /mnt/etc/locale.gen | tail +7 | grep -v ^["#"] |  cut -f1 -d' ')
  do
    echo "- ${i}.${local}"
    locales+=("${local}")
    ((i=i+1))
  done
}
part_check () {
  if [[ -z $1 ]] || [[ -z $(ls $1 2>/dev/null) ]] || [[ $1 == "/dev/" ]]
  then
    return 1
  elif [[ ! $(echo $1 | rev | cut -c1) =~ [0-9]{1} ]]
  then
    return 2
  fi
  for disk in $(fdisk -l | grep "Disk /dev/" | cut -f2 -d" ")
  do
    if [[ ${1}: == $disk ]]
    then
      return 0
    fi
  done
}
pacman_func () {
  packages=$@
  arch-chroot /mnt pacman -S --noconfirm --needed $packages &>/dev/null
  error_handler
  sleep 1
}
install_package () {
  ipr1=""
  ipr2=""
  name=$1 && shift
  cstname=$1 && shift
  iarr=("$@")
  iarr+=('Otro')
  if [[ ${cstname} == "del shell" ]]
  then
    iarr+=('bash')
  else
    iarr+=('Ninguno')
  fi
  while [[ -z $ipr1 ]] || [[ -z ${iarr[${ipr1}]} ]] || [[ ! -z $overflow ]]
  do
    if [[ ! -z $overflow ]]
    then
      echo -e "${error} Introduce solo un paquete."
    fi
    i=0
    empty_lines
    echo "Selecciona ${name}:"
    for entry in "${iarr[@]}"
    do
      echo "${i}.${entry}"
      ((i=i+1))
    done
    read ipr1 overflow
  done
  if [[ ${iarr[${ipr1}]} == "${iarr[-2]}" ]]
  then
    until [[ $ipr2 == S ]]
    do
      echo "Introduce el/los paquete/s ${cstname} que quieras instalar"
      read ipr1
      echo "Quieres continuar con la instalacion de los siguientes paquetes? S/N"
      for pkg in ${ipr1}
      do
        echo "- ${pkg}"
      done
      read ipr2
      ipr2=$(allcaps $ipr2)
    done
    pacman_func "${ipr1}"
  elif [[ $name == "un Gestor de AUR" ]]
  then
    if [[ ! $(arch-chroot /mnt pacman -Q git sudo) ]]
    then
      until [[ $gi =~ ^[SN]$ ]]
      do
        empty_lines
        echo -e "${warn} Es necesario tener tanto git como sudo para instalar ${iarr[${ipr1}]}"
        echo "Desea instalarlos? S/N"
        read gi
        gi=$(allcaps $gi)
      done
      if [[ $gi == S ]]
      then
        echo -n "Instalando paquetes "
        pacman_func "git" "sudo"
        echo -n "Instalando dependencias "
        pacman_func "base-devel"
      fi
    fi
    if [[ ! $gi == N ]]
    then
      echo -n "Instalando gestor AUR "
      arch-chroot /mnt sh -c "cd /tmp && git clone https://aur.archlinux.org/${iarr[${ipr1}]}.git && echo 'nobody ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && usermod nobody -d /tmp/${iarr[${ipr1}]} -s /bin/bash && chown -R nobody:users ${iarr[${ipr1}]} && cd ${iarr[${ipr1}]} && su nobody -c 'makepkg -si --noconfirm' && usermod nobody -d / -s /usr/bin/nologin && grep -v nobody /etc/sudoers > /opt/sudoers.tmp && cat /opt/sudoers.tmp > /etc/sudoers" &>/dev/null
      error_handler
    fi
  elif [[ ! ${iarr[${ipr1}]} == "${iarr[-1]}" ]]
  then
    case ${iarr[${ipr1}]} in
    "xorg")
      echo -n "Instalando ${iarr[${ipr1}]} "
      pacman_func "xorg xorg-server"
    ;;
    "plasma")
      echo -n "Instalando ${iarr[${ipr1}]} "
      pacman_func "plasma-desktop"
    ;;
    "lightdm")
      ldm_gr=""
      echo -n "Instalando ${iarr[${ipr1}]} "
      pacman_func "lightdm"
      while [[ -z ${lightdm_greeters[${ldm_gr}]} ]] || [[ -z $ldm_gr ]]
      do
        i=0
        empty_lines
        echo "Introduce el numero del greeter que quieras instalar:"
        for greeter in "${lightdm_greeters[@]}"
        do
          echo " ${i}.${greeter}"
          ((i=i+1))
        done
        read ldm_gr
      done
      echo -n "Instalando ${lightdm_greeters[${ldm_gr}]} "
      pacman_func "${lightdm_greeters[${ldm_gr}]}"
      sed -i "s/#greeter-session=example-gtk-gnome/greeter-session=${lightdm_greeters[${ldm_gr}]}/g" /mnt/etc/lightdm/lightdm.conf
      error_handler
    ;;
    "zsh")
      echo -n "Instalando ${iarr[${ipr1}]} "
      pacman_func "zsh"
      error_handler
      until [[ $ohmyzsh =~ ^[SN]$ ]]
      do
        empty_lines
        echo "Desea insalar OhMyZSH? S/N"
        read ohmyzsh
        ohmyzsh=$(allcaps $ohmyzsh)
      done
      if [[ $ohmyzsh == S ]]
      then
        echo -n "Descargando OhMyZSH "
        if [[ -z $username ]]
        then
          arch-chroot /mnt sh -c "$(curl $ohmyzshlink) --unattended" &>/dev/null
        else
          arch-chroot /mnt sh -c "curl $ohmyzshlink -o installer.sh && chmod +x installer.sh && su $username -c './installer.sh --unattended' && rm installer.sh" &>/dev/null
        fi
        error_handler
      fi
    ;;
    *)
      echo -n "Instalando ${iarr[${ipr1}]} "
      pacman_func "${iarr[${ipr1}]}"
    ;;
    esac
  fi
}

#SCRIPT-----------------------------------
if [[ -z $(uname -r | grep arch) ]] ##Elimina este if si sabes lo que haces y no tinenes arch
then
  echo -e "${error} No estas utilizando Arch linux, no se puede seguir con la instalacion"
  exit
fi
if [[ $(whoami) != root ]]
then
  echo -e "${error} Debes ejecutar el programa como root, usa sudo su"
  exit
fi
if [[ -z $discos ]]
then
  echo -e "${error} No hay ningun disco conectado a la maquina"
 	exit
fi
if [[ -z $ueficheck ]]
then
  echo -e "${warn} Tienes un sistema UEFI, crea una particion de al menos 256M en el disco principal"
  until [[ $plist =~ ^[MG]$ ]]
  do
    echo "¿Que tabla de particiones deseas usar? (M)BR o (G)PT"
    echo "Tambien puedes usar ? para ver una breve descripción de ambas."
    read plist
    plist=$(allcaps $plist)
    if [[ $plist == "?" ]]
    then
      echo "-----MBR-----"
      echo "Tiene un numero maximo de 4 particiones, como maximo puede haber 4 primarias y 1 extendida"
      echo "Dentro de la partición extendida podemos crear un maximo de 60 particiones logicas"
      echo "Tamaño maximo de cada particion de 2TB"
      echo "-----GPT-----"
      echo "Tiene un numero maximo de 128 particiones principales"
      echo "Tamaño maximo de cada particion 8ZiB"
    fi
  done
else
  plist="M"
fi
empty_lines
if [[ $plist == "G" ]]
then
  echo -e "Continuando con GPT ${ok}"
else
  echo -e "Continuando con MBR ${ok}"
fi
discos_conectados
echo "Selecciona como quieres particionar los discos."
if [[ ! -z $dwarn ]]
then
  until [[ $dwarnr =~ ^[SN]$ ]]
  do
    echo -e "${warn} Uno o mas discos conectados no son compatibles con BIOS. ¿Desea continuar? S/N"
    read dwarnr
    dwarnr=$(allcaps $dwarnr)
  done
  if [[ $dwarnr == S ]]
  then
    :
  elif [[ $dwarnr == N ]]
  then
    exit
  fi
fi
echo ""
dn=0
for disco in $discos
do
  disk_part=""
  prm=0
	opciones=()
 	echo "----[${disco}]"
 	echo "1.Particionar 2.No particionar 3.Listar discos"
 	read q1
 	until [[ $q1 == 1 ]] || [[ $q1 == 2 ]]
 	do
    if [[ $q1 == 3 ]]
    then
      clear
      discos_conectados
      echo "----[${disco}]"
      echo "1.Particionar 2.No particionar 3.Listar discos"
			read q1
		else
			echo -e "${error} Debes introducir 1 para particionar, 2 para saltar el disco o 3 para listar de nuevo los discos."
	    read q1
    fi
 	done
 	if [[ $q1 == 1 ]]
 	then
 		clear
    comp=$(ls ${disco}? ${disco}p? 2>/dev/null)
    if [[ ! -z $comp ]]
    then
      format_disk=""
      until [[ $format_disk =~ ^[SN]$ ]]
      do
        empty_lines
        echo -e "${error} El disco no esta vacio, vacialo para particionarlo."
        echo "¿Deseas formatealo? S/N"
        echo ""
        echo -e "${warn} PERDERAS TODOS LOS ARCHIVOS"
        read format_disk
        format_disk=$(allcaps $format_disk)
      done
    fi
    if [[ $format_disk == "S" ]] || [[ -z $comp ]]
    then
      mounted=$(mount -l | grep $disco | cut -f1 -d' ')
      if [[ ! -z $mounted ]]
      then
        tumount=$(umount $mounted)
        if [[ ! -z $(echo $tumount | grep busy) ]]
        then
          echo -n "Forzando el desmontado del disco"
          error_handler
        fi
      fi
      swapon=$(fdisk -l | grep swap | awk '{print $1}')
      if [[ ! -z $swapon ]]
      then
        for swapp in $swapon
        do
          swapoff $swapp &>/dev/null
        done
      fi
      until [[ $disk_part == "S" ]]
      do
        if [[ $disk_part == "N" ]]
        then
          disk_part=""
          prm=0
        	opciones=()
          uefi_part=''
          sizeconver "$(lsblk $disco | head -n2 | tail -n1 | awk '{print $4}')"
          disk_array[${dn}]=$nsize
        fi
        printf "o\nw\n" | fdisk $disco &>/dev/null
  			ext=False
        full=False
    		for i in $(seq 1 63)
        do
          if [[ $full == "True" || $plist == "G" || ( ${disk_array[${dn}]} -eq 0 && ${extsize} -eq 0 )]]
          then
            break
          fi
          q2=''
          spc=''
  				if [[ $prm -le 3 ]] && [[ ${disk_array[${dn}]} -gt 0 ]]
    			then
            if [[ $ext == True ]]
    				then
    					until [[ $q2 =~ ^[PLCF]$ ]]
    	        do
                empty_lines
                invalid_opt
    						echo "----[${disco}] Restante: ${disk_array[${dn}]}M Extended: ${extsize}M"
    	          echo ""
    	          echo "Debes seleccionar un tipo de particion o cancelar la operacion."
    	          echo ""
    	          echo "Particion ${i}:"
    						if [[ $i == 1 ]]
    						then
    							echo "(P)rimaria, (L)ogica o (C)ancelar"
    						else
    							echo "(P)rimaria, (L)ogica, (F)in o (C)ancelar)"
    						fi
    	           	read q2
                  q2=$(allcaps $q2)
                  if [[ $i == 1 ]] && [[ $q2 == F ]]
                  then
                    q2=foo
                  fi
              done
    				else
    					until [[ $q2 =~ ^[PECF]$ ]]
    	        do
                empty_lines
                invalid_opt
    	          echo "----[${disco}] Restante: ${disk_array[${dn}]}M"
    	          echo ""
    	          echo "Debes seleccionar un tipo de particion o cancelar la operacion."
    	          echo ""
    	          echo "Particion ${i}:"
    						if [[ $i == 1 ]]
    						then
    		  				echo "(P)rimaria, (E)xtendida o (C)ancelar"
    						else
    							echo "(P)rimaria, (E)xtendida, (F)in o (C)ancelar)"
    						fi
    	          read q2
                q2=$(allcaps $q2)
                if [[ $i == 1 ]] && [[ $q2 == F ]]
                then
                  q2=foo
                fi
              done
    				fi
  				else
  					if [[ $ext == True ]]
  					then
  						until [[ $q2 =~ ^[NF]$ ]]
  						do
                empty_lines
                invalid_opt
  							echo "----[${disco}] Extended: ${extsize}M"
  							echo ""
  							echo "Se han terminado de crear todas las particiones primarias."
                echo "A continuacion se crearan particiones logicas"
  							echo "(N)ueva, (F)inalizar"
  							read q2
                q2=$(allcaps $q2)
              done
  						if [[ $q2 == N ]]
  						then
  							q2=X
              else
                break
  						fi
            else
              break
  					fi
  				fi
          case $q2 in
            "P")
				     opciones+=('n')
             opciones+=('p')
  					 fdisk_repair
  					 ((prm=prm+1))
            ;;
            "E")
    					ext=True
    					opciones+=('n')
              opciones+=('e')
    					fdisk_repair
    					((prm=prm+1))
            ;;
            "L")
    					opciones+=('n')
    					opciones+=('l')
    					opciones+=('nbsp')
            ;;
            "C"|"F")
              opciones=('')
              break 1
            ;;
            "X")
    					opciones+=('n')
    					opciones+=('nbsp')
            ;;
          esac
          size_test
          if [[ $q2 == E ]] && [[ ! -z $psize ]]
          then
            sizeconver $psize
            extsize=$nsize
          fi
          if [[ $q2 =~ ^[LX]$ ]]
          then
            extsize=$test_size
          else
            disk_array[${dn}]=$test_size
          fi
          if [[ ! $q2 == E ]]
          then
    				echo "¿Es una particion especial?"
            if [[ -z $ueficheck ]] && [[ -z $uefi_part ]]
            then
              until [[ $spc =~ ^[SUN]$ ]]
      				do
                if [[ ! -z $spc ]]
                then
                  echo -e "${error} Introduce una opción valida"
                fi
                echo "(S)wap o (U)efi, (N)o"
                read spc
                spc=$(allcaps $spc)
              done
            else
              until [[ $spc =~ ^[SN]$ ]]
      				do
                if [[ ! -z $spc ]]
                then
                  echo -e "${error} Introduce una opción valida"
                fi
                echo "(S)wap, (N)o"
                read spc
                spc=$(allcaps $spc)
              done
            fi
            case $spc in
              "S")
    					  opciones+=('t')
      					if [[ ! $i == 1 ]]
      					then
      						opciones+=("$i")
      					fi
      					opciones+=('82')
              ;;
			        "U")
                uefi_part="True"
				        opciones+=('t')
      				  if [[ ! $i == 1 ]]
      					then
      						opciones+=("$i")
      					fi
      					opciones+=('ef')
              ;;
            esac
          fi
  	    done
        if [[ $plist == "G" ]]
        then
          for i in $(seq 1 128)
          do
              q2=""
              if [[ ${disk_array[${dn}]} -eq 0 ]]
              then
                break
              fi
              until [[ $q2 =~ ^[NFC]$ ]]
              do
                empty_lines
                invalid_opt
          	    echo "----[${disco}] Restante: ${disk_array[${dn}]}M"
                echo "A continuacion se van a crear particiones primarias"
                echo "(N)ueva, (F)inalizar o (C)ancelar"
                read q2
                q2=$(allcaps $q2)
              done
              case $q2 in
                N)
                  opciones+=('n')
                  opciones+=('nbsp')
                  opciones+=('nbsp')
                  size_test
                  spc="foo"
                  until [[ $spc =~ ^[LSE]$ ]] || [[ -z $spc ]]
                  do
                    echo ""
                    echo "Selecciona el tipo de particion"
                    echo "(L)inux FileSystem (Por defecto)"
                    echo "(S)wap"
                    if [[ -z $uefi_part ]]
                    then
                      echo "(E)fi"
                    fi
                    read spc
                    spc=$(allcaps $spc)
                    if [[ -z $spc ]]
                    then
                      spc="L"
                    elif [[ $spc == "E" ]] && [[ ! -z $uefi_part ]]
                    then
                      spc="Nope"
                    fi
                  done
                  case $spc in
                    L)
                      opciones+=('nbsp')
                    ;;
                    S)
                      opciones+=('8200')
                    ;;
                    E)
                      uefi_part="True"
                      opciones+=('ef00')
                    ;;
                  esac
                  disk_array[${dn}]=$test_size
                ;;
                F)
                  break
                ;;
                C)
                  break
                ;;
              esac
          done
        fi
  			if [[ ! $q2 == C ]]
  			then
          if [[ $plist == "M" ]]
          then
            opciones+=("w")
          else
            opciones+=('w')
            opciones+=('Y')
          fi
  				name=$(printf "$disco" | awk -F'/' '{print $3}')
  	      touch /tmp/disk${name}.tmp
  	      for opt in "${opciones[@]}"
  	      do
            if [[ $opt == nbsp ]]
  					then
              printf "\n" >> /tmp/disk${name}.tmp
  					else
  	         	printf "$opt\n" >> /tmp/disk${name}.tmp
  					fi
          done
          if [[ $plist == M ]]
          then
  				      fdisk /dev/${name} < /tmp/disk${name}.tmp &>/dev/null
          elif [[ $plist == G ]]
          then
                gdisk /dev/${name} < /tmp/disk${name}.tmp &>/dev/null
          fi
          rm /tmp/disk${name}.tmp
  			fi
        until [[ $disk_part =~ ^[SN]$ ]]
        do
          empty_lines
          echo $disco
          particiones=$(lsblk $disco | tail +3 | sed -r 's/[ ]+/-/g' | cut -f1,4 -d'-')
          if [[ $(echo $particiones | wc -w) -eq 0 ]]
          then
            echo ""
            echo "No has creado ninguna particion, ¿quieres continuar? S/N"
            read disk_part
            disk_part=$(allcaps $disk_part)
          else
            for line in $particiones
      	    do
              echo "$line"
	            done
              echo ""
              echo "¿Estas son las particiones que has creado, quieres continuar? S/N"
              read disk_part
              disk_part=$(allcaps $disk_part)
          fi
        done
      done
    fi
 	fi
  ((dn=dn+1))
done
empty_lines
if [[ -z $(fdisk -l | grep "Device") ]]
then
  echo -e "${error} No has creado ninguna particion"
  echo ""
  sleep 2
  exit 1
fi
echo "Se han acabado de particionar los discos, ahora es necesario formatearlos."
echo ""
eswap=$(fdisk -l | grep swap | awk '{print $1}')
uefipart=$(fdisk -l | grep EFI | cut -f1 -d" ")
if [[ $(echo $uefipart | wc -w) = 1 ]]
then
  mkfs.fat -F 32 ${uefipart} &>/dev/null
elif [[ $(echo $uefipart | wc -w) > 1 ]]
then
  until [[ $uefipartq > 0 ]] && [[ $uefipartq < $i ]]
  do
    echo "Selecciona la particion UEFI:"
    i=1
    for part in $uefipart
    do
      echo "$i.${part}"
      ((i=i+1))
    done
    read uefipartq
  done
  uefipart=$(echo $uefipart | cut -f${uefipartq} -d" ")
  mkfs.fat -F 32 ${uefipart} &>/dev/null
fi
if [[ -z $eswap ]]
then
	echo -e "${warn} No existe ninguna particion SWAP."
	echo "¿Quieres convertir una particion existente en SWAP? S/N"
	read q3
  q3=$(allcaps $q3)
	until  [[ $q3 =~ ^[NS]$ ]]
	do
		echo -e "${error}${q3} no es un valor valido, introduce S o N"
		read q3
    q3=$(allcaps $q3)
	done
	if [[ $q3 == S ]]
	then
		echo "Introduce la particion que quieres convertir en swap Ej: sdb2"
    partition_list
		read q4
		while [[ -z $(ls /dev/$q4 2>/dev/null) ]]
		do
			echo "Introduzca una particion para convertir en swap o (C)ancelar"
			read q4
      if [[ $q4 =~ ^[Cc]$ ]]
      then
        break 1
      fi
		done
    if [[ ! $q4 =~ ^[Cc]$ ]]
      then
  		spart=$(printf $q4 | rev | cut -c 1)
  		printf "t\n${spart}\n82\nw\n" > /tmp/swap.txt
  		sdisk=$(printf $q4 | cut -c 1,2,3)
  		fdisk /dev/${sdisk} < /tmp/swap.txt 1>/dev/null
  		rm /tmp/swap.txt
    fi
	fi
fi
for swapp in ${eswap[*]}
do
  mkswap $swapp &>/dev/null
  swapon $swapp &>/dev/null
done
until [[ $q7 == N ]]
do
	q5=""
  q7=""
	until [[ $q5 =~ ^[fF]$ ]]
	do
    empty_lines
    echo ""
  	echo "---------------Particiones"
  	partition_list
    echo ""
		echo "Introduce una particion para formatear o (F)in"
		read q5 overflow
		empty_lines
		if [[ ! $q5 =~ ^[fF]$ ]]
		then
      part_check /dev/${q5}
			fcomp=$?
			if [[ $fcomp -ne 0 ]]
			then
				echo -e "${error} ${q5} no es una particion valida"
        sleep 2
      elif [[ -z $q5 ]]
      then
        :
			elif [[ ${eswap[*]} =~ /dev/$q5 ]]
			then
				echo -e "${error} ${q5} no se puede formatear (es la particion de SWAP)"
				sleep 2
      elif [[ /dev/$q5 == "$uefipart" ]]
      then
				echo -e "${error} ${q5} no se puede formatear (es la particion de UEFI)"
				sleep 2
			else
        q6=""
        until [[ $q6 =~ ^[EFBXC]$ ]]
        do
          empty_lines
          echo "Que formato quieres darle a /dev/${q5}"
				  echo "(e)xt4, (f)at32, (b)trfs, e(x)fat o (c)ancelar"
				  read q6
          q6=$(allcaps $q6)
        done
        if [[ ! $q6 == C ]]
        then
          echo -n "Formateando "
        fi
				if [[ $q6 == E ]]
				then
					mkfs.ext4 /dev/${q5} &>/dev/null
          error_handler
				elif [[ $q6 == F ]]
				then
					mkfs.fat -F 32 /dev/${q5} &>/dev/null
          error_handler
        elif [[ $q6 == B ]]
        then
          mkfs.bfs /dev/${q5} &>/dev/null
          error_handler
        elif [[ $q6 == X ]]
        then
          mkfs.exfat /dev/${q5} &>/dev/null
          error_handler
				fi
			fi
      sleep .5
      empty_lines
		fi
	done
  until [[ $q7 =~ ^[SN]$ ]]
  do
  	empty_lines
  	echo "Se han terminado de fomatear las particiones"
  	echo ""
  	partition_list
  	echo ""
  	echo "Desea modificar algun formato? S/N"
  	read q7
    q7=$(allcaps $q7)
  done
done
while [[ -z $rcomp ]]
do
  empty_lines
  echo "A continuacion se van a montar las particiones"
  echo ""
  partition_list
  echo ""
  echo "Introduzca la particion root (/)"
  read rootp overflow
  part_check /dev/${rootp}
  rcomp=$?
  if [[ $rcomp -ne 0 ]] || [[ ${eswap[*]} =~ /dev/$rootp ]] || [[ "/dev/${rootp}" == "${uefipart}" ]]
  then
    rcomp=""
    echo -e "${error} ${rootp} no es una particion valida"
    sleep 2
  fi
  mkfs.ext4 -F /dev/${rootp} &>/dev/null
done
mount /dev/${rootp} /mnt 2>/dev/null
pacstrap_install='foo'
x="False"
until [[ -z $pacstrap_install ]]
do
  clear
  echo -n "Instalando kernel "
  pacstrap_install=$(pacstrap /mnt "${basepack[@]}" 2>&1 1>/dev/null)
  if [[ ! -z $(echo $pacstrap_install | grep full) ]]
  then
    echo -e $error
    echo "La particion que se ha seleccionado como root es muy pequeña."
    echo "Vuelva a crear las particiones y deje mas tamaño para la particion root"
    exit
  elif [[ ! -z $pacstrap_install ]]
  then
    if [[ $(echo $pacstrap_install | grep "is unknown trust error") ]]
    then
      echo -e $warn
      echo -n "Actualizando certificados "
      pacman -Sy &>/dev/null
      pacman -S --noconfirm archlinux-keyring &>/dev/null
      error_handler
      sleep 2
    elif [[ $(echo $pacstrap_install | grep "reinstalling") ]] && [[ $x == "False" ]]
    then
      pacstrap_install=""
      x="True"
    else
      echo -e "${error} Ha ocurrido el siguiente error"
      echo $pacstrap_install
      exit
    fi
  fi
done
error_handler
echo -n "Actualizando certificados "
arch-chroot /mnt pacman -S --noconfirm "archlinux-keyring" &>/dev/null
error_handler
echo -n "Actualizando paquetes base "
arch-chroot /mnt pacman -Syu --noconfirm &>/dev/null
error_handler
if [[ ! -z $uefipart ]]
then
  mkdir -p /mnt/boot/efi
  mount $uefipart /mnt/boot/efi 2>/dev/null
fi
sleep 2
until [[ $part =~ ^[fF]$ ]]
do
  empty_lines
  if [[ $part =~ ^[lL]$ ]]
  then
    partition_list mpoint
  fi
  echo "Introduzca los puntos de montaje de la siguiente manera:"
  echo "Ej: sda2 /boot/efi"
  echo "Utilize (F)in para no montar mas unidades o (L)iste las unidades."
  read part mpoint
  if [[ $part =~ ^[fFlL]$ ]]
  then
    :
  else
    regex='^[\/]?([.]?[a-zA-Z][a-zA-Z0-9\-\_]*[\/]?)+$'
    part_check /dev/${part}
    mcomp=$?
    if [[ -z $(echo $mpoint | grep '^/') ]]
    then
      mpoint=/$mpoint
    fi
    if [[ -z $part ]] || [[ $mcomp -ne 0 ]]
    then
      echo -e "${error} Tienes que introducir una particion valida"
      sleep 2
    elif [[ $part == "$rootp" ]]
    then
      echo -e "${error} No puedes montar la particion root"
      sleep 2
    elif [[ ${eswap[*]} =~ /dev/$part ]]
    then
      echo -e "${error} No puedes montar la particion swap"
      sleep 2
    elif [[ /dev/${part} == "$uefipart" ]]
    then
      echo -e "${error} No puedes montar la particion uefi"
      sleep 2
    elif [[ -z $mpoint ]] || [[ ! $mpoint =~ $regex ]]
    then
      echo -e "${error} Tienes que introducir un punto de montaje"
      sleep 2
    elif [[ ! -d /mnt${mpoint} ]]
    then
      q8="foo"
      until [[ $q8 =~ ^[SN]$ ]]
      do
        echo -e "${error} No existe el punto de montaje, quieres crearlo? S/N"
        read q8
        q8=$(allcaps $q8)
      done
      if [[ $q8 == S ]]
      then
        mkdir -p /mnt/$mpoint
        mount /dev/$part /mnt/$mpoint
        echo -e "${ok} Se ha creado ${mpoint} y se ha montado ${part}."
        sleep 3
      fi
    else
      mount /dev/$part /mnt/$mpoint
    fi
  fi
done
clear
echo -n "Generando fstab "
genfstab -U /mnt >> /mnt/etc/fstab
error_handler
sleep 2
until [[ $q9 == S ]]
do
  hostname=''
  while [[ -z $hostname ]] || [[ ! $hostname =~ ^[a-z][a-z0-9\-]{3,31} ]]
  do
    empty_lines
    if [[ ! -z $hostname ]]
    then
      echo -e "${error} El nombre solo puede usar letras minusculas, numeros y _-"
      echo "El nombre debe empezar por _ o letras minusculas"
    fi
    echo "Cual es el nombre que va a tener este equipo"
    read hostname
  done
  echo $hostname > /mnt/etc/hostname
  empty_lines
  echo "El nombre del equipo es:"
  cat /mnt/etc/hostname
  echo "Es correcto? S/N"
  read q9
  q9=$(allcaps $q9)
done
until [[ $q10 == S ]]
do
  regionf=''
  ciudadf=''
  q10=''
  while [[ -z $regionf ]]
  do
    i=0
    regiones=()
    empty_lines
    echo "Teclea el numero de la region en la que te encuentras"
    for region in /mnt/usr/share/zoneinfo/*
    do
      region=$(echo $region | cut -f6 -d"/")
      if [[ -f /mnt/usr/share/zoneinfo/$region ]] || [[ $region == Etc ]] || [[ $region == posix ]] || [[ $region == right ]] || [[ $region == SystemV ]]
      then
        :
      else
        echo "${i}.${region}"
        regiones+=("${region}")
        ((i=i+1))
      fi
    done
    read regionq
    if [[ $ciudadq =~ ^[0-9] ]]
    then
     regionf=${regiones[${regionq}]}
    else
     regionf=''
    fi
    if [[ -z $regionf ]]
    then
      echo -e "${error} No hay ninguna region con el numero ${regionq}"
      sleep 2
    fi
  done
  while [[ -z $ciudadf ]]
  do
    i=0
    ciudades=()
    ciudadi=''
    ciudadq=''
    while [[ -z $ciudadi ]] || [[ -z $(ls /mnt/usr/share/zoneinfo/$regionf/${ciudadi^}* 2>/dev/null) ]]
    do
      empty_lines
      if [[ -z $(ls /mnt/usr/share/zoneinfo/$regionf/${ciudadi^}* 2>/dev/null) ]]
      then
        echo -e "${error} No existe ninguna ciudad con esa letra."
      fi
      echo "Teclea la letra inicial de la ciudad en la que te encuentras"
      read ciudadi
    done
    while [[ -z $ciudadq ]]
    do
      i=0
      empty_lines
      echo "Teclea el numero de la ciudad en la que te encuentras"
      for ciudad in /mnt/usr/share/zoneinfo/$regionf/${ciudadi^}*
      do
        ciudad=$(echo "${ciudad}" | cut -f7 -d'/')
        echo "${i}.${ciudad}"
        ciudades+=("${ciudad}")
        ((i=i+1))
      done
      echo "${i}.Ninguna"
      ciudades+=("Ninguna")
      read ciudadq
      if [[ $ciudadq =~ ^[0-9] ]]
      then
       ciudadf=${ciudades[${ciudadq}]}
      else
       ciudadf=''
      fi
    done
    if [[ -z $ciudadf ]]
    then
      echo -e "${error} No hay ninguna ciudad con el numero ${ciudadq}"
      sleep 2
    elif [[ $ciudadf == "Ninguna" ]]
    then
      ciudadf=''
    fi
  done
  until [[ $q10 =~ ^[SN]$ ]]
  do
    empty_lines
    echo "La ubicacion es:"
    echo "${ciudadf}, ${regionf}"
    echo "Es correcto? S/N"
    read q10
    q10=$(allcaps $q10)
  done
done
ln -sf /mnt/usr/share/zoneinfo/$regionf/$ciudadf /mnt/etc/localtime
hwclock --systhoc
empty_lines
echo "A continuacion descomente los locales que quiera instalar"
echo "Presione cualquier tecla para continuar"
read cualquiera
until [[ $q11 == S ]]
do
  q11=''
  nano /mnt/etc/locale.gen
  if [[ -z $(locales_list) ]]
  then
    empty_lines
    echo -e "${error} No has seleccionado ningun idioma."
    echo "Para seleccionarlo borra el # del idioma que quieras usar."
    sleep 3
  else
    until [[ $q11 =~ ^[SN]$ ]]
    do
      empty_lines
      echo "Se van a instalar los siguientes locales:"
      locales_list
      echo ""
      echo "Desea continuar? S/N"
      read q11
      q11=$(allcaps $q11)
    done
  fi
done
clear
echo -n "Generando locales "
arch-chroot /mnt locale-gen &>/dev/null
error_handler
sleep 1
if [[ -z ${locales[1]} ]]
then
  langf=${locales[0]}
else
  until [[ $q12 == S ]]
  do
    langf=''
    q12=''
    lang=''
    while [[ -z $lang ]]
    do
      empty_lines
      echo "Cual va a ser el idioma del sistema operativo:"
      locales_list
      read lang
      langf=${locales[${lang}]}
      if [[ -z $langf ]]
      then
        echo -e "${error} No existe ningun idioma con el numero ${lang}"
        sleep 2
      fi
    done
    empty_lines
    echo "Se va a asignar [${langf}] como idioma principal"
    echo "Desea continuar? S/N"
    read q12
    q12=$(allcaps $q12)
  done
fi
echo "LANG=${langf}" > /mnt/etc/locale.conf
until [[ $q13 == S ]]
do
  q13=''
  keymap='foo'
  until [[ -z $keymap ]] || [[ ! -z $(arch-chroot /mnt localectl list-keymaps | grep ${keymap} 2>/dev/null) ]]
  do
    empty_lines
    echo "A continuacion seleccione el layout del teclado (No introduzca nada para US)"
    echo "Pulsa cualquier tecla para mostrar las posibilidades y pulsa Q para salir."
    read cualquiera
    arch-chroot /mnt localectl list-keymaps
    echo ""
    echo "Introduce el layout que quieras usar"
    read keymap
  done
  if [[ -z $keymap ]]
  then
    keymap="us"
  fi
  until [[ $q13 =~ ^[NS]$ ]]
  do
    empty_lines
    echo "Se va a instalar el siguiente layout"
    echo "[${keymap}]"
    echo "Desea continuar? S/N"
    read q13
    q13=$(allcaps $q13)
  done
done
echo "KEYMAP=${keymap}" > /mnt/etc/vconsole.conf
until [[ $q14 =~ ^[NS]$ ]]
do
  empty_lines
  echo "Quieres crear un usuario nuevo? S/N"
  read q14
  q14=$(allcaps $q14)
done
if [[ $q14 == S ]]
then
  name_length="False"
  while [[ $username == root ]] || [[ -z $username ]] || [[ $valid_name == "False" ]]
  do
    empty_lines
    echo "Como va a llamarse?"
    read username
    username=${username,,}
    if [[ $username =~ ^[a-z\_][a-z0-9\_\-]{3,31} ]]
    then
      valid_name="True"
    else
      valid_name="False"
    fi
    if [[ $valid_name == "False" ]]
    then
      echo -e "${error} La longitud del nombre de usuario debe estar entre 3 y 32 caracteres."
      echo "El nombre debe empezar por una letra minuscula o _ y solo puede contener letras, numeros y -_"
      sleep 3
    fi
  done
  echo -n "Creando usuario "
  arch-chroot /mnt useradd $username &>/dev/null
  error_handler
  echo -n "Creando directorio home de ${username} "
  if [[ ! -d /mnt/home/$username ]]
  then
    arch-chroot /mnt mkdir /home/$username
    echo -e "${ok}"
  else
    echo -e "${warn}"
  fi
  echo -n "Cambiando los permisos "
  arch-chroot /mnt chown -R $username:$username /home/$username
  error_handler
  arch-chroot /mnt passwd ${username}
  until [[ $? -eq 0 ]]
  do
    echo -e "${error} Las contraseñas no coinciden"
    arch-chroot /mnt passwd ${username}
  done
fi
empty_lines
echo "Asigna una clave al usuario root"
arch-chroot /mnt passwd root
until [[ $? -eq 0 ]]
do
  echo -e "${error} Las contraseñas no coinciden"
  arch-chroot /mnt passwd root
done
echo "127.0.0.1     localhost" > /mnt/etc/hosts && echo "::1      localhost" >> /mnt/etc/hosts && echo "127.0.1.1     ${hostname}.localdomain     ${hostname}" >> /mnt/etc/hosts
until [[ $q15 =~ ^[NS]$ ]]
do
  empty_lines
  echo "A continuacion se van a instalar las siguientes dependencias:"
  echo ""
  for pq in "${bichopack[@]}"
  do
    echo "- ${pq}"
  done
  echo ""
  echo "Desea instalar alguno de los paquetes? S/N"
  read q15
  q15=$(allcaps $q15)
done
if [[ $q15 == S ]]
then
  while [[ -z $q16 ]]
  do
    clear
    echo ""
    echo "Teclee el/los numeros de los paquetes que desee instalar"
    i=0
    echo "- 40.Ninguno"
    for pq in "${bichopack[@]}"
    do
      echo "- ${i}.${pq}"
      ((i=i+1))
    done
    echo "- 30.Todos"
    read q16
  done
  if [[ $q16 == 40 ]]
  then
    :
  elif [[ $q16 == 30 ]]
  then
    clear
    echo -n "Instalando todos los paquetes "
    pacman_func "${bichopack[@]}"
  else
    for pq in $q16
    do
      target=${bichopack[$pq]}
      if [[ -z $target ]]
      then
        echo -e "${error} No existe ningun paquete con el numero ${pq}"
      else
        echo -n "Instalando ${target} "
        pacman_func "${target}"
      fi
    done
  fi
 sleep 2
fi
if [[ ! -z $(arch-chroot /mnt pacman -Q sudo 2>/dev/null) ]] && [[ ! -z $username ]]
then
  until [[ $q17 =~ ^[NS]$ ]]
  do
    empty_lines
    echo "Se ha detectado que has instalado la utilidad sudo."
    echo "¿quieres agregar a tu usuario a sudoers? S/N"
    read q17
    q17=$(allcaps $q17)
  done
  if [[ $q17 == S ]]
  then
    echo "${username} ALL=(ALL) ALL" >> /mnt/etc/sudoers
  fi
fi
gpuinfo=$(lspci | grep VGA | grep NVIDIA)
if [[ ! -z $gpuinfo ]]
then
  until [[ $q18 =~ ^[NS]$ ]]
  do
    empty_lines
    echo -e "${warn} Se ha detectado que tu tarjeta grafica es NVIDIA, deseas instalar los drivers de NVIDIA? S/N"
    read q18
    q18=$(allcaps $q18)
  done
  if [[ $q18 == S ]]
  then
    pacman_func "nvidia" "nvidia-utils"
    echo -e "${ok} Se han instalado los drivers de NVIDIA"
  fi
fi
biosv="efi"
until [[ ( $biosv == "bios" && $gcomp -eq 2 ) || ( ! -z $grubd && $biosv == "efi" ) ]]
do
  if [[ ! -z $ueficheck ]]
  then
    biosv="bios"
  else
    if [[ ! -z $(lsblk -f | grep vfat) ]]
    then
      :
    elif [[ -z $(lsblk -f | grep vfat) ]] && [[ -z $(ls /dev/nvme*) ]]
    then
      biosv="bios"
    else
      until [[ $nouefi == "C" ]]
      do
        if [[ $nouefi == "S" ]]
        then
          exit 1
        fi
        empty_lines
        echo -e "${error} No se ha encontrado ninguna particion uefi."
        echo "Se va a continuar con la instalacion en modo BIOS, es posible que uno o varios discos no sean detectados correctamente."
        echo "(C)ontinuar o (S)alir"
        read nouefi
        nouefi=$(allcaps $nouefi)
      done
      biosv="bios"
    fi
  fi
  empty_lines
  if [[ $biosv == "bios" ]]
  then
    echo "A continuacion se va a descargar e instalar grub, seleccione el DISCO de arranque"
    discos_conectados
    read grubd
    part_check ${grubd}
    gcomp=$?
  else
    if [[ $(lsblk -f | grep vfat | wc -l) -gt 1 ]]
    then
      echo "A continuacion se va a descargar e instalar grub, seleccione la particion UEFI"
      partition_list vfat
      read grubd
    else
      grubd=$(lsblk -f | grep vfat | cut -f1 -d" " | cut -c7-)
    fi
    grubd=$(lsblk -f /dev/${grubd} | grep vfat 2>/dev/null)
  fi
done
echo -n "Descargando GRUB "
pacman_func "grub"
if [[ $biosv == "bios" ]]
then
  echo -n "Instalando GRUB "
  arch-chroot /mnt grub-install --target=i386-pc ${grubd} &>/dev/null
else
  echo -n "Descargando efibootmgr "
  pacman_func "efibootmgr"
  echo -n "Instalando GRUB "
  arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB &>/dev/null
fi
error_handler
echo -n "Generando el archivo de configuracion de grub "
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null
error_handler
sleep 2
until [[ $q19 =~ ^[NS]$ ]]
do
  empty_lines
  echo "Por ultimo vamos a instalar el entorno grafico"
  echo "Desea continuar(s) o quiere instalarlo por su cuenta(n)"
  read q19
  q19=$(allcaps $q19)
done
if [[ $q19 == "N" ]]
then
  empty_lines
  echo ""
  echo "GRACIAS POR UTILIZAR ARCH GUIDE-INSTALL BY CONFUGIRADORES®"
  echo ""
  echo "--------------------------------------------------------------------------------------------------"
  echo "Visita www.confugiradores.es para mas scripts, proyectos y tutoriales."
  sleep 3
  exit
fi
empty_lines
until [[ $q20 =~ ^[NS]$ ]]
do
  echo "Quieres instalar un gestor de paquetes AUR? S/N"
  read q20
  q20=$(allcaps $q20)
done
if [[ $q20 == S ]]
then
  install_package "un Gestor de AUR" "del gestor de AUR" "${aurpackages[@]}"
fi
install_package "un Display Server" "del display server" "${displayservers[@]}"
install_package "un Escritorio" "del escritorio" "${desktops[@]}"
install_package "un Display Manager" "del display manager" "${dms[@]}"
arch-chroot /mnt systemctl enable ${iarr[${ipr1}]}
if [[ ${iarr[${ipr1}]} == "Ninguno" ]]
then
  install_package "un Window Manager" "del window manager" "${wms[@]}"
fi
wm=${iarr[${ipr1}]}
install_package "un Terminal" "del terminal" "${terminales[@]}"
terminal=${iarr[${ipr1}]}
install_package "un Shell, el shell por defecto es bash" "del shell" "${shells[@]}"
echo -n "Cambiando shell"
if [[ -z $username ]]
then
  arch-chroot /mnt usermod root -s /usr/bin/${iarr[${ipr1}]} &>/dev/null
else
  arch-chroot /mnt usermod $username -s /usr/bin/${iarr[${ipr1}]} &>/dev/null
fi
error_handler
install_package "un File Manager" "del File Manager" "${fms[@]}"
install_package "un Navegador" "del navegador" "${navegadores[@]}"
if [[ ! -z $(arch-chroot /mnt pacman -Q dhcpcd 2>/dev/null) ]]
then
  echo -n "Activando configuracion de red "
  arch-chroot /mnt systemctl enable dhcpcd &>/dev/null
  error_handler
fi
if [[ ! $wm == "Ninguno" ]]
then
  echo -n "Cambiando el terminal por defecto "
  if [[ -z $username ]]
  then
    echo ""
  else
    case $wm in
      awesome)
        arch-chroot /mnt mkdir /home/$username/.config/awesome && printf "terminal = \"${terminal}\" " >> /home/$username/.config/awesome/rc.lua
      ;;
      xmonad)
        arch-chroot /mnt mkdir /home/$username/.config/xmonad && printf "import XMonad\n main = xmonad def\n { terminal = \"${terminal}\"\n}" >> /home/$username/.config/xmonad/xmonad.hs
      ;;
    esac
    error_handler
  fi
fi
if [[ ! -z $(arch-chroot /mnt pacman -Q networkmanager 2>/dev/null) ]]
then
  echo -n "Habilitando NetworkManager "
  arch-chroot /mnt systemctl enable NetworkManager &>/dev/null
  if [[ ! -z $(arch-chroot /mnt pacman -Q plasma-desktop 2>/dev/null) ]]
  then
    pacman_func plasma-nm
  else
    pacman_func network-manager-applet
  fi
  sleep 1
fi
empty_lines
echo ""
echo "GRACIAS POR UTILIZAR ARCH GUIDE-INSTALL BY CONFUGIRADORES®"
echo ""
echo "--------------------------------------------------------------------------------------------------"
echo "Visita www.confugiradores.es para mas scripts, proyectos y tutoriales."
sleep 3
poweroff




