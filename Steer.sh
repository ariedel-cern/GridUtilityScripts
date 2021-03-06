#!/bin/bash
# File              : Steer.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.12.2021
# Last Modified Date: 08.02.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# master steering script for analysis

[ ! -f config.json ] && echo "No config file!!!" && exit 1
StatusFile="$(jq -r '.StatusFile' config.json)"

[ ! -f $StatusFile ] && echo "{}" >$StatusFile

echo "Steering Analysis Train..."

# submit jobs to the grid -> 0. Reincarnation
(
	echo "PID:" $BASHPID
	until SubmitJobs.sh; do
		GridTimeout.sh "$(jq -r '.misc.LongTimeout' config.json)"
	done
	echo "ALL RUNS SUBMITTED"
) &>"Submit.log" &

echo "Wait for the first run to be submitted..."
until grep -q "RUNNING" $StatusFile; do
	GridTimeout.sh "$(jq -r '.misc.LongTimeout' config.json)"
done

echo "First run was submitted, start background jobs..."

# update status of running jobs and reincarnate them if necessary
(
	echo "PID:" $BASHPID
	while jq '.[].Merged' $StatusFile | grep -wq "0"; do
		UpdateStatus.sh
		Reincarnate.sh
		GridTimeout.sh "$(jq -r '.misc.LongTimeout' config.json)"
	done
	echo "REINCARNATION DONE"
) &>"Reincarnate.log" &

# copy file from grid
(
	echo "PID:" $BASHPID
	while jq '.[].Merged' $StatusFile | grep -wq "0"; do
		CopyFromGrid.sh
		CheckFileIntegrity.sh
		Merge.sh
		GridTimeout.sh "$(jq -r '.misc.LongTimeout' config.json)"
	done
	echo "COPY DONE"
) &>"Copy.log" &

echo "Analysis Train still going..."
wait
echo "Analysis Train arrived..."

echo "Reterminate output files"
ReTerminate.sh

exit 0
