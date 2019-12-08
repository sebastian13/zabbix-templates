#!/bin/bash

set -e

rescript example.repo.1
source /etc/zabbix/scripts/log-backup.sh

rescript example.repo.2 backup -lC
source /etc/zabbix/scripts/log-backup.sh
