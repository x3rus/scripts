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
DEBUG=1
LOG_DEBUG="/home/xerus/temp_graph/log_kill.log"


########
# MAIN #
########

# get PID of the app
PID_APP=$(ps aux | grep $APP_TO_KILL | grep -v grep | tr -s " " | cut -d " " -f 2)

if [ "$DEBUG" = "1" ] ; then
    echo "---------------------------" >> $LOG_DEBUG 
    date >> $LOG_DEBUG 
    ps aux | grep $APP_TO_KILL >> $LOG_DEBUG 
fi

# If I get a PID send the signal TERM to the app
if [ ! -z $PID_APP ] ; then
    kill $PID_APP &>>$LOG_DEBUG

    if [ "$DEBUG" = "1" ] ; then
        ps aux | grep $APP_TO_KILL >> $LOG_DEBUG 
        echo "----------END------------" >> $LOG_DEBUG    
    fi
fi
