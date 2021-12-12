#!/bin/bash
# File              : Reincarnate.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 30.11.2021
# Last Modified Date: 12.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# reincarnate failed jobs on grid

[ ! -f config.json ] && echo "No config.json file!!!" && exit 1
LockFile="$(jq -r '.LockFile' config.json)"
StatusFile="$(jq -r '.StatusFile' config.json)"
[ ! -f $StatusFile ] && echo "No $StatusFile file!!!" && exit 1

Runs="$(jq -r 'keys[]' $StatusFile)"

# loop variables
Data=""
Re0=""
Re1=""
StatusRe0=""
SubjobErrorRe0=""
Indices=""
LastRe=""
MasterjobIdRe0=""
MasterjobIdRe1=""
GridOutputDirOld=""
GridOutputDirNew=""
FailedSubjobs=""
JdlFileName=""
GridXmlCollection=""
XmlCollection=""
InputFiles=""
TTL=""
JobID=""

for Run in $Runs; do

	# check if we can actually reincarnate something
	[ ! CheckQuota.sh ] && break

	# get data of the run
	Data="$(jq -r --arg Run "$Run" '.[$Run]' $StatusFile)"
	Status="$(jq -r '.Status' <<<$Data)"

	# if the run is already done, i.e. all reincarnations or every subjob in a given reincarnation succeeded, we do not update anymore
	if [ $Status == "DONE" ]; then
		break
	fi

	# iterate over reincarnations

	Indices="$(jq -r 'keys_unsorted[-4:]|length' <<<$Data)"
	Indices="$(($Indices - 1))"
	LastRe="$(jq -r 'keys[-2]' <<<$Data)"

	for Index in $(seq 0 $Indices); do

		Re0="R${Index}"
		StatusRe0="$(jq -r --arg Re $Re0 '.[$Re].Status' <<<$Data)"
		SubjobErrorRe0="$(jq -r --arg Re $Re0 '.[$Re].SubjobError' <<<$Data)"

		# check if reincarnation is still ongoing
		if [ ! "$StatusRe0" == "DONE" ]; then
			break
		fi
		# if we passed this check, this means the reincarnation is done
		# now we have to check if this is the last reincarnation or the
		# current one ended without any subjob failing, the run is done
		if [ "$Re0" == "$LastRe" -o "$SubjobErrorRe0" -eq 0 ]; then
			jq --arg Run "$Run" --arg Status "DONE" 'setpath([$Run,"Status"];$Status)' $StatusFile | sponge $StatusFile
			break
		fi
		# if we end up here, this means this is not the last reincarnation,
		# the current one is done and there are subjob that failed
		# now we need to check if we already kicked off the next reincarnation
		Re1="R$((Index + 1))"
		MasterjobIdRe1="$(jq -r --arg Re $Re1 '.[$Re].MasterjobID' <<<$Data)"
		# if the next reincarnation is running, the masterjob id will not be -1
		[ ! $MasterjobIdRe1 -eq -1 ] && break

		# now we can kick off the next reincarnation!
		GridOutputDirOld="$(jq -r '.task.GridHomeDir' config.json)/$(jq -r '.task.GridWorkDir' config.json)/$(jq -r '.task.GridOutputDir' config.json)"
		GridOutputDirNew="${GridOutputDirOld}/${Run}/${Re1}"

		JdlFileName="${Re1}_${Run}_Reincarnate.jdl"
		XmlCollection="${Re1}_${Run}_Reincarnate.xml"

		GridXmlCollection="$(jq -r '.task.GridXmlCollection' config.json)"

		# get all failed subjobs
		MasterjobIdRe0="$(jq -r --arg Re $Re0 '.[$Re].MasterjobID' <<<$Data)"
		FailedSubjobs="$(alien_ps -m $MasterjobIdRe0 | awk ' $4!~"D" { print $2 }' | tr '\n' ',' | sed s'/,$//')"

		# get xml collection of all failed AODs
		# check if chers and password are there
		curl -L -k --key "$HOME/.globus/userkey.pem" --cert "$HOME/.globus/usercert.pem:$(cat $HOME/.globus/grid)" "http://alimonitor.cern.ch/jobs/xmlof.jsp?pid=${FailedSubjobs}" --output "$XmlCollection"

		# create new working directory on grid
		alien_mkdir -p "$GridOutputDirNew"

		# create new jdl file
		cp "$(jq -r '.task.Jdl' config.json)" "$JdlFileName"

		# adept to reincarnation
		sed -i -e "/nodownload/c    \"LF:${GridOutputDirNew}/\$1,nodownload\"" $JdlFileName
		sed -i -e "/OutputDir\s=/c OutputDir = \"LF:${GridOutputDirNew}/\$2\/#alien_counter_03i#\"; " $JdlFileName
		InputFiles="$(jq -r --argjson I "$((Index + 1))" '.task.FilesPerSubjob[$I]' config.json)"
		sed -i -e "/SplitMaxInputFileNumber/c SplitMaxInputFileNumber = \"$InputFiles\"; " $JdlFileName
		TTL="$(jq -r --argjson I "$((Index + 1))" '.task.TimeToLive[$I]' config.json)"
		sed -i -e "/TTL/c TTL = \"$TTL\"; " $JdlFileName

		# upload to grid
		alien_cp "file:$JdlFileName" "alien:${GridOutputDirNew}/"
		alien_cp "file:$XmlCollection" "alien:${GridOutputDirNew}/"

		# submit new masterjob
		MasterjobIdRe1="$(alien_submit "${GridOutputDirNew}/${JdlFileName}" "${XmlCollection}" $Run -json | jq -r '.results[0].jobId')"

		# update status file
		(
			flock 100
			jq --arg Run "$Run" --arg Re "$Re1" --arg Status "SUBMITTED" 'setpath([$Run,$Re,"Status"];$Status)' $StatusFile | sponge $StatusFile
			jq --arg Run "$Run" --arg Re "$Re1" --arg ID "$MasterjobIdRe1" 'setpath([$Run,$Re,"MasterjobID"];$ID)' $StatusFile | sponge $StatusFile
		) 100>$LockFile

		break
	done
done

exit 0
