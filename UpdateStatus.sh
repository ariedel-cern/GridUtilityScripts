#!/bin/bash
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 30.11.2021
# Last Modified Date: 08.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# update masterjob status information

[ ! -f config.json ] && echo "No config.json file!!!" && exit 1
LockFile="$(jq -r '.LockFile' config.json)"
StatusFile="$(jq -r '.StatusFile' config.json)"
[ ! -f $StatusFile ] && echo "No $StatusFile file!!!" && exit 1

Runs=""
echo "Waiting for lock..."
{
	flock 100
	cp $StatusFile "${StatusFile}.bak"
	Runs="$(jq -r 'keys[]' $StatusFile)"
} 100>$LockFile

Data=""
Status=""

Reincarnations=""
MasterjobID=""
MasterjobStatus=""
SubjobTotal=""
SubjobDone=""
SubjobActive=""
SubjobWaiting=""
SubjobError=""

GetData() {

	local MasterjobData="$(alien.py masterjob $MasterjobID)"

	MasterjobStatus=$(awk '/status:/{print $NF}' <<<$MasterjobData)
	SubjobTotal="$(awk '/total/{print $(NF-1)}' <<<$MasterjobData)"

	SubjobDone="$(awk '/DONE:/{print $NF}' <<<$MasterjobData)"

	SubjobWaiting="$(awk '/WAITING:/{print $NF}' <<<$MasterjobData)"

	local SubjobRunning="$(awk '/RUNNING:/{print $NF}' <<<$MasterjobData)"
	local SubjobAssigned="$(awk '/ASSIGNED:/{print $NF}' <<<$MasterjobData)"
	local SubjobStarted="$(awk '/STARTED:/{print $NF}' <<<$MasterjobData)"
	local SubjobSaving="$(awk '/SAVEING:/{print $NF}' <<<$MasterjobData)"

	SubjobActive="$((${SubjobRunning:=0} + ${SubjobAssigned:=0} + ${SubjobStarted:=0} + ${SubjobSaving:=0}))"

	SubjobError=$((${SubjobTotal:=0} - ${SubjobDone:=0} - ${SubjobWaiting:=0} - ${SubjobActive:=0}))
}

for Run in $Runs; do

	echo "Update Run: $Run"

	# get data of the run
	echo "Waiting for lock..."
	{
		flock 100
		Data="$(jq -r --arg Run "$Run" '.[$Run]' $StatusFile)"
	} 100>$LockFile

	Status="$(jq -r '.Status' <<<$Data)"

	[ "$Status" == "DONE" ] && continue

	# iterate over reincarnations
	Reincarnations="$(jq -r 'keys_unsorted[-4:][]' <<<$Data)"

	for Reincarnation in $Reincarnations; do

		# if the masterjob is DONE, skip to the next reincarnation
		Status="$(jq -r --arg Re $Reincarnation '.[$Re].Status' <<<$Data)"

		[ "$Status" == "DONE" ] && continue

		MasterjobID="$(jq -r --arg Re $Reincarnation '.[$Re].MasterjobID' <<<$Data)"
		[ "${MasterjobID:=-44}" -eq "-44" ] && break

		GetData

		echo "with Reincarnation $Reincarnation -> $MasterjobID"

		# update values
		echo "Waiting for lock..."
		{
			flock 100
			jq --arg Run "$Run" --arg Re "$Reincarnation" --arg Status "${MasterjobStatus:=RUNNING}" 'setpath([$Run,$Re,"Status"];$Status)' $StatusFile | sponge $StatusFile
			jq --arg Run "$Run" --arg Re "$Reincarnation" --arg Total "${SubjobTotal:=-44}" 'setpath([$Run,$Re,"SubjobTotal"];$Total)' $StatusFile | sponge $StatusFile
			jq --arg Run "$Run" --arg Re "$Reincarnation" --arg Done "${SubjobDone:=-44}" 'setpath([$Run,$Re,"SubjobDone"];$Done)' $StatusFile | sponge $StatusFile
			jq --arg Run "$Run" --arg Re "$Reincarnation" --arg Waiting "${SubjobWaiting:=-44}" 'setpath([$Run,$Re,"SubjobWaiting"];$Waiting)' $StatusFile | sponge $StatusFile
			jq --arg Run "$Run" --arg Re "$Reincarnation" --arg Active "${SubjobActive:=-44}" 'setpath([$Run,$Re,"SubjobActive"];$Active)' $StatusFile | sponge $StatusFile
			jq --arg Run "$Run" --arg Re "$Reincarnation" --arg Error "${SubjobError:=-44}" 'setpath([$Run,$Re,"SubjobError"];$Error)' $StatusFile | sponge $StatusFile
		} 100>$LockFile

	done

done

exit 0
