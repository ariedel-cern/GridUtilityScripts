#!/bin/bash
# File              : Steer.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.12.2021
# Last Modified Date: 07.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# master steering script for analysis

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# before running make sure that weights are available and that the split for bootstrap is known

# submit jobs to the grid -> 1. Reincarnation
(SubmitJobs.sh) &>$SUBMIT_LOG &

# update status of running jobs
(UpdateStatus.sh) &>$GETMETADATA_LOG &

# reincarnate failed jobs
# (Reincarnate.sh) &>$REINCARNATE_LOG &

# copy file from grid
# (CopyFromGrid.sh) &>$COPY_LOG &

# check integrity of copied files
# (CheckFileIntegrity.sh) &>$CHECKINTEGRITY_LOG &

# merge files run by run
# (Merge.sh) &>$MERGE_LOG &

echo "Analysis Train still going..."
wait

echo "FINISHED"

exit 0
