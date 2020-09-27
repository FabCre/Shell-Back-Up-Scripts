#!/usr/bin/env bash
# Variables
# options to use manual mode
if [ "$1" = "-m" ] || [ "$1" = "--manual" ]; then
  MODE="Manual"
else
  MODE="Auto"
fi

TODAY=$(date '+%Y-%m-%d')                                               # format date 2020-06-28
BACKUP_FOLDER_PATH=/home/panda/Documents/Backups/                       # path for the output
BACKUP_FILENAME=thunderbird-profile-$TODAY                              # name of the generated back up
THUNDERBIRD_PROFILE_PATH=/home/panda/.thunderbird/panda.default-release # path to the profil to save
LOCK_FILE_PATH=/tmp/thunderbird-backup.lock
IS_THUNDERBIRD_RUNNING=0
ATTEMPTS_TO_STOP_THUNDERBIRD=5

# -----------------------------------------------------------------------

# Check if the file already exists
test -e "$BACKUP_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" &&
echo "The file: $BACKUP_FILENAME.tar.gz already exists. Deleting..." &&
rm -f "$BACKUP_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" ||
echo "The file $BACKUP_FILENAME.tar.gz doesn't exists. Backup creating..."

# -----------------------------------------------------------------------

# TODO Protect contre le controle + C pour fermer le script
# TODO Ne pas avoir plus de 3 sauvegarde, trouver le moyen de supprimer les vieilles
# TODO Faire un fichier de log
# TODO Faire une copie sur un remote ou bien sur disque a mount => créer une seconde option pour avoir un second chemin de back up sur un disque de save.
# TODO Faire un readme
# TODO Tache systemd

# -----------------------------------------------------------------------

# Check for only one copy of the script running

# create empty lock file if none exists
cat /dev/null >>$LOCK_FILE_PATH
read -r lastPID <$LOCK_FILE_PATH

# if lastPID is not null and a process with that pid exists , exit
[ -n "$lastPID" ] && [ -d /proc/"$lastPID" ] && echo "A Thunderbird backup is already running." && exit

# not running, save my pid in the lock file
echo $$ >$LOCK_FILE_PATH

echo "Thunderbird backup starting in mode $MODE, backup folder: $BACKUP_FOLDER_PATH"

# -----------------------------------------------------------------------

# If thunderbird running ask user to close it
# If user answer No, exiting
# If user say Yes, then check again, if it still running ask again (5 attempts)

for ((i = 1; i <= ATTEMPTS_TO_STOP_THUNDERBIRD; i++)); do
  if pgrep "thunderbird" >/dev/null; then

    IS_THUNDERBIRD_RUNNING=1

    if [ ${MODE} = "Auto" ]; then
      echo "Killing Thunderbird process before backup."
      killall thunderbird
      sleep 5
      break
    fi

    # On the first round of the loop, then after until five round
    if [ $i -eq 1 ]; then
      MSG="Before starting backup, Thunderbird must be closed."
    else
      MSG="Thunderbird still running."
    fi

    echo "$MSG Could you please close Thunderbird? ($i / $ATTEMPTS_TO_STOP_THUNDERBIRD attempts)"

    # Open Modal to advise user, check "man zenity"
    zenity \
      --width=400 \
      --question \
      --title="Thunderbird backup" \
      --text="$MSG\nCould you please close Thunderbird? \n($i / $ATTEMPTS_TO_STOP_THUNDERBIRD attempts)"

    # if user press No button
    if [ $? -eq 1 ]; then
      echo "Backup canceled by the user."
      exit
    fi

  else
    break
  fi
done

# If user say five times that he close thunderbird but it still running, show error and exiting

if pgrep "thunderbird" >/dev/null; then
  if [ ${MODE} = "Manual" ]; then
    zenity --error --text "Can't do backup, Thunderbird is still running. \nPlease kill the process before backup. \nThunderbird backup stop." --width=400
  fi
  echo "Error: Can't do backup, Thunderbird is still running. Please kill the process before backup. Thunderbird backup stop."
  exit
fi

# -----------------------------------------------------------------------

# Now we can do backup, note: to disable silent mode remove below ">/dev/null" and "-q" flag

echo "Thunderbird backup in progress..."
pushd $THUNDERBIRD_PROFILE_PATH >/dev/null || exit
cd ..
tar -czf "$BACKUP_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" -P $THUNDERBIRD_PROFILE_PATH
popd >/dev/null || exit

# -----------------------------------------------------------------------

# Show notify message that backup created

if [ -f "$BACKUP_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" ]; then
  echo "Thunderbird backup successfully created."
  notify-send "Thunderbird backup successfully created."
else
  echo "Error: Thunderbird backup hasn't created. unexpected error occurred."
  if [ ${MODE} = "Manual" ]; then
    zenity --error --text "Thunderbird backup hasn't created.\nUnexpected error occurred." --width=400
  fi
fi
# -----------------------------------------------------------------------