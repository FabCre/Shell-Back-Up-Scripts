#!/usr/bin/env bash

# Variables
# options to use manual mode
if [ "$1" = "-m" ] || [ "$1" = "--manual" ]; then
  MODE="Manual"
else
  MODE="Auto"
fi

TODAY=$(date '+%Y-%m-%d')
BACKUP_FOLDER_PATH=
BACKUP_FILENAME=
FIREFOX_PROFILE_PATH=
LOCK_FILE_PATH=
IS_FIREFOX_RUNNING=0
ATTEMPTS_TO_STOP_FIREFOX=5

# Check if the file already exists
test -e "$BACKUP_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" &&
echo "The file: $BACKUP_FILENAME.tar.gz already exists. Removing..." &&
rm -f "$BACKUP_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" ||
echo "The file $BACKUP_FILENAME.tar.gz doesn't exists. Backup creating..."

# -----------------------------------------------------------------------

# Check for only one copy of the script running

# create empty lock file if none exists
cat /dev/null >>$LOCK_FILE_PATH
read -r lastPID <$LOCK_FILE_PATH

# if lastPID is not null and a process with that pid exists , exit
[ -n "$lastPID" ] && [ -d /proc/"$lastPID" ] && echo "A Firefox backup is already running." && exit

# not running, save my pid in the lock file
echo $$ >$LOCK_FILE_PATH

echo "Firefox backup starting in mode $MODE, backup folder: $BACKUP_FOLDER_PATH"

# -----------------------------------------------------------------------

# If firefox running ask user to close it
# If user answer No, exiting
# If user say Yes, then check again, if it still running ask again (5 attempts)

for ((i = 1; i <= ATTEMPTS_TO_STOP_FIREFOX; i++)); do
  if pgrep "firefox" >/dev/null; then

    IS_FIREFOX_RUNNING=1

    if [ ${MODE} = "Auto" ]; then
      echo "Killing Firefox process before backup."
      killall firefox
      sleep 5
      break
    fi

    # On the first round of the loop, then after until five round
    if [ $i -eq 1 ]; then
      MSG="Before starting backup, Firefox must be closed."
    else
      MSG="Firefox still running."
    fi

    echo "$MSG Could you please close Firefox? ($i / $ATTEMPTS_TO_STOP_FIREFOX attempts)"

    # Open Modal to advise user, check "man zenity"
    zenity \
      --width=400 \
      --question \
      --title="Firefox backup" \
      --text="$MSG\nCould you please close Firefox? \n($i / $ATTEMPTS_TO_STOP_FIREFOX attempts)"

    # if user press No button
    if [ $? -eq 1 ]; then
      echo "Backup canceled by the user."
      exit
    fi

  else
    break
  fi
done

# If user say five times that he close firefox but it still running, show error and exiting

if pgrep "firefox" >/dev/null; then
  if [ ${MODE} = "Manual" ]; then
    zenity --error --text "Can't do backup, Firefox is still running. \nPlease kill the process before backup. \nFirefox backup stop." --width=400
  fi
  echo "Error: Can't do backup, Firefox is still running. Please kill the process before backup. Firefox backup stop."
  exit
fi

# -----------------------------------------------------------------------

# Now we can do backup, note: to disable silent mode remove below ">/dev/null"

echo "Firefox backup in progress..."
pushd $FIREFOX_PROFILE_PATH >/dev/null || exit
cd ..
tar -czf "$BACKUP_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" -P $FIREFOX_PROFILE_PATH
popd >/dev/null || exit

# -----------------------------------------------------------------------

# Check if the lock file exists and remove it

test -e $LOCK_FILE_PATH &&
echo "Removing the lock file..." &&
rm -f $LOCK_FILE_PATH &&
echo "The Lock file successfully removed."||
echo "The Lock file has already been removed."

# -----------------------------------------------------------------------

# Check if there is file older than fourteen days and remove it

find $BACKUP_FOLDER_PATH/* -type f -mtime +14 -exec rm -f {} \; &&
echo "Backup older than 14 days are successfully removed."

# -----------------------------------------------------------------------

# Show notify message that backup is created

if [ -f "$BACKUP_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" ]; then
  echo "Firefox backup successfully created."
  notify-send "Firefox backup successfully created."
else
  echo "Error: Firefox backup hasn't created. unexpected error occurred."
  if [ ${MODE} = "Manual" ]; then
    zenity --error --text "Firefox backup hasn't created.\nUnexpected error occurred." --width=400
  fi
fi

# -----------------------------------------------------------------------
