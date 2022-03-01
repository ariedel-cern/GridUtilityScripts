#!/bin/bash
# File              : Cleanup.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.03.2022
# Last Modified Date: 01.03.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# cleanup analysis

[ ! -f config.json ] && echo "No config.json file!!!" && exit 1
LockFile="$(jq -r '.LockFile' config.json)"
StatusFile="$(jq -r '.StatusFile' config.json)"
[ ! -f $StatusFile ] && echo "No $StatusFile file!!!" && exit 1

echo "Waiting for lock..."
{
	flock 100
	Runs="$(jq -r 'keys[]' $StatusFile)"
} 100>$LockFile

# options from config file
UseWeights=$(jq -r '.task.UseWeights' config.json)

# loop variables
Data=""
Re0=""
Re1=""
AODTotal=""
StatusRe0=""
SubjobActiveRe0=""
SubjobWaitingRe0=""
SubjobErrorRe0=""
Indices=""
LastRe=""
MasterjobIdRe0=""
MasterjobIdRe1=""
GridOutputDirOld=""
GridOutputDirNew=""
LocalWorkDir=""
FailedSubjobs=""
JdlFileName=""
GridXmlCollection=""
XmlCollection=""
InputFiles=""
TTL=""
JobID=""

for Run in $Runs; do

	# get data of the run
	echo "Waiting for lock..."
	{
		flock 100
		Data="$(jq -r --arg Run "$Run" '.[$Run]' $StatusFile)"
	} 100>$LockFile
	Status="$(jq -r '.Status' <<<$Data)"

	echo "Cleanup after Run $Run"

	if [ "$Status" == "DONE" ]; then
		echo "$Run is already DONE!"
		continue
	fi

	# get all indices
	Indices="$(jq -r 'keys_unsorted[-4:]|length' <<<$Data)"
	Indices="$(($Indices - 1))"
	# get index of last reincarnation
	LastRe="$(jq -r 'keys[-2]' <<<$Data)"
	# get number of total AODs
	TotalAOD="$(jq -r '.R0.AODTotal' <<<$Data)"

	# iterate over reincarnations
	for Index in $(seq 0 $Indices); do

		# get stats of reincarnation
		Re0="R${Index}"

		echo "Working on Reincarnation $Re0"

		StatusRe0="$(jq -r --arg Re $Re0 '.[$Re].Status' <<<$Data)"

		# skip if reincarnation is already done
		if [ "$StatusRe0" == "DONE" ]; then
			echo "Reincarnation is already DONE. Continue..."
		fi

		echo "Start Cleanup"

		# change to local work dir
		if [ "$UseWeights" = "false" ]; then
			LocalWorkDir="GridFiles/Dummy"
		else
			LocalWorkDir="GridFiles/${Run}"
		fi
		cd $LocalWorkDir

		# get masterjobID for killing it
		MasterjobIdRe0="$(jq -r --arg Re "$Re0" '.[$Re].MasterjobID' <<<$Data)"
		# get the failed subjobs
		FailedSubjobs="$(alien_ps -m $MasterjobIdRe0 | awk ' $4!~"D" { print $2 }' | tr '\n' ',' | sed s'/,$//')"
		# download xml collection to count the failed AODs
		XmlCollection="Discarded_${Run}_Reincarnate.xml"
		curl --retry 10 -L -k --key "$HOME/.globus/userkey.pem" --cert "$HOME/.globus/usercert.pem:$(cat $HOME/.globus/grid)" "http://alimonitor.cern.ch/jobs/xmlof.jsp?pid=${FailedSubjobs}" --output "$XmlCollection"
		# get the number of failed AODs
		FailedAODs="$(grep "event name" $XmlCollection | tail -n1 | awk -F\" '{print $2}')"

		# come back
		cd -

		# write to status file
		echo "Waiting for lock..."
		{
			flock 100
			jq --arg Run "$Run" --arg Re "$Re0" 'setpath([$Run,$Re,"Status"];"DONE")' $StatusFile | sponge $StatusFile
			jq --arg Run "$Run" --arg Re "$Re0" --arg AODError "${FailedAODs:=-44}" 'setpath([$Run,$Re,"AODError"];$AODError)' $StatusFile | sponge $StatusFile
			jq --arg Run "$Run" 'setpath([$Run,"Status"];"DONE")' $StatusFile | sponge $StatusFile
		} 100>$LockFile

		# kill masterjob
		alien.py kill "$MasterjobID"

		break

	done
done

exit 0
