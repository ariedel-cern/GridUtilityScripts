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
	SubjobTotal="${SubjobTotal:=0}"

	SubjobDone="$(awk '/DONE:/{print $NF}' <<<$MasterjobData)"
	SubjobDone="${SubjobDone:=0}"

	SubjobWaiting="$(awk '/WAITING:/{print $NF}' <<<$MasterjobData)"
	SubjobWaiting="${SubjobWaiting:=0}"

	local SubjobRunning="$(awk '/RUNNING:/{print $NF}' <<<$MasterjobData)"
	SubjobRunning="${SubjobRunning:=0}"
	local SubjobAssigned="$(awk '/ASSIGNED:/{print $NF}' <<<$MasterjobData)"
	SubjobAssigned="${SubjobAssigned:=0}"
	local SubjobStarted="$(awk '/STARTED:/{print $NF}' <<<$MasterjobData)"
	SubjobStarted="${SubjobStarted:=0}"
	local SubjobSaving="$(awk '/SAVEING:/{print $NF}' <<<$MasterjobData)"
	SubjobSaving="${SubjobSaving:=0}"

	SubjobActive="$(($SubjobRunning + $SubjobAssigned + $SubjobStarted + $SubjobSaving))"
	SubjobActive="${SubjobActive:=0}"

	SubjobError=$(($SubjobTotal - $SubjobDone - $SubjobWaiting - $SubjobActive))
	SubjobError="${SubjobError:=0}"

}

for Run in $Runs; do

	echo "Update Run: $Run"

	# get data of the run
    {
        flock 100
	    Data="$(jq -r --arg Run "$Run" '.[$Run]' $StatusFile)"
    } 100>$LockFile

	Status="$(jq -r '.Status' <<<$Data)"

	# if the run is already done, i.e. all reincarnations or every subjob in a given reincarnation succeeded, we do not update anymore
	if [ $Status == "DONE" ]; then
		echo "$Run is DONE!"
		continue
	fi

	# iterate over reincarnations
	Reincarnations="$(jq -r 'keys_unsorted[-4:][]' <<<$Data)"

	for Reincarnation in $Reincarnations; do

		MasterjobID="$(jq -r --arg Re $Reincarnation '.[$Re].MasterjobID' <<<$Data)"
		[ "$MasterjobID" -eq -1 ] && break

		# Status="$(jq -r '.Status' <<<$Data)"
		# [ "$Status" == "DONE" ] && break

		GetData

		echo "with Reincarnation $Reincarnation -> $MasterjobID"
		# update values
        { flock 100
                jq --arg Run "$Run" --arg Re "$Reincarnation" --arg Status "$MasterjobStatus" 'setpath([$Run,$Re,"Status"];$Status)' $StatusFile | sponge $StatusFile
                jq --arg Run "$Run" --arg Re "$Reincarnation" --arg Total "$SubjobTotal" 'setpath([$Run,$Re,"SubjobTotal"];$Total)' $StatusFile | sponge $StatusFile
                jq --arg Run "$Run" --arg Re "$Reincarnation" --arg Done "$SubjobDone" 'setpath([$Run,$Re,"SubjobDone"];$Done)' $StatusFile | sponge $StatusFile
                jq --arg Run "$Run" --arg Re "$Reincarnation" --arg Waiting "$SubjobWaiting" 'setpath([$Run,$Re,"SubjobWaiting"];$Waiting)' $StatusFile | sponge $StatusFile
                jq --arg Run "$Run" --arg Re "$Reincarnation" --arg Active "$SubjobActive" 'setpath([$Run,$Re,"SubjobActive"];$Active)' $StatusFile | sponge $StatusFile
                jq --arg Run "$Run" --arg Re "$Reincarnation" --arg Error "$SubjobError" 'setpath([$Run,$Re,"SubjobError"];$Error)' $StatusFile | sponge $StatusFile
        } 100>$LockFile

	done

done

exit 0
