#!/bin/bash
#
# Description : 
#   FR:
#   EN:
#
# Auteur : Thomas Boutry
# Licence : GPL v3.
#
###############################################################################


#############
# Variables #
#############
APP_TO_KILL="graph-temp.sh"


########
# MAIN #
########

# get PID of the app
PID_APP=$(ps aux | grep $APP_TO_KILL | grep -v grep | tr -s " " | cut -d " " -f 2)

# If I get a PID send the signal TERM to the app
if [ ! -z $PID_APP ] ; then
    kill $PID_APP
fi
