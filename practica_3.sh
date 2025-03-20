#!/bin/bash

#845107, Tomas, Daniel, M, 3, B
#875325, Martinez, Victor, M, 3, B

function usuario {
    if [ "$(id -u)" -ne 0 ]  # Si el usuario no tiene permisos de administrador, la salida devolvera 
    then 			 # un valor distinto a 0.
	echo "Este script necesita privilegios de administracion" #Se le indica que necesita los 
	exit 1          # permisos de administrador y se termina la ejecución.
    fi
}

function parametros {
    if [ "$#" -ne 2 ]  # Si el numero de parametros que nos pasa el usuario es distinto de dos 
    then  # entonces le indicamos al usuario que el numero de parametros es incorrecto y se 
	echo "Numero incorrecto de parametros"  # termina la ejecución. 
	exit 1
    fi

    if [[ "$1" != "-a" && "$1" != "-s" ]]   # En caso de que los atributos que nos 
    then 	#pase no sea -a o -s, le indicamos que no es una opción valida mostrandoselo por
	echo "Opcion invalida" >&2   # la salida de error (stderr) y terminando la ejecución.
	exit 1
    fi
}

function eliminarUsuario {
    mkdir -p /extra/backup      # Nos aseguramos de que el directorio backup existe

    while IFS=, read -r nombre _ _  #Para borrar usuarios, cortamos cada fila del fichero por la 
    do     # primera coma, ya que el resto nos da igual para borrar el usuario y  con -f1 $1 
	if id "$nombre" &>/dev/null   # seleccionamos el primer atributo.
	then
	    dirHome=$(eval echo ~$nombre)  # Obtenemos la ruta del home del usuario de forma segura
	    if [ -d "$dirHome" ]
	    then
	        tar -cf /extra/backup/$nombre.tar "$dirHome" >/dev/null 2>&1
	    fi

	# En primer lugar guardamos el directorio home del usuario que se quiere eliminar, que se
	# encuentra en el fichero /etc/passwd, siendo el sexto parametro de la línea, separados
	# por :. Es por eso que utilizamos cut -d: -f6. Después intentamos crear un tar.gz donde 
	# vamos a comprimir el directorio home del usuario $i. Redireccionamos la salida de error
	# a la salida estandar, ya que la redireccionamos a /dev/null, para que de esta manera 
	# no se muestre ningún mensaje.
	    estado=$?   # Guardamos el estado que ha devuelto el comando tar, para saber si ha 
		    # podido crear correctamente el tar en cuyo caso devolvera 0 o si por lo 
	      # contrario no ha podido crearlo y devuelve 1 o 2 según el manual de tar de ubuntu.
	    if [ $estado -eq 0 ]  # en caso de que lo haya podido crear,
	    then
	        userdel -r "$nombre" >/dev/null 2>&1  # borramos el usuario $i
	    else   # en caso contrario
	        rm -f /extra/backup/$nombre.tar  # borramos el tar.gz, debido a que aun así este se ha creado
	    fi		     # igualmente y hay que borrarlo.
	fi
    done < "$1"
}

function anadirUsuario {
    while IFS=, read -r nombre psswd nomCom  # Mientras podamos leer el fichero que nos pasan
    do     # como parametro,
	if [[ -z "$nombre" || -z "$psswd" || -z "$nomCom" ]]  # Si alguno de los 
	then      # parametros del usuario es vacio, indicamos que es un campo invalido al no
	    echo "Campo invalido"  # contener nada y terminamos la ejecución.
	    exit 1
	fi
	# Obtenemos el uid registrado con awk que permite procesar el archivo /etc/passwd y 
	# obtener la tercera columna, que es en la que se almacena el uid, luego con sort -n
	# ordenamos de forma numerica y con tail -n 1 obtenemos el último valor (el mas alto).
	#uid=$(awk -F: '$3 >=  /etc/passwd | sort -n | tail -n 1)

	#if [ $uid -lt 1815 ]
	#then    #Si el uid mas alto registrado es menor a 1815, se le asigna el valor 1815
	#    uid=$((1815))
	#else   #Si no, se le suma 1 al uid  mas alto registrado ya que no se puede repetir un uid
	#    uid=$(($uid + 1))
	#fi


	# Se crea el usuario, -m crea el directorio home y copia el directorio /etc/skel al
	# directorio home del usuario sin tener que añadir -k.
	# -u asigna el uid al usuario, -U crea un grupo con el mismo nombre que el usuario.

	if id "$nombre" &>/dev/null
	then     # Si el usuario ya existe: (useradd devuelve 9 cuando el usuario ya existe)
	    echo "El usuario $nombre ya existe"
	else  # Si el usuario ha sido añadido corectamente, le asignamos una contraseña
	    useradd -m -k /etc/skel -K UID_MIN=1815 -K PASS_MAX_DAYS=30 -c "$nomCom" -U "$nombre"
	    if [[ $? -eq 0 ]]
	    then
	        echo "${nomCom} ha sido creado"
	        echo "$nombre:$psswd" | chpasswd
		usermod -aG "$nombre"
	    else
		echo "Error al crear el usuario $nombre"
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








