#!/bin/bash
#
# Description : Script qui réalise l'ensemble des backups les un à la suite des autres
#		le script démarre donc le premier backup en prenant le fichier dans le
#		répertoire DIR_CONF_BK_FILE. Une fois le backup terminé il traite le
#		suivant. L'ensemble des backups une fois terminé un courriel est transmit
#		avec un rapport de l'opération et un graphe du temps passe
#		Le rapport de backup est formater en HTML
#
#
# Auteur  : Thomas.boutry <thomas.boutry@x3rus.com>
# Date    : 2013-07-07
# Licence : GPL v3
#
#############################################################

#################
### Variables ###
#################
PERIOD=$1
#CONF_FILE=/usr/local/sysadmin/backup/FullBackup.conf
CONF_FILE=/home/xerus/git/scripts/backup-scripts/rsnapshot/FullBackup.conf

# Load configuration file
if [ -f $CONF_FILE ] ; then
    . $CONF_FILE
else
    echo "ERROR: Configuration file don't exist please fix it "
    echo "ERROR: Script look for the file $CONF_FILE "
    exit 1
fi


################
### Function ###
################
f_send_mail()
{
	for mail in $MAILADMINS
	do
		cat $TMPFILE_RSYNC_FULL_REPPORT  | $MAILAPP -s "$MAILSUBJECT $MAILSUBJECT_STATUS" -f "$MAILFROM" -t "$MAILADMINS" -i "{'graph1':\"$GRAPHFILE\"}"
	done
} # f_send_mail

f_cleanup(){
    # Clean up temporary files 
    if [ -f $TMPFILE_RSYNC_RUN ] ;then
    	rm $TMPFILE_RSYNC_RUN
    fi
	if [ -f  $TMPFILE_RSYNC_REPPORT ] ; then
    	rm $TMPFILE_RSYNC_REPPORT
    fi
	if [ -f $TMPFILE_RSYNC_FULL_REPPORT ]; then
    	rm $TMPFILE_RSYNC_FULL_REPPORT
    fi

    exit
} # end f_cleanup

##############
#### MAIN ####
##############

if ! echo ${PERIOD} | egrep -q 'hourly|daily|weekly|monthly' ; then
    echo "ERROR: Bad period value. Available values are <hourly|daily|weekly|monthly>."
    f_cleanup
    exit 1
fi

echo " " >> $TMPFILE_RSYNC_REPPORT
echo " <b>$MSG_H1_TXT_BK_ON_HD  : </b> <br> " >> $TMPFILE_RSYNC_REPPORT
echo " <b>$MSG_LINE </b> <br> " >> $TMPFILE_RSYNC_REPPORT
echo "<tt><pre>" >> $TMPFILE_RSYNC_REPPORT

# trap exit to run Clean up function
trap f_cleanup SIGHUP SIGINT SIGQUIT SIGABRT SIGKILL SIGALRM SIGTERM

# TODO Voir pour faire du parallelisme pour uptimiser le temps de backup
# Start backup for each system listed in the $DIR_CONF_BK_FILE
TIMER_BK_all_host="$(date +%s)"
for host in $DIR_CONF_BK_FILE/*.conf
do

	TIMER_BK_host="$(date +%s)"
	$BKRUNNER $host $PERIOD	 > $TMPFILE_RSYNC_RUN
	BKRUNNER_RESULTAT=$?
	cat $TMPFILE_RSYNC_RUN | $BKREPORT  >> $TMPFILE_RSYNC_REPPORT
	if [ $BKRUNNER_RESULTAT -ne 0 ]; then
		MAILSUBJECT_STATUS=" Sync Prob "
		cat $RSNAPSHOT_ERROR_SYNC  >> $TMPFILE_RSYNC_REPPORT
	fi 
	TIMER_BK_host="$(($(date +%s)-TIMER_BK_host))"
	printf "<i>$MSG_BK_PERFORME_IN:%02d:%02d:%02d:%02d </i> \n" "$((TIMER_BK_host/86400))" "$((TIMER_BK_host/3600%24))" "$((TIMER_BK_host/60%60))" "$((TIMER_BK_host%60))" >> $TMPFILE_RSYNC_REPPORT
done

TIMER_BK_all_host="$(($(date +%s)-TIMER_BK_all_host))"
echo "<br>" >> $TMPFILE_RSYNC_REPPORT
printf "<i>$MSG_BK_HOST_PERFORME_IN: %02d:%02d:%02d:%02d </i> \n" "$((TIMER_BK_all_host/86400))" "$((TIMER_BK_all_host/3600%24))" "$((TIMER_BK_all_host/60%60))" "$((TIMER_BK_all_host%60))" >> $TMPFILE_RSYNC_REPPORT
echo "</pre></tt> <br>" >> $TMPFILE_RSYNC_REPPORT

# Check if the rrdfile exist try to create it #
if [ ! -f $RRDFILE ]; then
    /usr/bin/rrdtool create $RRDFILE --start $(date +%s) --step 86400 DS:backupTime:GAUGE:172800:0:1440 RRA:LAST:0.5:1:14

    # Ajout d'une petite seconde afin de ne pas avoir l'erreur :
    #  illegal attempt to update using time 1432727939 when last update time is 1432727939 (minimum one second step)
    sleep 2 
    if [ $? -ne 0 ] ; then
        echo "ERROR: Unable to create the rrdfile"
    fi
fi

# TODO Voir pour faire le graphique avec gnuplot
#      l'idee serai d'avoir plus de graphe par host p-e par repertoire sur une longue periode
if [ -f $RRDFILE ]; then
# Update RRD Graphique
    TIMER_BK_all_host_MINS=$(($TIMER_BK_all_host/60%60))
    /usr/bin/rrdtool update $RRDFILE $(date +%s):$TIMER_BK_all_host_MINS 
    echo "/usr/bin/rrdtool update $RRDFILE $(date +%s --date='1 day ago'):$TIMER_BK_all_host_MINS" >> /tmp/rrdtool-cmd
    if [ $? -ne 0 ]; then
	    echo "ERROR : When system try to update the rrd file <br>  " >> $TMPFILE_RSYNC_REPPORT
    else
	/usr/bin/rrdtool graph $GRAPHFILE --start -2w --vertical-label "Minutes"  --title "backup time"   DEF:TimeBackup=$RRDFILE:backupTime:LAST  LINE2:TimeBackup#FF0000 &>/dev/null
	echo "<br> " >> $TMPFILE_RSYNC_REPPORT
	echo " <b> $MSG_GRAPHIC_HEADER</b> <br>  " >> $TMPFILE_RSYNC_REPPORT
	echo " <img src=\"cid:graph1\"> <br>  " >> $TMPFILE_RSYNC_REPPORT
    fi
else
    echo " ERROR: Unable to update the rrd file for the graphic, file unavelable !! <br> " >> $TMPFILE_RSYNC_REPPORT
	
fi

# Feed Backup local in the FULL backup
cat $TMPFILE_RSYNC_REPPORT >> $TMPFILE_RSYNC_FULL_REPPORT


f_send_mail
f_cleanup
