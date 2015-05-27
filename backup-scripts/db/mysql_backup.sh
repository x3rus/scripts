#!/bin/bash
#
# Version 0.1
# 
# Autheur : Thomas Boutry <xerus@x3rus.com>
#
# Description :  Réalise un backup de la Base de donnée Mysql dans un répertoire donne
# Les fichiers seront overwriter a chaque fois ce script a pour but d'etre utiliser
# avec rsnapshot .
#
# Utilisateur Backup creer dans mysql : 
# GRANT LOCK TABLES, SELECT, FILE, RELOAD, SUPER   ON *.* TO 'dba-backup'@'localhost' IDENTIFIED BY '*****'
#
# Pour un système de backup mysql avec rotation voir :
# Projet : AutoMysqlBackup
# URL    : http://sourceforge.net/projects/automysqlbackup/
#############################################

# Variables
BACKUP_DIR=$1

# Backup user
BACKUP_USER=dba-backup
BACKUP_PASSWD=B4ckupDB4haha


# Function

f_usage() {
    echo "usage :  "
    echo "	 $0 Path_where_to_backup "
} # f_usage

# Main


# Validation de la variable 
if [ "$BACKUP_DIR" == "" ]; then
	echo "Error, You need to passe the backup directory in argument"
	f_usage
	exit 1
fi

if ! [ -d $BACKUP_DIR ] ; then
	echo  " Error , Argument not a directory "
	f_usage
	exit 1
fi

if ! [ -w $BACKUP_DIR ] ; then
	echo "Error , don't have permission to write in $BACKUP_DIR "
	f_usage
	exit 1
fi

# Get databases  name
LST_DBS=`mysql -u $BACKUP_USER --password=$BACKUP_PASSWD --silent -e 'show databases' | egrep -v 'Database|information_schema'`

# Backup each BD
for db in $LST_DBS; do
   mysqldump -u $BACKUP_USER --password=$BACKUP_PASSWD --database $db | gzip  > $BACKUP_DIR/$db.sql.gz
done

# Make a full
mysqldump -u $BACKUP_USER --password=$BACKUP_PASSWD  --all-databases | gzip  > $BACKUP_DIR/full.sql.gz

