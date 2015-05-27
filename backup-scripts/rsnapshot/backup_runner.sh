#!/bin/sh
#
# Description : Wrapper pour l'appel du script rsnapshot , ce script réalise 
#	 	la validation de paramettre une fois le backup terminé il 
#		affiche a l'écran le résultat du backup
#
# Auteur  : Thomas.boutry <xerus@x3rus.com>
# Date    : 2013-07-07
# Licence : GPL v3
# 
############################################

umask 022
PATH="/bin:/usr/bin:/usr/local/bin"
export PATH

if [ $# -ne 2 ]; then
        echo "Usage: $0 <configuration_file> <hourly|daily|weekly|monthly>"
        echo "Ex: $0 /etc/rsnapshot/hosts/fuseki.x3rus.com.conf daily"
        exit
fi

CONFIG_FILE=$1
PERIOD=$2

if [ ! -f ${CONFIG_FILE} ]; then
        echo "ERROR: Could not find ${CONFIG_FILE}."
        exit 1
fi

if ! echo ${PERIOD} | egrep -q 'hourly|daily|weekly|monthly' ; then
        echo "ERROR: Bad period value. Available values are <hourly|daily|weekly|monthly>."
        exit 1
fi

# Check if this script is running by root.
if [ `id -u` -ne 0 ]; then
        echo "ERROR: You must be root to execute this script."
        exit 1
fi
# Check if this script is running by root.
if [ `id -u` -ne 0 ]; then
        echo "ERROR: You must be root to execute this script."
        exit 1
fi

# Check if rsnapshot is available and executable.
if [ ! -x `which rsnapshot` ]; then
        echo "ERROR: Could not locate rsnapshot."
        exit 1
fi

# Run the the backup and redirect the output and errors on /dev/null.
rsnapshot -c ${CONFIG_FILE} -v ${PERIOD} > /tmp/rsnap-out.$$ 2>&1
RSNAPSHOT_RETURN_CODE=$?

cat /tmp/rsnap-out.$$  

# Remove the the rsnapshot output.
rm /tmp/rsnap-out.$$   

exit $RSNAPSHOT_RETURN_CODE

# EOF
