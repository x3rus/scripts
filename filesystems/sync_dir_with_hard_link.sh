#!/bin/bash
#
# Description : Sync file as hard link to an other directory
#		to be able to do an HardLink both directory
#		must be on the SAME filesysteme !! 
#		and must be a file system with hardlink support
#
#
# Author : Thomas Boutry <xerus@x3rus.com>
#
# TODO :
#	- add exclude tag for some directory
#	- add option to sync file base on a pattern
#	  like *.mp3 or a regex
#	- set the option to pass in parameter 
#	  - directory to sync
#	  - deph of sync
#	  
#
#
########################################################


###############
## VARIABLES ##
###############
DIR_SOURCE=/home/xerus/Musique
DIR_DESTINATION=/home/public/TV/Music
DEPTH=0

###############
## FUNCTIONS ##
###############

# f_create_directory_structure
# 
# Hardlink is only available for regular file not directory 
# so I create directory with mkdir
f_create_directory_structure ()
{
	# Change default internal field separator by default
	# SPACE is a valide separator but some directory have
	# space in the name So I change it for ";"
	OLD_IFS=$IFS
	IFS=";"

	# Find all directory but quote and add ; at the end of all
	# TODO : add depth configuration
	LST_DIR_STRUCTURE=$(find $DIR_SOURCE  -type d  -printf "%P;")
	if [ $? -ne 0 ] ; then
		echo "ERROR: unable to find all directory at the source directory"
		return 1
	fi

	for dir in $LST_DIR_STRUCTURE; do
		# If the directory not already created
		if ! [ -d $DIR_DESTINATION/$dir ]; then
			if ! mkdir "$DIR_DESTINATION/$dir" ; then
				echo "ERROR : Unable to create directory $DIR_DESTINATION/$dir"
				return 1
			fi
		fi
	done

	# Set backup original internal field separator
	IFS=$OLD_IFS
} # END f_create_directory_structure


f_create_hardlink()
{
	# Change default internal field separator by default
	# SPACE is a valide separator but some directory have
	# space in the name So I change it for ";"
	OLD_IFS=$IFS
	IFS=";"

	# Find all directory but quote and add ; at the end of all
	# TODO : add depth configuration
	LST_FILE_TO_SYNC=$(find $DIR_SOURCE  -type f  -printf "%P;")
	if [ $? -ne 0 ] ; then
		echo "ERROR: unable to find file to sync in the source directory $DIR_SOURCE "
		return 1
	fi
	
	for file2sync in $LST_FILE_TO_SYNC ; do
		# If the File not already exist link it
		if ! [ -f $DIR_DESTINATION/$file2sync ] ; then
			if ! ln "$DIR_SOURCE/$file2sync" "$DIR_DESTINATION/$file2sync" ; then
				echo "ERROR : Unable to create file hardlink $DIR_DESTINATION/$file2sync"
				return 1
			fi
		fi 
	done

	
	# Set backup original internal field separator
	IFS=$OLD_IFS
} # END f_create_hardlink

##########
## MAIN ##
##########

if f_create_directory_structure ; then
	
	if f_create_hardlink ; then
		exit 0
	else
		exit 1
	fi
else
	exit 1
fi
