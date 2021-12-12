#!/bin/bash
# File              : CopyFromGrid.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 16.06.2021
# Last Modified Date: 13.12.2021
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
FilesCopiedOld=""

for Run in $Runs; do

	Data="$(jq -r --arg Run "$Run" '.[$Run]' $StatusFile)"
	Status="$(jq -r '.Status' <<<$Data)"
	FilesCopied="$(jq -r '.FilesCopied' <<<$Data)"
	[ -f "${StatusFile}.bak" ] && FilesCopiedOld="$(jq -r --arg Run "$Run" '.[$Run].FilesCopied' "${StatusFile}.bak")"
	if [ -z $FilesCopiedOld -o $FilesCopiedOld -eq 0 ]; then
		FilesCopiedOld="-10"
	fi

	if [ ! "$Status" == "DONE" -a "$(($FilesCopied - $FilesCopiedOld))" -lt 5 ]; then
		continue
	fi

	echo "Copy Files from Run: $Run"

	alien_cp "alien:${GridOutputDir}/${Run}" "file:${LocalOutputDir}" -glob "*.root" -T $CopyJobs -retry $CopyRetries

	FilesCopied=$(find "${LocalOutputDir}/${Run}" -type f -name "*.root" | wc -l)

	(
		flock 100
		jq --arg Run "$Run" --arg FilesCopied "$FilesCopied" 'setpath([$Run,"FilesCopied"];$FilesCopied)' $StatusFile | sponge $StatusFile
	) 100>$LockFile

done

exit 0
