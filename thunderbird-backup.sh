#!/usr/bin/env bash
# Variables
# options de sauvegarde manuelle interactive
if [ "$*" = "-m" ] || [ "$*" = "--manual" ]; then
  MODE="Manual"
else
	MODE="Auto"
fi
TODAY=$(date '+%Y-%m-%d') # format date 2020-06-28
BACKUP_FOLDER_PATH=/home/panda/Documents/
BACKUP_FILENAME=thunderbird-profile-$TODAY
THUNDERBIRD_PROFILE_PATH=/home/panda/.thunderbird/panda.default-release
LOCK_FILE_PATH=/tmp/thunderbird-backup.lock
IS_THUNDERBIRD_RUNNING=0
ATTEMPTS_TO_STOP_THUNDERBIRD=5

# TODO check si le fichier de backup existe déjà, en mode manuel et en mode auto le supprimer directement
#test -e "$1" && echo "Le fichier $1 existe" || echo "Le fichier $1 n'existe pas"

# TODO Protect contre le controle + C pour fermer le script
# TODO Ne pas avoir plus de 3 sauvegarde, trouver le moyen de supprimer les vieilles
# TODO Faire un fichier de log
# TODO Faire une copie sur un remote ou bien sur disque a mount
# TODO Faire un readme
# TODO Tache systemd

# -----------------------------------------------------------------------

# Check for only one copy of the script running

# create empty lock file if none exists
cat /dev/null >> $LOCK_FILE_PATH
read lastPID < $LOCK_FILE_PATH

# if lastPID is not null and a process with that pid exists , exit
[ -n "$lastPID" ] && [ -d /proc/"$lastPID" ] && echo "A Thunderbird backup is already running." && exit

# not running, save my pid in the lock file
echo $$ > $LOCK_FILE_PATH

echo "Thunderbird backup starting in mode $MODE, backup folder: $BACKUP_FOLDER_PATH"

# -----------------------------------------------------------------------

# -----------------------------------------------------------------------

# If thunderbird running ask user to close it
# If user answer No, exiting
# If user say Yes, than check again, if it still running ask again (5 attempts)

for ((i=1; i<=ATTEMPTS_TO_STOP_THUNDERBIRD; i++))
do
    if pgrep "thunderbird" > /dev/null;
    then

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
          exit;
          fi

    else
        break
    fi
done

# If user say five times that he close thunderbird but it still running, show error and exiting

if pgrep "thunderbird" > /dev/null
then
    if [ ${MODE} = "Manual" ]; then
      zenity --error --text "Can't do backup, Thunderbird is still running. \nPlease kill the process before backup. \nThunderbird backup stop." --width=400
    fi
    echo "Error: Can't do backup, Thunderbird is still running. Please kill the process before backup. Thunderbird backup stop.";
    exit
fi

# -----------------------------------------------------------------------

# Now we can do backup, note: to disable silent mode remove below ">/dev/null" and "-q" flag

pushd $THUNDERBIRD_PROFILE_PATH > /dev/null || exit
cd ..
tar -czf "$BACKUP_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" $THUNDERBIRD_PROFILE_PATH
popd > /dev/null || exit

# -----------------------------------------------------------------------

# Show notify message that backup created

if [ -f "$BACKUP_FOLDER_PATH/$BACKUP_FILENAME.tar.gz" ];
then
    echo "Thunderbird backup successfully created. Thunderbird backup stop."
    notify-send "Thunderbird backup successfully created. Thunderbird backup stop."
else
    echo "Error: Thunderbird backup hasn't created. unexpected error occurred."
    if [ ${MODE} = "Manual" ]; then
      zenity --error --text "Thunderbird backup hasn't created.\nUnexpected error occurred." --width=400
    fi
fi

# -----------------------------------------------------------------------

# ---------------
##!/bin/bash
#SOURCE_DIRS=/media/nfs/
#TARGET_DIR=/home/jean/documents
## monter le repertoire nfs
#mount /media/nfs
#
#rsync -av --del --stats $SOURCE_DIRS "$TARGET_DIR"
#
#umount /media/nfs
#
#echo "Backup Terminé"
#----------

# rsync from this host to the backup server

## options de sauvegarde manuelle interactive
#if [ "$*" = "-m" -o "$*" = "--manual" ]; then
#	MODE="Manual"
#else
#	MODE="Automatic"
#fi
#
##définition des variables
##------------------------
#SCRIPT_PATH=~/scripts/backup		#chemin du dossier contenant le script
#SRC_FOLDER=~/					#chemin du dossier local contenant les fichiers à sauvergarder
#SAVELIST=${SCRIPT_PATH}/savelist	#fichier texte contenant la liste des fichiers et sous-dossiers de SRC_FOLDER à sauvegarder
##------------------------
#USER=nom_utilisateur				#nom d'utilisateur ssh sur le serveur
#REMOTE_HOST=server.domain.fr		#adresse distante du serveur de sauvegarde
#ALT_HOST=server.local				#adresse locale du serveur de sauvegarde
#DST_FOLDER=backup				#nom du dossier de sauvegarde sur le serveur
##------------------------
#NICE=5					#priorité donnée au script
##------------------------
#
#LOGIN=${USER}@${REMOTE_HOST}
#DATE=`date +%k:%M`

#echo $DATE

#création du dossier de log si inexistant
#if [ ! -e ${SCRIPT_PATH}  ] ; then mkdir ${SCRIPT_PATH}/log; touch ${SCRIPT_PATH}/log/last ; fi
#
##fonction de notification
#notification() {
#	# ${1} = "terminée" ou "annulée"
#	# ${2} = durée d'affichage en secondes
#	echo message:"${DATE}\nLa sauvegarde sur ${REMOTE_HOST} est ${1}" | zenity --notification --listen --window-icon="info" | zenity --notification --timeout=${2} --window-icon="info" --text="Sauvegarde sur ${REMOTE_HOST} ${1} (${DATE})" && if cat ${SCRIPT_PATH}/log/list | grep ""; then cat ${SCRIPT_PATH}/log/list | grep -v /$ | zenity --text-info --title="Fichiers synchronisés" --width=800 --height=600; else zenity --info --text="Aucun fichier synchronisé"; fi
#
#}
#
##fonction de sauvegarde et log
#save() {
#	#synchronisation et log
#	{
#	echo "# ${MODE} backup"
#	echo "# Starting: "`/bin/date`
#	nice -n ${NICE} rsync -avrz --delete \
#	--files-from=${SAVELIST} \
#	${SRC_FOLDER} \
#	${DST_FOLDER}
#	echo "# Ending: "`/bin/date`
#	echo "# -------------------------------------------------------------"
#	echo
#	} >> ${SCRIPT_PATH}/log/`date +%G-%V`.log
#	date >> ${SCRIPT_PATH}/log/last
#	# sauvegarde du nom des derniers fichiers synchronisés
#	tac ${SCRIPT_PATH}/log/`date +%G-%V`.log | sed -n '2,/#\ -/p' | tac | sed -e '1,5d' | sed -e :a -e '$d;N;2,5ba' -e 'P;D' >${SCRIPT_PATH}/log/list
#	# notification
#	notification "terminée" 1200
#}
#
## dialogue si mode interactif
#if [ ${MODE} = "Automatic" ]; then
#	save
#else
#	zenity --question --title="Sauvegarde Manuelle sur ${REMOTE_HOST}" --text="Sauvegarder sur ${REMOTE_HOST} maintenant?
#
#	La dernière sauvegarde date du :
#	`tail -1 ${SCRIPT_PATH}/log/last | sed 's/ (UTC.*//'`
#	Les modifications ultérieures seront tranférées sur ${REMOTE_HOST}.
#	"
#
#	if [ $? = "0" ]
#	then
#		save
#	else
#		notification "annulée" 60
#	fi
#fi