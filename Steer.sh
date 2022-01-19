#!/bin/bash
# File              : Steer.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.12.2021
# Last Modified Date: 18.01.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# master steering script for analysis

[ ! -f config.json ] && echo "No config file!!!" && exit 1
StatusFile="$(jq -r '.StatusFile' config.json)"
touch $StatusFile

set -o pipefail

# submit jobs to the grid -> 0. Reincarnation
(
	echo "PID:" $BASHPID
	SubmitJobs.sh
	echo "ALL RUNS SUBMITTED"
) &>"Submit.log" &

echo "Wait for the first run to be submitted..."

until grep -q "RUNNING" $StatusFile; do
	LongTimeout="$(jq -r '.misc.LongTimeout' config.json)"
	GridTimeout.sh $LongTimeout
done

echo "First run was submitted, start background jobs..."

# update status of running jobs and reincarnate them if necessary
(
	echo "PID:" $BASHPID
	while jq '.[].Status' $StatusFile | grep -q "RUNNING"; do
		UpdateStatus.sh
		Reincarnate.sh
		LongTimeout="$(jq -r '.misc.LongTimeout' config.json)"
		GridTimeout.sh $LongTimeout
	done

	echo "REINCARNATION DONE"
) &>"Reincarnate.log" &

# copy file from grid
(
	echo "PID:" $BASHPID
	while jq '.[].Status' $StatusFile | grep -q "RUNNING"; do
		CopyFromGrid.sh
		CheckFileIntegrity.sh
		LongTimeout="$(jq -r '.misc.LongTimeout' config.json)"
		GridTimeout.sh $LongTimeout
	done
	echo "COPY DONE"
) &>"Copy.log" &

echo "Analysis Train still going..."
wait
echo "Analysis Train finished..."

# merge files run by run
echo "Start merging..."
Merge.sh &>$MERGE_LOG
echo "Stop merging..."

echo "FINISHED"

exit 0
