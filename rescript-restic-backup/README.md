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

1. Download **log-rescript.sh** and **rescript-repo-discovery.pl** to `/etc/zabbix/scripts/`

  ```bash
  mkdir -p /etc/zabbix/scripts
  cd /etc/zabbix/scripts
  curl -O https://raw.githubusercontent.com/sebastian13/zabbix-templates/master/rescript-restic-backup/scripts/log-rescript.sh
  curl -O https://raw.githubusercontent.com/sebastian13/zabbix-templates/master/rescript-restic-backup/scripts/rescript-repo-discovery.pl
  chmod +x log-rescript.sh rescript-repo-discovery.pl
  ``` 

1. Upload the template **zbx\_template\_rescript-backup** to Zabbix Server and assign it to a host

1. Run the script after each **rescript** call

### Example
```bash
#!/bin/bash

# Run rescript's automatic function
rescript example.repo.1
# send logs to zabbix
source /etc/zabbix/scripts/log-rescript.sh

# Using a rescript command requires the --log flag
rescript example.repo.2 backup -l
source /etc/zabbix/scripts/log-rescript.sh

```

