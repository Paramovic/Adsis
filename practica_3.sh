#!/bin/bash

#845107, Tomas, Daniel, M, 3, B
#875325, Martinez, Victor, M, 3, B

function usuario {
    if [ "$(id -u)" -ne 0 ]; then
	echo -e "Este script necesita privilegios de administracion"
	exit 1
    fi
}

function parametros {
    if [ "$#" -ne 2 ]; then
	echo "Numero incorrecto de parametros"
	exit 1
    fi
    if [[ "$1" != "-a" && "$1" != "-s" ]] 
    then 	
	echo -e "Opcion invalida" >&2   
	exit 1
    fi
}

function eliminarUsuario {
    mkdir -p /extra/backup

    while IFS=, read -r nombre _ _ 
    do     
	if id "$nombre" &>/dev/null
	then
	    dirHome=$(eval echo ~$nombre)
	    if [ -d "$dirHome" ]
	    then
	        tar -cf /extra/backup/$nombre.tar "$dirHome" >/dev/null 2>&1
	    fi
	    estado=$?   
	    if [ $estado -eq 0 ]  
	    then
	        userdel -r "$nombre" >/dev/null 2>&1  
	    else  
	        rm -f /extra/backup/$nombre.tar  
	    fi		    
	fi
    done < "$1"
}

function anadirUsuario {
    while IFS=, read -r nombre psswd nomCom  # Mientras podamos leer el fichero que nos pasan
    do     # como parametro,
	if [[ -z "$nombre" || -z "$psswd" || -z "$nomCom" ]]  # Si alguno de los 
	then      # parametros del usuario es vacio, indicamos que es un campo invalido al no
	    echo -e "Campo invalido"  # contener nada y terminamos la ejecución.
	    exit 1
	fi
	
	if id "$nombre" &>/dev/null
	then 
	    echo "El usuario $nombre ya existe"
	else
	    useradd -m -k /etc/skel -K UID_MIN=1815 -K PASS_MAX_DAYS=30 -c "$nomCom" -U "$nombre"
	    if [[ $? -eq 0 ]]
	    then
	        echo -e "${nomCom} ha sido creado"
	        echo "$nombre:$psswd" | chpasswd
		usermod -s /bin/bash "$nombre"
	    else
		echo -e "Error al crear el usuario $nombre"
		exit 1
	    fi
	fi
    done < "$1"
}

usuario
parametros "$1" "$2"

if [ "$1" = "-s" ]
then
    eliminarUsuario "$2"
else
    anadirUsuario "$2"
fi
