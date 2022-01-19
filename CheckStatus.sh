#!/bin/bash
# File              : CheckStatus.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 20.12.2021
# Last Modified Date: 19.01.2022
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
			TotalSubjob=$(($TotalSubjob + $RunSubjob))

			RunDoneSubjob=$(jq -r --arg Re $Reincarnation '.[$Re].SubjobDone' <<<$Data)
			TotalDoneSubjob=$(($TotalDoneSubjob + $RunDoneSubjob))

			RunSubjobSucess=$(echo "scale=2; ${RunDoneSubjob:=0}/${RunSubjob:=1}" | bc)
			RunAODSuccess=$(echo "scale=2; ${RunDoneAOD:=0}/${RunAOD:=1}" | bc)
			Column+="$(printf "%1.2f" $RunAODSuccess)|$(printf "%1.2f" $RunSubjobSucess),"

		else
			Column+="----|----,"
		fi

	done

	TotalDoneAOD=$(($TotalDoneAOD + $RunDoneAOD))

	# string for header before the first row
	[ $Bool -eq 0 ] && Table+="$Header\n" && Bool="1"
	Table+="$Column\n"

done

echo "###############################################################################"
echo -e $Table | column -s ',' -t
echo "###############################################################################"

TotalSubjobSuccess=$(echo "scale=2; $TotalDoneSubjob/$TotalSubjob" | bc)
TotalAODSuccess=$(echo "scale=2; $TotalDoneAOD/$TotalAOD" | bc)

cat <<EOF | column -s ',' -t
Total stats,
Total number of AODs,$TotalAOD 
Total number of processed AODs,$TotalDoneAOD
Total AOD success rate,$(printf "%1.2f" $TotalAODSuccess)
Total number of submitted subjobs,$TotalSubjob
Total number of successfull subjobs,$TotalDoneSubjob
Total Subjob Success Rate,$(printf "%1.2f" $TotalSubjobSuccess)
EOF

echo "###############################################################################"
exit 0
