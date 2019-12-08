#!/bin/bash

set -e

echo
echo "============================="
echo "  Sending Output to Zabbix"
echo "============================="
echo

arr=()

echo "--> Running discovery of rescript repos"
REPODISC=$(/etc/zabbix/zabbix_agentd.d/rescript-repo-discovery.pl /root/.rescript/config/)
zabbix_sender --config /etc/zabbix/zabbix_agentd.conf --key "rescript.repo.discovery[discoverrepos]" --value "$REPODISC"
echo "Zabbix needs a minute to process new items discovered..."
sleep 30
echo

# Identify the most recent rescript-log
RLOG=$(find /root/.rescript/logs/ -type f | xargs ls -tr | tail -n 1)
REPO=$(echo $RLOG | sed 's/.*\/logs\///' | sed 's/-.*//')
TIME=$(stat -c '%015Y' $RLOG)

# Calculate checksum the conf file used
CKSUM=$(cksum /root/.rescript/config/$REPO.conf | awk '{print $1}')
arr+=("- rescript.config.cksum[$REPO] $TIME $CKSUM")


# Exctract Snapshot ID
RLOG_SNAPSHOTID=$(cat $RLOG | grep '^snapshot .* saved$' | awk '{print $2}')
arr+=("- rescript.backup.snapshotid[$REPO] $TIME $RLOG_SNAPSHOTID")


# Extract Added Bytes
RLOG_ADDED=$(cat $RLOG | grep 'Added to the repo' | awk '{print $5,$6}' | \
	python3 -c 'import sys; import humanfriendly; print (humanfriendly.parse_size(sys.stdin.read(), binary=True))' )
arr+=("- rescript.backup.added[$REPO] $TIME $RLOG_ADDED")


# Extract Processed Time
RLOG_PROCESSED_TIME=$(cat $RLOG | grep '^processed' | \
		    awk '{print $NF}' | \
		    awk -F':' '{print (NF>2 ? $(NF-2)*3600 : 0) + (NF>1 ? $(NF-1)*60 : 0) + $(NF)}' )
arr+=("- rescript.backup.processedtime[$REPO] $TIME $RLOG_PROCESSED_TIME")


# Extract Processed Bytes
RLOG_PROCESSED_BYTES=$(cat $RLOG | grep '^processed' | \
		     awk '{print $4,$5}' | \
		     python3 -c 'import sys; import humanfriendly; print (humanfriendly.parse_size(sys.stdin.read(), binary=True))'  )
arr+=("- rescript.backup.processedbytes[$REPO] $TIME $RLOG_PROCESSED_BYTES")


# Log Restic Check
RLOG_CHECK=$( grep "Starting check..." $RLOG ) && echo "--> Restic Check Logging" || echo "Restic Check wasn't started."
if [ "$RLOG_CHECK" ]
then
  RLOG_CHECK_RESULT=$( grep "no errors were found" $RLOG ) || RLOG_CHECK_RESULT=$(grep "ciphertext verification failed" $LOG)
  arr+=("- rescript.check.message[$REPO] $TIME $RLOG_CHECK_RESULT")
fi
echo


echo "--> Sending everything to Zabbix"
# for ix in ${!arr[*]}; do printf "%s\n" "${arr[$ix]}"; done
# echo
for ix in ${!arr[*]}; do printf "%s\n" "${arr[$ix]}"; done | zabbix_sender --config /etc/zabbix/zabbix_agentd.conf --with-timestamps --input-file -
