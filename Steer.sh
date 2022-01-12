#!/bin/bash
# File              : Steer.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.12.2021
# Last Modified Date: 20.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# master steering script for analysis

[ ! -f config.json ] && echo "No config file!!!" && exit 1
StatusFile="$(jq -r '.StatusFile' config.json)"

set -o pipefail

# submit jobs to the grid -> 0. Reincarnation
# (
#     echo $BASHPID
# 	SubmitJobs.sh
# 	echo "ALL RUNS SUBMITTED"
# ) &>"Submit.log" &

# wait for the first run to be submitted

until grep -q "RUNNING" $StatusFile; do
	LongTimeout="$(jq -r '.misc.LongTimeout' config.json)"
	GridTimeout.sh $LongTimeout
done

# update status of running jobs and reincarnate them if necessary
(
	echo $BASHPID
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
	echo $BASHPID
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

# merge files run by run
# (Merge.sh) &>$MERGE_LOG &

echo "FINISHED"

exit 0
