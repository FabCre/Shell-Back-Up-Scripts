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
BACKUP_FILENAME=vivaldi-profile-$TODAY
VIVALDI_PROFILE_PATH=
LOCK_FILE_PATH=
IS_VIVALDI_RUNNING=0
ATTEMPTS_TO_STOP_VIVALDI=5

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
[ -n "$lastPID" ] && [ -d /proc/"$lastPID" ] && echo "A Vivaldi backup is already running." && exit

# not running, save my pid in the lock file
echo $$ >$LOCK_FILE_PATH

echo "Vivaldi backup starting in mode $MODE, backup folder: $BACKUP_FOLDER_PATH"

# -----------------------------------------------------------------------

# If vivaldi running ask user to close it
# If user answer No, exiting
# If user say Yes, then check again, if it still running ask again (5 attempts)

for ((i = 1; i <= ATTEMPTS_TO_STOP_VIVALDI; i++)); do
  if pgrep "firefox" >/dev/null; then

    IS_VIVALDI_RUNNING=1

    if [ ${MODE} = "Auto" ]; then
      echo "Killing Vivaldi process before backup."
      killall vivaldi
      sleep 5
      break
    fi

    # On the first round of the loop, then after until five round
    if [ $i -eq 1 ]; then
      MSG="Before starting backup, Vivaldi must be closed."
    else
      MSG="Vivaldi still running."
    fi

    echo "$MSG Could you please close Vivaldi? ($i / $ATTEMPTS_TO_STOP_VIVALDI attempts)"

    # Open Modal to advise user, check "man zenity"
    zenity \
      --width=400 \
      --question \
      --title="Vivaldi backup" \
      --text="$MSG\nCould you please close Vivaldi? \n($i / $ATTEMPTS_TO_STOP_VIVALDI attempts)"

    # if user press No button
    if [ $? -eq 1 ]; then
      echo "Backup canceled by the user."
      exit
    fi

  else
    break
  fi
done

# If user say five times that he close vivaldi but it still running, show error and exiting

if pgrep "vivaldi" >/dev/null; then
  if [ ${MODE} = "Manual" ]; then
    zenity --error --text "Can't do backup, Vivaldi is still running. \nPlease kill the process before backup. \nVivaldi backup stop." --width=400
  fi
  echo "Error: Can't do backup, Vivaldi is still running. Please kill the process before backup. Vivaldi backup stop."
  exit
fi

# -----------------------------------------------------------------------

# Now we can do backup, note: to disable silent mode remove below ">/dev/null"

echo "Vivaldi backup in progress..."
pushd $VIVALDI_PROFILE_PATH >/dev/null || exit
cd ..
tar -czf "$BACKUP_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" -P $VIVALDI_PROFILE_PATH
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

find $BACKUP_FOLDER_PATH/* -type f -mtime +4 -exec rm -f {} \; &&
echo "Backup older than 4 days are successfully removed."

# -----------------------------------------------------------------------

# Show notify message that backup is created

if [ -f "$BACKUP_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" ]; then
  echo "Vivaldi backup successfully created."
  notify-send "Vivaldi backup successfully created."
else
  echo "Error: Vivaldi backup hasn't created. unexpected error occurred."
  if [ ${MODE} = "Manual" ]; then
    zenity --error --text "Vivaldi backup hasn't created.\nUnexpected error occurred." --width=400
  fi
fi

# -----------------------------------------------------------------------
