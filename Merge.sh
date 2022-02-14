#!/bin/bash
# File              : Merge.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 24.03.2021
# Last Modified Date: 08.02.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# merge .root files run by run

[ ! -f config.json ] && echo "No config file!!!" && exit 1
LockFile="$(jq -r '.LockFile' config.json)"
StatusFile="$(jq -r '.StatusFile' config.json)"
[ ! -f $StatusFile ] && echo "No $StatusFile file!!!" && exit 1

echo "Merging $(jq -r '.task.GridOutputFile' config.json) run by run in $(jq -r '.task.GridOutputDir' config.json)"

MergedFile=""
OutputFile="$(jq -r '.task.GridOutputFile' config.json)"
Runs="$(jq -r 'keys[]' $StatusFile)"

Data=""
Status=""
FilesCopied=""
FilesChecked=""
FilesMerged=""

for Run in $Runs; do

	echo "Waiting for lock..."
	{
		flock 100
		Data="$(jq -r --arg Run "$Run" '.[$Run]' $StatusFile)"
	} 100>$LockFile

	echo "Trying to merge $Run"
	Status="$(jq -r '.Status' <<<$Data)"
	FilesCopied="$(jq -r '.FilesCopied' <<<$Data)"
	FilesChecked="$(jq -r '.FilesChecked' <<<$Data)"
	FilesMerged="$(jq -r '.Merged' <<<$Data)"

	[ "${Status:=RUNNING}" != "DONE" ] && continue
	echo "Run is DONE"
	[ "${FilesMerged:=0}" -ge "1" ] && continue
	echo "Run is not merged yet"
	[ "$((${FilesCopied:=10} - 2))" -gt "${FilesChecked:=0}" ] && continue
	echo "Files are copied and check, let's go..."

	RunDir="$(jq -r '.task.GridOutputDir' config.json)/${Run}"

	# go into subdirectory
	pushd $RunDir

	echo "Start merging run $Run in $PWD"

	# construct filename for merged file
	MergedFile="$(basename $Run)_Merged.root"
	FilesToMerge="$(find . -type f -name "$OutputFile")"

	# merge files using hadd in parallel!!!
	hadd -f -k -j $(nproc) $MergedFile $FilesToMerge || exit 1

	# create backup, just in cas3
	cp "${MergedFile}" "${MergedFile}.bak"

	# count number of merge files
	FilesMerged="$(wc -l <<<$FilesToMerge)"

	# delete smaller root files (safing space on the local disk)
	find . -type f -name "$OutputFile" -delete
	# delete all empty directories
	find . -empty -type d -delete

	# go back
	popd

	echo "Waiting for lock..."
	{
		flock 100
		jq --arg Run "$Run" --arg FilesMerged "${FilesMerged:=0}" 'setpath([$Run,"Merged"];$FilesMerged)' $StatusFile | sponge $StatusFile
	} 100>$LockFile

done

exit 0
