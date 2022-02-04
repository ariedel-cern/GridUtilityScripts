#!/bin/bash
# File              : CopyFromGrid.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 16.06.2021
# Last Modified Date: 03.02.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# copy files from grid to local machine run by run

[ ! -f config.json ] && echo "No config file!!!" && exit 1
LockFile="$(jq -r '.LockFile' config.json)"
StatusFile="$(jq -r '.StatusFile' config.json)"
[ ! -f $StatusFile ] && echo "No $StatusFile file!!!" && exit 1

# get variables from config file
{
	flock 100
	Runs="$(jq -r 'keys[]' $StatusFile)"
} 100>$LockFile
LocalOutputDir="$(jq -r '.task.GridOutputDir' config.json)"
GridOutputDir="$(jq -r '.task.GridHomeDir' config.json)/$(jq -r '.task.GridWorkDir' config.json)/$LocalOutputDir"
CopyJobs="$(jq -r '.misc.CopyJobs' config.json)"
CopyRetries="$(jq -r '.misc.CopyRetries' config.json)"

# loop variables
Data=""
FilesCopied=""
FilesMerged=""

for Run in $Runs; do

	{
		flock 100
		Data="$(jq -r --arg Run "$Run" '.[$Run]' $StatusFile)"
	} 100>$LockFile

	FilesMerged="$(jq -r '.Merged' <<<$Data)"
	[ "${FilesMerged:=0}" -ge 1 ] && continue

	echo "Copy Files from Run: $Run"
	mkdir -p "${LocalOutputDir}/${Run}"
    alien_mkdir -p "${GridOutputDir}/${Run}"

	alien_cp "alien:${GridOutputDir}/${Run}" "file:${LocalOutputDir}" -glob "*.root" -T $CopyJobs -retry $CopyRetries

	FilesCopied=$(find "${LocalOutputDir}/${Run}" -type f -name $(jq -r '.task.GridOutputFile' config.json) | wc -l)

	{
		flock 100
		jq --arg Run "$Run" --arg FilesCopied "${FilesCopied:=0}" 'setpath([$Run,"FilesCopied"];$FilesCopied)' $StatusFile | sponge $StatusFile
	} 100>$LockFile

done

exit 0
