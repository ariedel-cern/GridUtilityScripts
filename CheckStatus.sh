#!/bin/bash
# File              : CheckStatus.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 20.12.2021
# Last Modified Date: 08.02.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# check status of analysis train

[ ! -f config.json ] && echo "No config file!!!" && exit 1
LockFile="$(jq -r '.LockFile' config.json)"
StatusFile="$(jq -r '.StatusFile' config.json)"
[ ! -f $StatusFile ] && echo "No $StatusFile file!!!" && exit 1

{
	flock 100
	Runs="$(jq -r 'keys[]' $StatusFile)"
} 100>$LockFile

# loop variables
Data=""

TotalSubjob="0"
TotalDoneSubjob="0"
RunSubjob="0"
RunDoneSubjob="0"

TotalAOD="0"
TotalDoneAOD="0"
RunAOD="0"
RunDoneAOD="0"

TotalAODSuccess="0"
RunAODSuccess="0"
TotalSubjobSuccess="0"
RunSubjobSucess="0"

NumberOfRuns="0"
NuberOfDoneRuns="0"

Column=""
Status=""
Table=""

Header="Run,Status"
Bool="0"

for Run in $Runs; do

	# get data for this run
	{
		flock 100
		Data="$(jq -r --arg Run "$Run" '.[$Run]' $StatusFile)"
	} 100>$LockFile

	# clear variables
	Column=""
	RunDoneAOD="0"

	((NumberOfRuns++))

	if [ "$(jq -r '.Status' <<<$Data)" == "DONE" ]; then
		((NuberOfDoneRuns++))
	fi

	# First entry in the row is run number
	Column+="$Run,"

	# second entry is status of the Run
	Status="$(jq -r '.Status' <<<$Data)"
	Column+="$Status,"

	# iterate over Reincarnation
	Reincarnations="$(jq -r 'keys_unsorted[-4:][]' <<<$Data)"
	for Reincarnation in $Reincarnations; do

		# string for header, only construct it once
		[ $Bool -eq 0 ] && Header+=",${Reincarnation}"

		# get status of the masterjob of the current reincarnation
		Status="$(jq -r --arg Re $Reincarnation '.[$Re].Status' <<<$Data)"

		# only use data if the reincarnation is DONE
		if [ $Status = "DONE" ]; then

			if [ $Reincarnation = "R0" ]; then
				RunAOD=$(jq -r --arg Re $Reincarnation '.[$Re].AODTotal' <<<$Data)
				TotalAOD=$(($TotalAOD + $RunAOD))
			fi

			RunDoneAOD=$(($RunDoneAOD + $(jq -r --arg Re $Reincarnation '.[$Re].AODTotal' <<<$Data) - $(jq -r --arg Re $Reincarnation '.[$Re].AODError' <<<$Data)))

			RunSubjob=$(jq -r --arg Re $Reincarnation '.[$Re].SubjobTotal' <<<$Data)
			TotalSubjob=$((${TotalSubjob:=0} + ${RunSubjob:=0}))

			RunDoneSubjob=$(jq -r --arg Re $Reincarnation '.[$Re].SubjobDone' <<<$Data)
			TotalDoneSubjob=$((${TotalDoneSubjob:=0} + ${RunDoneSubjob:0}))

			RunSubjobSucess=$(echo "scale=2; ${RunDoneSubjob:=0}/${RunSubjob:=1}" | bc)
			RunAODSuccess=$(echo "scale=2; ${RunDoneAOD:=0}/${RunAOD:=1}" | bc)
			Column+="$(printf "%1.2f" $RunAODSuccess)|$(printf "%1.2f" $RunSubjobSucess),"

		else
			Column+="----|----,"
		fi

	done

	TotalDoneAOD=$((${TotalDoneAOD:=0} + ${RunDoneAOD:=0}))

	# string for header before the first row
	[ $Bool -eq 0 ] && Table+="$Header\n" && Bool="1"
	Table+="$Column\n"

done

echo "###############################################################################"
echo -e $Table | column -s ',' -t
echo "###############################################################################"

TotalSubjobSuccess=$(echo "scale=2; ${TotalDoneSubjob:=0}/${TotalSubjob:=1}" | bc)
TotalAODSuccess=$(echo "scale=2; ${TotalDoneAOD:=0}/${TotalAOD:=1}" | bc)

cat <<EOF | column -s ',' -t
Summary,
Runs,${NuberOfDoneRuns}/${NumberOfRuns}
Number of AODs,$TotalAOD 
Number of processed AODs,$TotalDoneAOD
AOD success rate,$(printf "%1.2f" $TotalAODSuccess)
Number of submitted subjobs,$TotalSubjob
Number of successfull subjobs,$TotalDoneSubjob
Subjob Success Rate,$(printf "%1.2f" $TotalSubjobSuccess)
EOF

echo "###############################################################################"
exit 0
