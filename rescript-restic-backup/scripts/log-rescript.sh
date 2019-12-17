#!/bin/bash

set -e

echo
echo "============================="
echo "  Sending Output to Zabbix"
echo "============================="
echo

arr=()

# Define various output colors
cecho () {
  local _color=$1; shift
  echo -e "$(tput setaf $_color)$@$(tput sgr0)"
}
black=0; red=1; green=2; yellow=3; blue=4; pink=5; cyan=6; white=7;

# Look for rescript config files & create items on Zabbix Server
cecho $yellow "[Running discovery of rescript repos]"
REPODISC=$(/etc/zabbix/scripts/rescript-repo-discovery.pl /root/.rescript/config/)
zabbix_sender --config /etc/zabbix/zabbix_agentd.conf --key "rescript.repo.discovery[discoverrepos]" --value "$REPODISC"
echo

# Identify the most recent rescript-log
RLOG=$(find /root/.rescript/logs/ -type f | xargs ls -tr | tail -n 1)
REPO=$(echo $RLOG | sed 's/.*\/logs\///' | sed 's/-backup-log-.*//; s/-cleanup-log-.*//; s/-log-.*//;')
TIME=$(stat -c '%015Y' $RLOG)

echo "Extracting from:  $RLOG"
echo "Repository:       $REPO"

# Calculate checksum the conf file used
CKSUM=$(cksum /root/.rescript/config/$REPO.conf | awk '{print $1}')
arr+=("- rescript.config.cksum[$REPO] $TIME $CKSUM")
echo "Checksum:         $CKSUM"
echo

# Log Restic Backup
log-backup () {
	# Exctract Snapshot ID
	RLOG_SNAPSHOTID=$(cat $RLOG | grep '^snapshot .* saved$' | awk '{print $2}')
	arr+=("- rescript.backup.snapshotid[$REPO] $TIME $RLOG_SNAPSHOTID")
	echo "Snapshot ID:      $RLOG_SNAPSHOTID"

	# Extract Added Bytes
	RLOG_ADDED=$(cat $RLOG | grep 'Added to the repo' | awk '{print $5,$6}' | \
		python3 -c 'import sys; import humanfriendly; print (humanfriendly.parse_size(sys.stdin.read(), binary=True))' )
	arr+=("- rescript.backup.added[$REPO] $TIME $RLOG_ADDED")
	echo "Bytes Added:      $RLOG_ADDED"

	# Extract Processed Time
	RLOG_PROCESSED_TIME=$(cat $RLOG | grep '^processed.*files' | \
			    awk '{print $NF}' | \
			    awk -F':' '{print (NF>2 ? $(NF-2)*3600 : 0) + (NF>1 ? $(NF-1)*60 : 0) + $(NF)}' )
	arr+=("- rescript.backup.processedtime[$REPO] $TIME $RLOG_PROCESSED_TIME")
	echo "Time Processed:   $RLOG_PROCESSED_TIME"

	# Extract Processed Bytes
	RLOG_PROCESSED_BYTES=$(cat $RLOG | grep '^processed.*files' | \
			     awk '{print $4,$5}' | \
			     python3 -c 'import sys; import humanfriendly; print (humanfriendly.parse_size(sys.stdin.read(), binary=True))'  )
	arr+=("- rescript.backup.processedbytes[$REPO] $TIME $RLOG_PROCESSED_BYTES")
	echo "Bytes Processed:  $RLOG_PROCESSED_TIME"
}

# Check if restic backup was run
RLOG_BACKUP=$( grep "start backup on" $RLOG ) && cecho $yellow "[Capture Restic Backup]" || :
if [ "$RLOG_BACKUP" ]
then
  log-backup
  echo
fi

# Log Restic Check
log-check () {
	RLOG_CHECK_RESULT=$( grep "no errors were found" $RLOG ) || RLOG_CHECK_RESULT=$(grep "ciphertext verification failed" $LOG)
	arr+=("- rescript.check.message[$REPO] $TIME $RLOG_CHECK_RESULT")
	echo "Checking Result:  $RLOG_CHECK_RESULT"
}

# Check if Restic Check was run
RLOG_CHECK=$( grep "Checking for Errors\|Starting check..." $RLOG ) && cecho $yellow "[Log Restic Check]" || :
if [ "$RLOG_CHECK" ]
then
  log-check
  echo
fi

# Log Restic Forget & Prune
log-prune () {
	# Save set policy
	RLOG_PRUNE_POLICY=$(cat $RLOG | grep "Applying Policy:" | sed 's/Applying Policy: //')
	arr+=("- rescript.prune.policy[$REPO] $TIME $RLOG_PRUNE_POLICY")
	echo "Policy:           $RLOG_PRUNE_POLICY"

	# Number of packs in repo
	RLOG_PRUNE_PACKS=$(cat $RLOG | grep "repository contains.*packs" | awk '{print $3}')
	arr+=("- rescript.prune.packs[$REPO] $TIME $RLOG_PRUNE_PACKS")
	echo "Contained Packs:  $RLOG_PRUNE_PACKS"

	# Size of Repo
	RLOG_PRUNE_SIZE=$(cat $RLOG | grep "repository contains.*packs" | awk '{print $(NF-1), $NF}' | \
			/usr/bin/python3 -c 'import sys; import humanfriendly; print (humanfriendly.parse_size(sys.stdin.read(), binary=True))' )
	arr+=("- rescript.prune.size[$REPO] $TIME $RLOG_PRUNE_SIZE")
	echo "Repo's Size:      $RLOG_PRUNE_SIZE"

	# Removed files
	RLOG_PRUNE_REMFILES=$(cat $RLOG | grep "will remove .* invalid files" | awk '{print $3}')
	arr+=("- rescript.prune.remfiles[$REPO] $TIME $RLOG_PRUNE_REMFILES")
	echo "Files removed:    $RLOG_PRUNE_REMFILES"

	# Deleted packs
	RLOG_PRUNE_DELPACKS=$(cat $RLOG | grep "will delete .* packs and rewrite .* packs, this frees .*" | awk '{print $3}')
	arr+=("- rescript.prune.delpacks[$REPO] $TIME $RLOG_PRUNE_DELPACKS")
	echo "Packs deleted:    $RLOG_PRUNE_DELPACKS"

	# Rewritten packs
	RLOG_PRUNE_REWPACKS=$(cat $RLOG | grep "will delete .* packs and rewrite .* packs, this frees .*" | awk '{print $7}')
	arr+=("- rescript.prune.rewpacks[$REPO] $TIME $RLOG_PRUNE_REWPACKS")
	echo "Packs rewritten:  $RLOG_PRUNE_REWPACKS"

	# Freed space
	RLOG_PRUNE_FREEDSPACE=$(cat $RLOG | grep "will delete .* packs and rewrite .* packs, this frees .*" | awk '{print $(NF-1), $NF}' | \
			/usr/bin/python3 -c 'import sys; import humanfriendly; print (humanfriendly.parse_size(sys.stdin.read(), binary=True))' )
	arr+=("- rescript.prune.freedspace[$REPO] $TIME $RLOG_PRUNE_FREEDSPACE")
	echo "Freed space:      $RLOG_PRUNE_FREEDSPACE"
}

# Check if restic forget & prune was run
RLOG_PRUNE=$( grep "Applying Policy" $RLOG ) && cecho $yellow "[Log Restic Forget & Prune]" || :
if [ "$RLOG_PRUNE" ]
then
  log-prune
  echo
fi

cecho $yellow "[Sending everything to Zabbix]"
# for ix in ${!arr[*]}; do printf "%s\n" "${arr[$ix]}"; done
# echo
send-to-zabbix () {
	for ix in ${!arr[*]}; do printf "%s\n" "${arr[$ix]}"; done | zabbix_sender --config /etc/zabbix/zabbix_agentd.conf --with-timestamps --input-file -
}

# Send Data
# It might be the case that the Zabbix Server has not fully processed the discovery of new items yet.
# If sending raises an error, the script starts a second try after one minute.
send-to-zabbix || { cecho $red "[ERROR] Sending or processing of some items failed. Will wait one minute before trying again..."; sleep 60; send-to-zabbix; }
echo
