#!/bin/bash
# File              : CopyFromGrid.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 16.06.2021
# Last Modified Date: 08.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# copy files from grid to local machine run by run

[ ! -f config.json ] && echo "No config file!!!" && exit 1
LockFile="$(jq -r '.LockFile' config.json)"
StatusFile="$(jq -r '.StatusFile' config.json)"
[ ! -f $StatusFile ] && echo "No $StatusFile file!!!" && exit 1

# get variables from config file
Runs="$(jq -r 'keys[]' $StatusFile)"
LocalOutputDir="$(jq -r '.task.GridOutputDir' config.json)"
GridOutputDir="$(jq -r '.task.GridHomeDir' config.json)/$(jq -r '.task.GridWorkDir' config.json)/$LocalOutputDir"
CopyJobs="$(jq -r '.misc.CopyJobs' config.json)"
CopyRetries="$(jq -r '.misc.CopyRetries' config.json)"

# loop variables
Data=""
Status=""
FilesCopied=""

for Run in $Runs; do

	Data="$(jq -r --arg Run "$Run" '.[$Run]' $StatusFile)"
	Status="$(jq -r '.Status' <<<$Data)"
	FilesCopied="$(jq -r '.FilesCopied' <<<$Data)"

	if [ "$Status" == "DONE" -a "$FilesCopied" == "ALL" ]; then
		break
	fi

	echo "Copy Files from Run: $Run"

	if alien_cp "alien:${GridOutputDir}/${Run}" "file:${LocalOutputDir}" -glob "*.root" -T $CopyJobs -retry $CopyRetries; then
		if [ $Status == "DONE" ]; then
			Copied="ALL"
		else
			Copied="PARTIAL"
		fi
	else
		Copied="ERROR"
	fi
	(
		flock 100
		jq --arg Run "$Run" --arg FilesCopied "$Copied" 'setpath([$Run,"FilesCopied"];$FilesCopied)' $StatusFile | sponge $StatusFile
	) 100>$LockFile

done

exit 0
