# Shell Backup Scripts

<img src="https://cloud.githubusercontent.com/assets/2059754/24601246/753a7f36-1858-11e7-9d6b-7a0e64fb27f7.png" height="100px" width="100px" alt="bash-logo"/>

##### A collection of small bash scripts for backup a directory or files with no dependencies. All of these scripts have been tested on Linux.

## Scripts

All scripts contains: 

* *.sh, the backup script.
* *.service, the systemd service.
* *.timer, the systemd timer.

## Installation

For example, in thunderbird backup script:

### Configure variables of the backup

First of all, configure PATH variables in the script thunderbird-backup.sh:
```shell script
BACKUP_FOLDER_PATH=YOUR/CUSTOM/PATH
THUNDERBIRD_PROFILE_PATH=/home/YOUR_USER/.thunderbird/YOUR_USER.default-release
LOCK_FILE_PATH=YOUR/CUSTOM/PATH
BACKUPS_OLDER_THAN=4
```

### Manage script

Copy the script to the /usr/local/bin directory:
```
sudo cp thunderbird-backup.sh /usr/local/bin
```

Make it executable:
```
sudo chmod +x /usr/local/bin/thunderbird-backup.sh
```

### Manage service

Copy the service to the /usr/lib/systemd/system/ directory:
```
sudo cp thunderbird-backup.service /usr/lib/systemd/system/
```

Grant some permissions to the service:
```
sudo chmod 644 thunderbird-backup.service
```

Check the status of the service:
```
sudo systemctl status thunderbird-backup.service
```

Reload systemd:
```
sudo systemctl daemon-reload
```

Enable the service:
```
sudo systemctl enable thunderbird-backup.service
```

Enabling a service doesn't start it, it only sets it to be launched at boot time. To start the service now:
```
sudo systemctl start thunderbird-backup.service
```
After manually starting the service, check if the service is running correctly:
```
sudo systemctl status thunderbird-backup.service
```
To stop the service, if needed:
```
sudo systemctl stop thunderbird-backup.service
```
To disable the service, if needed:
```
sudo systemctl disable thunderbird-backup.service
```

### Manage timer

Copy the timer to the /usr/lib/systemd/system/ directory:
```
sudo cp thunderbird-backup.timer /usr/lib/systemd/system/
```

Grant some permissions to the timer:
```
sudo chmod 644 thunderbird-backup.timer
```

Check the status of the timer:
```
sudo systemctl status thunderbird-backup.timer
```

Reload systemd:
```
sudo systemctl daemon-reload
```

Enable the timer:
```
sudo systemctl enable thunderbird-backup.timer
```

Enabling a timer doesn't start it. To start the timer now:
```
sudo systemctl start thunderbird-backup.timer
```
After manually starting the timer, check if the timer is running correctly:
```
sudo systemctl list-timers --all
```
To stop the timer:
```
sudo systemctl stop thunderbird-backup.timer
```
