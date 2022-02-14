#!/bin/bash
# File              : Reincarnate.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 30.11.2021
# Last Modified Date: 07.02.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# reincarnate failed jobs on grid

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

	# check if we can actually reincarnate something
	[ ! CheckQuota.sh ] && continue

	# get data of the run
	echo "Waiting for lock..."
	{
		flock 100
		Data="$(jq -r --arg Run "$Run" '.[$Run]' $StatusFile)"
	} 100>$LockFile
	Status="$(jq -r '.Status' <<<$Data)"

	echo "Reincarnate Run $Run"

	# if the run is already done, i.e. all reincarnations or every subjob in a given reincarnation succeeded, we do not update anymore
	if [ "$Status" == "DONE" ]; then
		echo "$Run is DONE!"
		continue
	fi

	# iterate over reincarnations
	Indices="$(jq -r 'keys_unsorted[-4:]|length' <<<$Data)"
	Indices="$(($Indices - 1))"
	LastRe="$(jq -r 'keys[-2]' <<<$Data)"

	for Index in $(seq 0 $Indices); do

		Re0="R${Index}"
		StatusRe0="$(jq -r --arg Re $Re0 '.[$Re].Status' <<<$Data)"
		SubjobActiveRe0="$(jq -r --arg Re $Re0 '.[$Re].SubjobActive' <<<$Data)"
		SubjobWaitingRe0="$(jq -r --arg Re $Re0 '.[$Re].SubjobWaiting' <<<$Data)"
		SubjobErrorRe0="$(jq -r --arg Re $Re0 '.[$Re].SubjobError' <<<$Data)"

		echo "Working on Reincarnation $Re0"

		# check if a reincarnation is still ongoing
		if [ ! "$StatusRe0" == "DONE" ]; then
			# now check if there are jobs running
			SubjobActiveRe0="${SubjobActive:=-44}"
			if [ "${SubjobActiveRe0#-}" -gt 0 ]; then
				# if there are, we do not need to reincarnate
				echo "Reincarnation $Re0 still going, break..."
				break
			fi

			# now check the number of waiting subjobs
			# if there are only a few, we can reincarnate
			if [ "$SubjobWaitingRe0" -gt "$(jq '.misc.ThresholdReincarnateWaitingJobs' config.json)" ]; then
				echo "Reincarnation $Re0 still has a few jobs in the queue, break ..."
				break
			fi

		fi
		# if we passed this check, this means the reincarnation is done

		# check if this is the last reincarnation
		if [ "${Re0:=R0}" == "${LastRe:=R3}" ]; then
			echo "Last Reincarnation $Re0, Run $Run is DONE!"
			echo "Waiting for lock..."
			{
				flock 100
				jq --arg Run "$Run" --arg Re "$Re0" --arg Error "${SubjobErrorRe0:=-44}" 'setpath([$Run,$Re,"AODError"];$Error)' $StatusFile | sponge $StatusFile
				jq --arg Run "$Run" --arg Status "DONE" 'setpath([$Run,"Status"];$Status)' $StatusFile | sponge $StatusFile
			} 100>$LockFile
			break
		fi

		# check if the reincarnation finished without a subjob in error
		if [ "${SubjobErrorRe0:=-44}" -eq 0 -a "${StatusRe0:=SPLIT}" == "DONE" ]; then
			echo "Reincarnation $Re0 finished without a failed subjob, Run $Run is DONE!"
			echo "Waiting for lock..."
			{
				flock 100
				jq --arg Run "$Run" --arg Re "$Re0" --arg Zero "0" 'setpath([$Run,$Re,"AODError"];$Zero)' $StatusFile | sponge $StatusFile
				jq --arg Run "$Run" --arg Status "DONE" 'setpath([$Run,"Status"];$Status)' $StatusFile | sponge $StatusFile
			} 100>$LockFile
			break
		fi

		# if we end up here, this means this is not the last reincarnation,
		# the current one is done and there are subjob that failed
		# now we need to check if we already kicked off the next reincarnation
		Re1="R$(($Index + 1))"
		MasterjobIdRe1="$(jq -r --arg Re $Re1 '.[$Re].MasterjobID' <<<$Data)"
		StatusRe1="$(jq -r --arg Re $Re1 '.[$Re].Status' <<<$Data)"

		# if the next reincarnation is running, the masterjob id will not be -44
		if [ "$MasterjobIdRe1" -ne "-44" ]; then
			echo "Reincarnation $Re1 is already under way, skip $Re0 ->$MasterjobIdRe1"
			continue
		fi

		# now we can kick off the next reincarnation!
		echo "Kick of Reincarnation $Re1 in Run $Run"

		GridOutputDirOld="$(jq -r '.task.GridHomeDir' config.json)/$(jq -r '.task.GridWorkDir' config.json)/$(jq -r '.task.GridOutputDir' config.json)"
		GridOutputDirNew="${GridOutputDirOld}/${Run}/${Re1}"

		JdlFileName="${Re1}_${Run}_Reincarnate.jdl"
		XmlCollection="${Re1}_${Run}_Reincarnate.xml"

		GridXmlCollection="$(jq -r '.task.GridXmlCollection' config.json)"

		# get all failed subjobs, including the ones we do not wait for
		MasterjobIdRe0="$(jq -r --arg Re "$Re0" '.[$Re].MasterjobID' <<<$Data)"
		FailedSubjobs="$(alien_ps -m $MasterjobIdRe0 | awk ' $4!~"D" { print $2 }' | tr '\n' ',' | sed s'/,$//')"

		# check if FailedSubjobs are empty
		if [ -z "$FailedSubjobs" ]; then
			break
		fi

		# change to local work dir
		if [ "$UseWeights" = "false" ]; then
			LocalWorkDir="GridFiles/Dummy"
		else
			LocalWorkDir="GridFiles/${Run}"
		fi
		cd $LocalWorkDir

		echo "Download XML collection of failed subjobs"
		curl --retry 10 -L -k --key "$HOME/.globus/userkey.pem" --cert "$HOME/.globus/usercert.pem:$(cat $HOME/.globus/grid)" "http://alimonitor.cern.ch/jobs/xmlof.jsp?pid=${FailedSubjobs}" --output "$XmlCollection"

		# check if we managed to download a xml collection
		# if not, break for now
		if ! grep -q "event name" "$XmlCollection"; then
			cd -
			break
		fi

		# get number of AODs which failed in this reincarnation
		FailedAODs="$(grep "event name" $XmlCollection | tail -n1 | awk -F\" '{print $2}')"

		# create new working directory on grid
		alien_mkdir -p "$GridOutputDirNew"

		# create new jdl file
		cp "$(jq -r '.task.Jdl' ../../config.json)" "$JdlFileName"

		# adept to reincarnation
		sed -i -e "/nodownload/c    \"LF:${GridOutputDirNew}/\$1,nodownload\"" $JdlFileName
		sed -i -e "/OutputDir\s=/c OutputDir = \"${GridOutputDirNew}/\$2\/#alien_counter_03i#\";" $JdlFileName
		InputFiles="$(jq -r --argjson I "$((Index + 1))" '.task.FilesPerSubjob[$I]' ../../config.json)"
		sed -i -e "/SplitMaxInputFileNumber/c SplitMaxInputFileNumber = \"$InputFiles\";" $JdlFileName
		TTL="$(jq -r --argjson I "$((Index + 1))" '.task.TimeToLive[$I]' ../../config.json)"
		sed -i -e "/TTL/c TTL = \"$TTL\"; " $JdlFileName

		# upload to grid
		{
			timeout 180 alien_cp "file:$JdlFileName" "alien:${GridOutputDirNew}/" -retry 10
			timeout 180 alien_cp "file:$XmlCollection" "alien:${GridOutputDirNew}/" -retry 10
		} || exit 2

		# kill waiting jobs
		alien_ps -m $MasterjobIdRe0 | awk ' $4=="W" { print $2 }' | parallel --bar --progress "alien.py kill {}"

		# submit new masterjob
		MasterjobIdRe1="null"
		until [ "$MasterjobIdRe1" != "null" ]; do
			MasterjobIdRe1="$(alien_submit "${GridOutputDirNew}/${JdlFileName}" "${XmlCollection}" "$Run" -json | jq -r '.results[0].jobId')"
		done

		# switch back
		cd -

		echo "Submitted new Masterjob with ID $MasterjobIdRe1"

		# update status file
		echo "Waiting for lock..."
		{
			flock 100
			jq --arg Run "$Run" --arg Re "$Re1" --arg Status "SUBMITTED" 'setpath([$Run,$Re,"Status"];$Status)' $StatusFile | sponge $StatusFile
			jq --arg Run "$Run" --arg Re "$Re1" --arg ID "${MasterjobIdRe1:=-44}" 'setpath([$Run,$Re,"MasterjobID"];$ID)' $StatusFile | sponge $StatusFile
			jq --arg Run "$Run" --arg Re "$Re1" --arg AOD "${FailedAODs:=-44}" 'setpath([$Run,$Re,"AODTotal"];$AOD)' $StatusFile | sponge $StatusFile
			jq --arg Run "$Run" --arg Re "$Re0" --arg AOD "${FailedAODs:=-44}" 'setpath([$Run,$Re,"AODError"];$AOD)' $StatusFile | sponge $StatusFile
			jq --arg Run "$Run" --arg Re "$Re0" 'setpath([$Run,$Re,"Status"];"DONE")' $StatusFile | sponge $StatusFile
		} 100>$LockFile

		break
	done
done

exit 0
