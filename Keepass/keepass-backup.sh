#!/usr/bin/env bash

# Variables
# options to use manual mode
if [ "$1" = "-m" ] || [ "$1" = "--manual" ]; then
  MODE="Manual"
else
  MODE="Auto"
fi

TODAY=$(date '+%Y-%m-%d')
BACKUP_KEEPASS_FOLDER_PATH=
BACKUP_FILENAME=
KEEPASS_PROFILE_PATH=
LOCK_FILE_PATH=

# Check if the file already exists
test -e "$BACKUP_KEEPASS_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" &&
echo "The file: $BACKUP_FILENAME.tar.gz already exists. Removing..." &&
rm -f "$BACKUP_KEEPASS_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" ||
echo "The file $BACKUP_FILENAME.tar.gz doesn't exists. Backup creating..."

# -----------------------------------------------------------------------

# Check for only one copy of the script running

# create empty lock file if none exists
cat /dev/null >>$LOCK_FILE_PATH
read -r lastPID <$LOCK_FILE_PATH

# if lastPID is not null and a process with that pid exists , exit
[ -n "$lastPID" ] && [ -d /proc/"$lastPID" ] && echo "A Keepass backup is already running." && exit

# not running, save my pid in the lock file
echo $$ >$LOCK_FILE_PATH

echo "Keepass backup starting in mode $MODE, backup folder: $BACKUP_KEEPASS_FOLDER_PATH"

# -----------------------------------------------------------------------

# Now we can do backup, note: to disable silent mode remove below ">/dev/null"

echo "Keepass backup in progress..."
pushd $KEEPASS_PROFILE_PATH >/dev/null || exit
cd ..
tar -czf "$BACKUP_KEEPASS_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" -P $KEEPASS_PROFILE_PATH
popd >/dev/null || exit

# -----------------------------------------------------------------------

# Check if the lock file exists and remove it

test -e $LOCK_FILE_PATH &&
echo "Removing the lock file..." &&
rm -f $LOCK_FILE_PATH &&
echo "The Lock file successfully removed." ||
echo "The Lock file has already been removed."

# -----------------------------------------------------------------------

# Check if there is file older than four days and remove it

find $BACKUP_KEEPASS_FOLDER_PATH/* -type f -mtime +4 -exec rm -f {} \; &&
echo "Backup older than 4 days are successfully removed."

# -----------------------------------------------------------------------

# Show notify message that backup is created

if [ -f "$BACKUP_KEEPASS_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" ]; then
  echo "Keepass backup successfully created."
  notify-send "Keepass backup successfully created."
else
  echo "Error: Keepass backup hasn't created. unexpected error occurred."
  if [ ${MODE} = "Manual" ]; then
    zenity --error --text "Keepass backup hasn't created.\nUnexpected error occurred." --width=400
  fi
fi

# -----------------------------------------------------------------------
