#/bin/bash
# File              : CheckFileIntegrity.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 17.06.2021
# Last Modified Date: 07.02.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# check integrity of all .root files in the local output directory

set -o pipefail

[ ! -f config.json ] && echo "No config file!!!" && exit 1
LockFile="$(jq -r '.LockFile' config.json)"
StatusFile="$(jq -r '.StatusFile' config.json)"
[ ! -f $StatusFile ] && echo "No $StatusFile file!!!" && exit 1

# get variables from config file
echo "Waiting for lock..."
{
	flock 100
	Runs="$(jq -r 'keys[]' $StatusFile)"
} 100>$LockFile
LocalOutputDir="$(jq -r '.task.GridOutputDir' config.json)"

FileLog="CheckedFiles.log"
if [ ! -f $FileLog ]; then
	: >$FileLog
fi

# check integrity
Check_Integrity() {

	# set flag
	local Flag=0

	# check if file was already checked
	if grep -Fxq "$1" "$2"; then
		return 0
	fi

	# check file
	local Timeout=20
	{
		timeout $Timeout file -E $1 || Flag=1
		timeout $Timeout rootls $1 || Flag=1
		# ADD MORE CHECKS
	} &>/dev/null

	# remove file if a check is not passed
	if [ $Flag -eq 1 ]; then
		return 1
	else
		# if it passes, print the name
		echo $1
		return 0
	fi
}
# needed to run a function with parallel
export -f Check_Integrity

Status=""
Dir=""
FilesChecked=""
GridOutputFile="$(jq -r '.task.GridOutputFile' config.json)"

for Run in $Runs; do

	Dir="${LocalOutputDir}/${Run}"
	echo "Checking .root files in $Dir"

	find $Dir -type f -name $GridOutputFile | parallel --progress --bar Check_Integrity {} $FileLog >>$FileLog

	FilesChecked=$(find "${LocalOutputDir}/${Run}" -type f -name $GridOutputFile | wc -l)

    echo "Waiting for lock..."
	{
		flock 100
		jq --arg Run $Run --arg FilesChecked ${FilesChecked:=0} 'setpath([$Run,"FilesChecked"];$FilesChecked)' $StatusFile | sponge $StatusFile
	} 100>$LockFile
done

exit 0
