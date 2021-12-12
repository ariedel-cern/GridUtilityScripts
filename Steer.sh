#!/bin/bash
# File              : Steer.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.12.2021
# Last Modified Date: 12.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# master steering script for analysis

[ ! -f config.json ] && echo "No config file!!!" && exit 1
ShortTimeout="$(jq -r '.misc.ShortTimeout' config.json)"
LongTimeout="$(jq -r '.misc.ShortTimeout' config.json)"

set -o pipefail

# submit jobs to the grid -> 0. Reincarnation
(
	SubmitJobs.sh
	echo "ALL RUNS SUBMITTED"
) &>"Submit.log" &

# update status of running jobs
(
	while jq '.[].Status' STATUS.json | grep "RUNNING" -q; do
		UpdateStatus.sh
		GridTimeout.sh $ShortTimeout
	done

) &>"UpdateStatus.log" &

# reincarnate failed jobs
(
	while jq '.[].Status' STATUS.json | grep "RUNNING" -q; do
		Reincarnate.sh
		GridTimeout.sh $ShortTimeout
	done

	echo "REINCARNATION DONE"
) &>"Reincarnate.log" &

# copy file from grid
(
	while jq '.[].Status' STATUS.json | grep "RUNNING" -q; do
		CopyFromGrid.sh
		CheckFileIntegrity.sh
		GridTimeout.sh $LongTimeout
	done
	echo "COPY DONE"
) &>"Copy.log" &

# merge files run by run
# (Merge.sh) &>$MERGE_LOG &

echo "Analysis Train still going..."
wait

echo "FINISHED"

exit 0
