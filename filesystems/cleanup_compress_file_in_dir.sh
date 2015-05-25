#!/bin/bash
#
#   Description : Compresse et supprime des fichiers dans un repertoire fournie
#               en parametre. La rotation peut etre recursive sur plusieurs 
#               niveau , ceci est parametrable. L'age des fichiers a 
#               supprimer est passable en parametre ainsi que le nombre de 
#               fichier a ne pas compresser.
#
#   Auteur : Boutry Thomas <thomas.boutry@x3rus.com>
#   Licence : GPL v3 
#
###############################################################################

#############
# Variables #
#############

LOCK_FILE=/var/lock/$(basename $0).lock     # Fichier lock pour ne pas avoir 2 
                                            # script qui roule en meme temps

MAX_FILES_AGE=60 			                # nombre en jours de conservation 
                                            # des fichiers
NUM_FILE_NOT_COMPRESSE=2		            # nombre de jours des fichiers nom
                                            # compressé, le système va donc
					                        # conserver X jour sans compresse 
                                            # le fichier
PATH_DIR_HOST=""			                # Path racine ou les répertoires 
                                            # des systèmes sont stocké
MAX_DEPTH="" 				                # Profondeur de traitement des 
                                            # fichiers dans le répertoire donnee
PATERN_FILE="*.log" 			            # Pattern pour le traitement des 
                                            # fichiers qui seront manipuler.

#############
# Functions #
#############

f_cleanup (){

	# Delete LOCK file
	if [ -f $LOCK_FILE ] ; then
		rm $LOCK_FILE
	fi
} # END f_cleanup

f_rotate_logs_file ()  {

	# recuperation de l'argument
	REP_TO_ROTATE=$1

	# une double validation ca ne fait pas de mal.
	if ! [ -d $REP_TO_ROTATE ]; then
		echo "ERROR : $REP_TO_ROTATE not a directory, unable to rotate files"
		return 1
	fi

	if [ "$MAX_DEPTH" != "" ] ; then
		EXTRA_ARG="$EXTRA_ARG -maxdepth $MAX_DEPTH"
	fi

	# recuperation de la listes des vieux fichiers plus vieux de $MAX_FILES_AGE 
    # et suppression encore une validation que le fichier est une fichier 
    # régulier et qu'il a l'extention .log.
	find $REP_TO_ROTATE $EXTRA_ARG -type f -name "$PATERN_FILE" -ctime +$MAX_FILES_AGE -exec rm {} \; 
	# Compression des fichiers tous en conservant les plus recent non-compresser.
	find $REP_TO_ROTATE $EXTRA_ARG -type f -name "$PATERN_FILE" -mtime +$NUM_FILE_NOT_COMPRESSE -exec gzip {} \; 



} # END f_rotate_logs_file

f_usage () {
	echo " Process a directory to delete and compress file in it "
	echo "Usage: "
	echo " $0 -d PATH [-k numDay] [-u numDay] [-r RecursiveNum] [-p pattern_file] [-h]"
	echo ""
	echo " Options description : "
	echo " 		-d  Directory 	 : Directory PATH to process "
	echo " 		-k  numDay 	 : Delete file old than numDay , so keep file with maximum day old"
	echo " 		    default 	 : 60 "
	echo " 		-u  numDay  	 : Keep file uncompress , if they less older then numDay "
	echo " 		    default 	 : 2 "
	echo " 		-r  RecursiveNum : Set the Max depth in the directory "
	echo " 		-p  pattern_file : Perform file manipulation only on file with pattern "
	echo " 		    default 	 : *.log"
	echo " 		-h  		 : Show this message "
} # END f_usage

#############
#   MAIN    #
#############

# Trap les signaux  Interrupt,Terminate et exit afin de realiser le clean up des fichiers temporaire.
trap f_cleanup INT TERM EXIT

if [ $# -lt 1 ] ; then
	f_usage 
	exit 1	
fi

#### Traitement Parametre ####
while getopts "hd:k:u:r:p:" optname; do
    case "$optname" in
      "d")
        PATH_DIR_HOST=${OPTARG}
        ;;
      "k")
        # Validation de la variable que c'est uniquement un chiffre http://mywiki.wooledge.org/BashFAQ/054
    	if [[ ${OPTARG} != *[!0-9]* ]]; then
	    	MAX_FILES_AGE=${OPTARG}
	    else
		    echo "ERROR : -k variable must be a number "
    		echo "$0 -h  , for more information "
	    	exit 1
	    fi
        ;;
      "u")
        # Validation de la variable que c'est uniquement un chiffre http://mywiki.wooledge.org/BashFAQ/054
	    if [[ ${OPTARG} != *[!0-9]* ]]; then
		    NUM_FILE_NOT_COMPRESSE=${OPTARG}
    	else
	    	echo "ERROR : -u variable must be a number "
		    echo "$0 -h  , for more information "
    		exit 1
	    fi
        ;;
      "r")
        # Validation de la variable que c'est uniquement un chiffre http://mywiki.wooledge.org/BashFAQ/054
    	if [[ ${OPTARG} != *[!0-9]* ]]; then
	    	MAX_DEPTH=${OPTARG}
    	else
	    	echo "ERROR : -r variable must be a number "
		    echo "$0 -h  , for more information "
    		exit 1
    	fi
        ;;
      "p")
		PATERN_FILE=${OPTARG}
        ;;
      "h")
        f_usage
	    exit 0
        ;;
      *)
        # Should not occur
        echo " Error with Argument " 
    	f_usage
	    exit 1
        ;;
    esac
done

# Validation que la variable $PATH_DIR_HOST n'est pas vide 
# de plus que la valeur n'est pas / mais qqc sous /var
if [ "$PATH_DIR_HOST" == "" ] ; then
	echo "ERROR : The variable PATH_DIR_HOST is empty it's not possible , fix it "
	exit 1
fi	

# Validation que la valeur n'est pas / uniquement mais sous le répertoire /var au minimum
if echo $PATH_DIR_HOST | grep -q ^/$ ; then
	echo "ERROR : The variable PATH_DIR_HOST don't define a path with only the / but a directory"
	exit 1
fi	

# Creation d'un fichier de lock pour eviter que 2 script roule en meme temps
if [ -f $LOCK_FILE ] ; then
	echo "ERROR : Script already running or Lock file ($LOCK_FILE) steel exist"
	exit 1
fi

# creation du fichier de Lock
touch $LOCK_FILE

# Valide que le fichier est bien un répertoire
if [ -d $PATH_DIR_HOST ] ; then
	f_rotate_logs_file $PATH_DIR_HOST
else
	echo "ERROR : Variable \$PATH_DIR_HOST is not a directory"
	echo " $PATH_DIR_HOST "
	exit 1
fi


# clean up les fichiers temporaire.
f_cleanup 

# Aucune erreur fin , desactive le trap et exit le script
trap - INT TERM EXIT
exit 0
