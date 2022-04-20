# !/bin/bash

# Programa que permite manejar las utilidades de PostgreSQL.

# Autor: Nicolás Cabrera  nicocabrera.0212@gmail.com

opcion=0
fechaActual=$(date +Y%m%d)


# Funcion Intalar Postgres.
instalar_postgres () {
	echo -e "\n verificando si existe Postgres"
	verifyInstall=$(which psql)
	if [ $? -eq 0 ]; then
		echo  -e " Postgres ya se encuentra instalado en su maquina"
	else
		read -s -p "Ingresar contraseña sudo: " passwordSudo
		echo -e "\n"
		read -s -p "Ingresar contraseña a utilizar en Postgres: " passwordPostgres
		echo -e "\n"
		echo "$passwordSudo" | sudo -S apt update 
		echo "$passwordSudo" | sudo -S apt-get -y install postgresql postgresql-contrib
		sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '{$PASSWORDpOSTGRES}'; "	
		echo "$passwordSudo" | sudo -S systemctl enable postgresql.service
		echo "$passwordSudo" | sudo -S systemctl start postgresql.service
	fi
	read -n 1 -s -r -p "PRESIONE [ENTER] para continuar..."


}

# Funcion desinstalar Postgres.

desinstalar_postgres () {
	read -s -p "Ingresar contraseña sudo: " password_sudo
	echo "$password_sudo" | sudo -S systemctl stop postgresql.service
	echo "$password_sudo" | sudo -S apt-get -y --purge remove postgresql\* 
	echo "$password_sudo" | sudo -S rm -r /etc/postgresql  
	echo "$password_sudo" | sudo -S rm -r /etc/postgresql-common  
	echo "$password_sudo" | sudo -S rm -r /var/lib/postgresql  
	echo "$password_sudo" | sudo -S userdel -r postgres  
	echo "$password_sudo" | sudo -S groupdel  postgres 
	
	read -n 1 -s -r -p "PRESIONE [ENTER] para continuar..."
}

# Funcion de respaldo.

respaldar () {
	read -s -p "Ingresar contraseña sudo: " password_sudo
	echo -e "Listar las Bases de Datos \n"
	sudo -u postgres psql -c "\l"
	read -p "Elegir la Base de Datos a respaldar: " bddRespaldo
	echo -e "\n"

	if [ -d "$1" ]; then
		echo "Estableciendo permisos al directorio"
		echo "$password_sudo" | sudo -S chmod 755 $1
		echo "Realizando Respaldo..."
		sudo -u postgres pg_dump -Fc $bddRespaldo > "$1/bddRespaldo$fechaActual.bak"
		echo "Respaldo realizado correctamente en la ubicacion: $1/bddRespaldo$fechaActual.bak"
	else
		echo "el directorio $1 no existe"
	fi
	read -n 1 -s -r -p "PRESIONE [ENTER] para continuar..."

}

# Funcion para restaurar respaldo
restaurar () {
	echo -e "Lista Respaldos \n"
	read -p "Ingresar el directorio donde estan los respaldos: " directorioBackup
	ls -la $directorioBackup
	read -p "Elegir el respaldo a restaurar: " respaldoRestaurar
	echo -e "\n"
	read -p "Ingrese el nombre de la base de datos destino: " dbDestino
	echo -e "\n Verificando si la Base de datos existe"
	verifyBD=$(sudo -u postgres psql -lqt | cut-d|-f 1  | grep -wq $dbDestino)
	if [ $? -eq 0 ]; then
		echo "Restaurando en la base de datos destino : $dbDestino"
	else
		sudo -u postgres psql -c "create database $dbDestino"
	fi

	if [ -f "$1/$respaldoRestaurar" ]; then
		echo "Restaurando Respaldo..."
		sudo -u postgres pg_restore -Fc -d $dbDestino "$directorioBackup/$respaldoRestaurar"
		echo "Lista Bases de Datos"
		sudo -u postgres psql -c "-l"
	else 
		echo "El respaldo $respaldoRestaurar no existe"
	fi
	read -n 1 -s -r -p "PRESIONE [ENTER] para continuar..."

}


while :
do
	#limpiar la pantalla
	clear
	#desplegar el menu de opciones
	echo "___________________________________"
	echo "Programa de utilidad de  PostgreSQL"
	echo "___________________________________"
	echo "          Menu Principal"
	echo "___________________________________"
	echo "1. Instalar Postgres"
	echo "2. Desinstalar Postgres"
	echo "3. Sacar un respaldo"
	echo "4. Restar respaldo"
	echo "5. Salir"

	#Leer los datos del usuario - Capturar informacion.

	read -n1 -p "Ingrese una opcion (1-5) " opcion

	#Validar la opcion ingresada

	case $opcion in
		1) 
			instalar_postgres 
			;;
		2) 
			desinstalar_postgres
			;;
		3)
			read -n5 -p "Directorio Backup " directorioBackup
            		sacar_respaldo $directorioBackup
            		sleep 3
			;;
		4)
			read -p "Directorio de Respaldo: " directorioRespaldo
			restaurar $directorioRespaldo
			;;


		5)
			echo "	Saliendo..."
			sleep 3
			exit 0
			;;
	esac
done
