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
DEFAULT_OCCURENCE=120 # 10 occurence

############
# Funtions #
############

f_usage () {
    echo "  usage : $0 [-c num] [-i num] [-d dir_path] [-b brut_file] [-o png_filename] "
    echo " "
    echo " Script to extract information from sensors and create a graph with GNUPlot"
    echo " it extract CPU temp, Other Temp, Load average * 100 , Fan RPMS * 100 "
    echo " The script work on a Dell D430 with archLinux, You probably need change "
    echo " some line to extract information for your system "
    echo " "
    echo " Options: "
    echo "      -c num : Number of data extraction. (DEFAULT : 10)"
    echo "      -i num : The delay between updates in seconds. (DEFAULT : 60 sec)"
    echo '      -d dir_path : Directory use to store temporary file and png graphe (DEFAULT : $HOME/temp_graph'
    echo '      -b brut_file: Filename to store information (DEFAULT : raw_temp_graph-$DATE)'
    echo '      -o png_file: Filename generate by GNUPlot (DEFAULT : temp_graph-$DATE.png)'
    echo '  All files are store in the dir_path '

} # end f_usage

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
    # Vitesse de la fan / 100
    FAN_RPMS=$(( $(sensors | grep Fan | cut -d " " -f 3) / 100 ))

    # Ecriture dans le fichier
    echo "$N $TEMPS_CPU_OTHER $FAN_RPMS $CUR_LOAD_100" >> $DIR_GRAPH/$FILE_DATA
    sleep $INTERVAL
done


