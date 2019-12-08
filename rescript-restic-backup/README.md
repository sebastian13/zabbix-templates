# Zabbix Template: Rescript Restic Backup

This script logs [restic backup](https://restic.net/) tasks to Zabbix, when using the [rescript wrapper](https://gitlab.com/sulfuror/rescript.sh).

## Screenshots
### Latest Data
![Latest Data](screenshots/data.png)

### Triggers
![Triggers](screenshots/triggers.png)

## Requirements
* Restic
* Rescript
* Zabbix-Sender
* python3
* python3-pip
* python3: humanfriendly

## How to Use

1. Download the script **log-rescript.sh** to any place you like. I would recommend **/etc/zabbix/scripts/**
1. Download **rescript-repo-discovery.pl** to **/etc/zabbix/zabbix\_agentd.d/**
1. Upload the **zbx\_template\_rescript-backup** to Zabbix and assign it to a host
1. Run the script after each **rescript** call

### Example
```bash
#!/bin/bash

# Run rescript automatic function
rescript example.repo.1

# send logs to zabbix
source /etc/zabbix/scripts/log-backup.sh

# Run another rescript backup
# Using a rescript command requires the --log flag
rescript example.repo.2 backup -l
source /etc/zabbix/scripts/log-backup.sh

```

