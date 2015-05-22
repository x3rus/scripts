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
CUR_DATE=$(date +%F-%H-%M)
FILE_GRAPH=temp-$CUR_DATE
DIR_GRAPH=$HOME/temp_graph
FILE_DATA=raw_temp_graph-$CUR_DATE
FILE_GRAPH=temp_graph-$CUR_DATE.png

DEFAULT_INTERVAL=60 # 60 seconde
DEFAULT_OCCURENCE=10 # 10 occurence

# Graph information
GRAPH_TITLE="CPU temp, Other temp, Load average, RPMS Fan"
GRAPH_X_LABEL="Time earch $INTERVAL secs" 
GRAPH_Y_LABEL="Y"
GRAPH_PNG_SIZE="800,600"

############
# Funtions #
############

f_usage () {
    # Show help message
    echo "  usage : $0 [-c num] [-i num] [-d dir_path] [-b brut_file] [-o png_filename] "
    echo " "
    echo " Script to extract information from sensors and create a graph with GNUPlot"
    echo " it extract CPU temp, Other Temp, Load average * 100 , Fan RPMS * 100 "
    echo " The script work on a Dell D430 with archLinux, You probably need change "
    echo " some line to extract information for your system "
    echo " "
    echo " Options: "
    echo "      -c num : Number of data extraction. (DEFAULT : 10)"
    echo "               Use 0 for unlimited "
    echo "      -i num : The delay between updates in seconds. (DEFAULT : 60 sec)"
    echo '      -d dir_path : Directory use to store temporary file and png graphe (DEFAULT : $HOME/temp_graph'
    echo '      -b brut_file: Filename to store information (DEFAULT : raw_temp_graph-$DATE)'
    echo '      -o png_file: Filename generate by GNUPlot (DEFAULT : temp_graph-$DATE.png)'
    echo '      -h : Show this message'
    echo '  All files are store in the dir_path '

} # end f_usage

f_do_graph () {

    # Check if we have some data to perform the graph
    if [ -s ${DIR_GRAPH}/${FILE_DATA} ]; then
        # Output graph 
        gnuplot <<- EOF
                set title "${GRAPH_TITLE} \n ${CUR_DATE}"
                set xlabel "${GRAPH_X_LABEL}"
                set ylabel "${GRAPH_Y_LABEL}"
                set terminal png size ${GRAPH_PNG_SIZE}
                set output "${DIR_GRAPH}/${FILE_GRAPH}"
                plot "${DIR_GRAPH}/${FILE_DATA}" using 2 title 'CPU temp' with lines, \
                     "${DIR_GRAPH}/${FILE_DATA}" using 3 title 'Other temp' with lines, \
                     "${DIR_GRAPH}/${FILE_DATA}" using 4 title 'Fan RPMS (/100)' with lines, \
                     "${DIR_GRAPH}/${FILE_DATA}" using 5 title 'Load (*100)' with lines
EOF

        if [ $? -ne 0 ] ; then
            echo "ERROR: An error occur when the script create the graph ${DIR_GRAPH/$FILE_GRAPH} "
            echo "ERROR: I hope raw data is ok ... please check "
        fi # End validation return code gnuplot

    fi # End if [ -s ${DIR_GRAPH}/${FILE_DATA} ]

    exit

} # end f_do_graph

########
# MAIN #
########

# Set Default Value
OCCURENCE=$DEFAULT_OCCURENCE
INTERVAL=$DEFAULT_INTERVAL

####################
# script arguments #

while getopts :c:i:d:b:o:h FLAG; do
    case $FLAG in
        c)  # set number of data extraction
            if [ $OPTARG -ge 0 ] ; then
                OCCURENCE=$OPTARG
            else
                echo "ERROR: argument error you must give an interger"
                f_usage
                exit 1
            fi
            ;;
        i)  # set time between each occurence  
            if [ $OPTARG -ge 0 ] ; then
                INTERVAL=$OPTARG
            else
                echo "ERROR: argument error you must give an interger"
                f_usage
                exit 1
            fi
            ;;
        d)  # set directory where file are located
            DIR_GRAPH=$OPTARG
            ;;
        b)  # set raw data file name
            FILE_DATA=$OPTARG
            ;;
        o)  # set graph file name
            FILE_GRAPH=$OPTARG
            ;;
        h)  # show help message
            f_usage
            exit 1
            ;;
        \?) #unrecognized option - show help
            echo "ERROR: option used not reconized , please read usage "
            f_usage
            exit 1
            ;;
    esac # end case opts
done # End while getopts

# TODO : Ajouter de la validation sur les arguments
# Validation presence du rep
if ! [ -w $DIR_GRAPH ]; then
    echo "ERROR: Répertoire $DIR_GRAPH n'existe pas  ou ne peut pas être ecrit"
    exit 1
fi


# Trap Signal sent to the script If the user press CTRL+C the script will
# create the final graph , it's useful when you run it infinitly with option -c 0
# Ref: http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html
trap f_do_graph SIGHUP SIGINT SIGTERM

# Loop , I use while true , because if you set the option the OCCURENCE to 0
# the graph will loop infinitly
ITERATOR=1
while (true) ; do
    # Extract data from sensors, maybe for other system change this part
    TEMPS_CPU_OTHER=$(sensors | egrep 'CPU|Other' | cut -d "+" -f 2 | cut -d "." -f 1 | tr "\n" " ")
    CUR_LOAD_100=$(uptime | tr -s " "  | cut -d " " -f 10 | tr -d "." | tr -d ",")
    # RPM fan / 100
    FAN_RPMS=$(( $(sensors | grep Fan | cut -d " " -f 3) / 100 ))

    # Write to data file
    echo "$ITERATOR $TEMPS_CPU_OTHER $FAN_RPMS $CUR_LOAD_100" >> $DIR_GRAPH/$FILE_DATA


    if [ $OCCURENCE -gt 0  -a $ITERATOR -ge $OCCURENCE ]; then
        break
    else
        # Increase iterator
        ITERATOR=$(( $ITERATOR + 1 ))
    fi

    sleep $INTERVAL
done

# Create graph 
f_do_graph


