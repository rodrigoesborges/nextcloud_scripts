#!/bin/bash

# Path to your occ command.
# E.g. /var/www/nextcloud/occ
COMMAND=/var/www/nextcloud/occ

# # Possible options:
#  preview:pre-generate - to generate preview to all NEW files
#  preview:generate-all - to rescan whole system and generate previews 
OPTIONS="preview:pre-generate"
#OPTIONS="preview:generate-all"

# # use to see all touched files
# Possible values (e.g. Debug level) -v, -vv, -vvv.
#DEBUG="-vvv"

# Path to NC log file
LOGFILE=/var/www/nextcloud/data/nextcloud.log

# Optional:
# Path to log file for this script
CRONLOGFILE=/var/log/next-cron.log

# Your PHP location if differnt
PHP=/usr/bin/php

### Please do not touch under this line ###

LOCKFILE=/tmp/nextcloud_preview

if [ -f "$LOCKFILE" ]; then
	# Remove lock file if script fails last time and did not run more then 10 days due to lock file.
	find "$LOCKFILE" -mtime +10 -type f -delete
	echo "WARNING - Other instance is still active, exiting." >> $CRONLOGFILE
	exit 1
fi

# Check if OCC is reacheble
if [ ! -w "$COMMAND" ]; then
	echo "ERROR - Command $COMMAND not found. Make sure taht path is corrct."
	exit 1
else
	if [ "$EUID" -ne "$(stat -c %u $COMMAND)" ]; then
		echo "ERROR - Command $COMMAND not executable for current user.
	Make sure that user has right to execute it.
	Script must be executed as $(stat -c %U $COMMAND)."
		exit 1
	fi
fi

# Check if php is executable
if [ ! -x "$PHP" ]; then
	echo "ERROR - PHP not found, or not executable."
	exit 1
fi

# Check if NC Log file is writable
if [ ! -w "$LOGFILE" ]; then
	echo "WARNING - could not write to Log file $LOGFILE, will drop log messages. Is User Correct? Current log file owener is $(stat -c %U $LOGFILE)"
	LOGFILE=/dev/null
fi

# Check if CRON Log file is writable
if [ ! -w "$CRONLOGFILE" ]; then
	echo "WARNING - could not write to Log file $CRONLOGFILE, will drop log messages. Is User Correct? Current log file owener is $(stat -c %U $CRONLOGFILE)"
	CRONLOGFILE=/dev/null
fi

touch $LOCKFILE

echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Preview generation +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
start=`date +%s`
date >> $CRONLOGFILE

$PHP $COMMAND $OPTIONS $DEBUG >> $CRONLOGFILE

end=`date +%s`
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Cron Preview generation Completed. Time: `expr $end - $start`s +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE

rm $LOCKFILE

exit 0
