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
# TODO: 
#	- Voir pour mettre du parallellisme des processus.
#	- Voir pour mieux générer le graphe .
#	- Voir pour faire un rapport HTML plus beau 
#############################################################

#################
### Variables ###
#################
PERIOD=$1
DIR_CONF_BK_FILE=/etc/rsnapshot/hosts
BKRUNNER=/usr/local/sysadmin/backup/backup_runner.sh
BKREPORT=/usr/local/sysadmin/backup/rsnapreport.pl
RRDFILE=/var/lib/rrd/time_for_backup.rrd
GRAPHFILE=/tmp/backuptime.png
NUMDAY=`date +%u`
D_DATE=`date +%F`

# Mail Configuration 
MAILADMINS="sysadmin_x3rus@x3rus.com"
MAILFROM="root"
MAILSUBJECT=" X3rus Backup $D_DATE : "
MAILSUBJECT_STATUS=" Success"
MAILAPP=/usr/local/sysadmin/backup/html-email-sender.py

# File Temporaire
TMPFILE_RSYNC_RUN=`mktemp`
TMPFILE_RSYNC_REPPORT=`mktemp`
TMPFILE_RSYNC_FULL_REPPORT=`mktemp`


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


##############
#### MAIN ####
##############

echo ${PERIOD} | egrep 'hourly|daily|weekly|monthly' 2>&1 >/dev/null

if [ $? -ne 0 ]; then
        echo "ERROR: Bad period value. Available values are <hourly|daily|weekly|monthly>."
	rm $TMPFILE_RSYNC_RUN
	rm $TMPFILE_RSYNC_REPPORT
	rm $TMPFILE_RSYNC_FULL_REPPORT
        exit 1
fi

# Start backup for each system listed in the $DIR_CONF_BK_FILE

echo " " >> $TMPFILE_RSYNC_REPPORT
echo " <b>Realisation du backup sur disques  : </b> <br> " >> $TMPFILE_RSYNC_REPPORT
echo " <b> ------------------------------------ </b> <br> " >> $TMPFILE_RSYNC_REPPORT
echo "<tt><pre>" >> $TMPFILE_RSYNC_REPPORT

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
	printf "<i>Backup performed in: %02d:%02d:%02d:%02d </i> \n" "$((TIMER_BK_host/86400))" "$((TIMER_BK_host/3600%24))" "$((TIMER_BK_host/60%60))" "$((TIMER_BK_host%60))" >> $TMPFILE_RSYNC_REPPORT
done

TIMER_BK_all_host="$(($(date +%s)-TIMER_BK_all_host))"
echo "<br>" >> $TMPFILE_RSYNC_REPPORT
printf "<i>Backup of Hosts is realise in: %02d:%02d:%02d:%02d </i> \n" "$((TIMER_BK_all_host/86400))" "$((TIMER_BK_all_host/3600%24))" "$((TIMER_BK_all_host/60%60))" "$((TIMER_BK_all_host%60))" >> $TMPFILE_RSYNC_REPPORT
echo "</pre></tt> <br>" >> $TMPFILE_RSYNC_REPPORT

rm $TMPFILE_RSYNC_RUN

# Update RRD Graphique
if [ -f $RRDFILE ]; then
    TIMER_BK_all_host_MINS=$(($TIMER_BK_all_host/60%60))
    /usr/bin/rrdtool update $RRDFILE $(date +%s):$TIMER_BK_all_host_MINS 
    echo "/usr/bin/rrdtool update $RRDFILE $(date +%s):$TIMER_BK_all_host_MINS" >> /tmp/rrdtool-cmd
    if [ $? -ne 0 ]; then
	    echo "ERROR : When system try to update the rrd file <br>  " >> $TMPFILE_RSYNC_REPPORT
    else
	/usr/bin/rrdtool graph $GRAPHFILE --start -2w --vertical-label "Minutes"  --title "backup time"   DEF:TimeBackup=$RRDFILE:backupTime:LAST  LINE2:TimeBackup#FF0000 &>/dev/null
	echo "<br> " >> $TMPFILE_RSYNC_REPPORT
	echo " <b> Graphique Temps utiliser pour les backups </b> <br>  " >> $TMPFILE_RSYNC_REPPORT
	echo " <img src=\"cid:graph1\"> <br>  " >> $TMPFILE_RSYNC_REPPORT
    fi
else
    echo " ERROR: Unable to update the rrd file for the graphic, file unavelable !! <br> " >> $TMPFILE_RSYNC_REPPORT
	
fi

# Feed Backup local in the FULL backup
cat $TMPFILE_RSYNC_REPPORT >> $TMPFILE_RSYNC_FULL_REPPORT
rm $TMPFILE_RSYNC_REPPORT


f_send_mail
rm $TMPFILE_RSYNC_FULL_REPPORT
