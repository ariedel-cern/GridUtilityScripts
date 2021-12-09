#/bin/bash
# File              : CheckFileIntegrity.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 17.06.2021
# Last Modified Date: 08.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# check integrity of all .root files in the local output directory

set -o pipefail

[ ! -f config.json ] && echo "No config file!!!" && exit 1
LockFile="$(jq -r '.LockFile' config.json)"
StatusFile="$(jq -r '.StatusFile' config.json)"
[ ! -f $StatusFile ] && echo "No $StatusFile file!!!" && exit 1

# get variables from config file
Runs="$(jq -r 'keys[]' $StatusFile)"
LocalOutputDir="$(jq -r '.task.GridOutputDir' config.json)"

# check integrity
Check_Integrity() {

	# set flag
	local Flag=0

	# check file
	{
		file -E $1 || Flag=1
		rootls $1 || Flag=1
		# ADD MORE CHECKS
	} &>/dev/null

	# remove file if a check is not passed
	if [ $Flag -eq 1 ]; then
		echo "$1 did not pass checks. Remove..."
		rm $1
		return 1
	else
		return 0
	fi
}
# needed to run a function with parallel
export -f Check_Integrity

Status=""
Dir=""
FilesChecked=""
FilesCopied=""

for Run in $Runs; do

	FilesChecked="$(jq -r --arg Run "$Run" '.[$Run].FilesChecked' $StatusFile)"

	if [ "$FilesChecked" == "ALL" ]; then
		break
	fi

	FilesCopied="$(jq -r --arg Run $Run '.[$Run].FilesCopied' $StatusFile)"
	Dir="${LocalOutputDir}/${Run}"
	echo "Checking .root files in $Dir"

	find $Dir -type f -name "*.root" | parallel --progress --bar Check_Integrity {}

	if [ $? -a "$FilesCopied" == "ALL" ]; then
		Status="ALL"
	else
		Status="PARTIAL"
	fi

	(
		flock 100
		jq --arg Run $Run --arg Status $Status 'setpath([$Run,"FilesChecked"];$Status)' $StatusFile | sponge $StatusFile
	) 100>$LockFile
done

exit 0
