#!/bin/bash
#845107, Tomas, Daniel, M, 3, B
#875325, Martinez, Victor, M, 3, B

if [[ "$#" -ne 3 ]]
then
    exit 1
fi

while read -r ip
do
    nombreMaquina=$(grep "$ip" /etc/hosts | awk '{print $2}')

    ping -c 1 "$ip" 2>/dev/null

    if [[ "$?" -eq 0 ]]
    then
        ssh "nombreMaquina" "$HOME/as/tests_practicas_AS/practica_3/./practica_3.sh $1 $2" 
    else
        echo "$nombreMaquina no es accesible"
    fi

done < "$3"
