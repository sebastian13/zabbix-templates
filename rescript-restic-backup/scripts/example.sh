#!/bin/bash

set -e

# Rescript's automatic function (https://gitlab.com/sulfuror/rescript.sh/wikis/usage)
# reads the "LOGGING" variable. By default, the "LOGGING" variable is set to "yes".
# This will create a log file with the output, which is necessary for this script.
rescript example.repo.1
# Run this script after each "rescript ..." call.
source /etc/zabbix/scripts/log-rescript.sh

# If using a rescript command, you have to use the logging flag -l or --log
# to create a logfile, which is necessary fort his script.
# -l, --log: create log file with command output.
rescript example.repo.2 backup -l
source /etc/zabbix/scripts/log-rescript.sh

# This script will also log the output of a restic check.
# -C, --check: check for errors in repository
rescript example.repo.2 backup -lC
source /etc/zabbix/scripts/log-rescript.sh
