#!/bin/bash
#
# Description : 
#   Permet de grapher la temperature du système en relation le load de la 
#   la machine le temps d'utilisation et p-e plus :P
# 
# Auteur : Thomas Boutry
# Licence : GPL v3.
#
###############################################################################

#############
# Variables #
#############
CUR_DATE=$(date +%F)
FILE_GRAPH=temp-$CUR_DATE
DIR_GRAPH=/var/graph-temp
FILE_DATA=info_brut.txt

DEFAULT_INTERVAL=60 # 60 seconde
DEFAULT_OCCURENCE=10 # 10 occurence
########
# MAIN #
########

# Validation presence du rep
if ! [ -w $DIR_GRAPH ]; then
    echo "ERROR: Répertoire $DIR_GRAPH n'existe pas  ou ne peut pas être ecrit"
    exit 1
fi


# Recuperation des arguments ...
# TODO : Prendre en charge les argument pour l'interval et l'occurence , p-e rep et fichier
OCCURENCE=$DEFAULT_OCCURENCE
INTERVAL=$DEFAULT_INTERVAL


for N in $(seq 1 $OCCURENCE) ; do
    # Recuperation des valeurs
    # TODO : peut-etre mettre dans le graphe la vitesse de la FAN 
    TEMPS_CPU_OTHER=$(sensors | egrep 'CPU|Other' | cut -d "+" -f 2 | cut -d "." -f 1 | tr "\n" " ")
    CUR_LOAD_100=$(uptime | tr -s " "  | cut -d " " -f 10 | tr -d "." | tr -d ",")

    # Ecriture dans le fichier
    echo "$N $TEMPS_CPU_OTHER $CUR_LOAD_100" >> $DIR_GRAPH/$FILE_DATA
    sleep $INTERVAL
done


