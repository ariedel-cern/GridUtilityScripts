#!/bin/bash
# File              : CheckQuota.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.12.2021
# Last Modified Date: 01.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# check if we can submit another masterjob to grid

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# variables
RunningSubjobs="0"
InErrorSubjobs="0"
WaitingSubjobs="0"
RunningTime="0"
CPUCost="0"
MasterjobsNotReady="0"
MasterjobsInError="0"

GetQuota() {
    # fill global variables
    RunningSubjobs=$(alien_ps -X | wc -l)
    InErrorSubjobs=$(alien_ps -E | wc -l)
    WaitingSubjobs=$(alien_ps -W | wc -l)
    RunningTime=$(alien.py quota | awk '/Running time/{gsub("%","",$8);print int($8)}')
    CPUCost=$(alien.py quota | awk '/CPU Cost/{gsub("%","",$6);print int($6)}')
    MasterjobsNotReady=$(alien_ps -M -W | wc -l)
    MasterjobsInError=$(alien_ps -M -E | wc -l)
    return 0
}

echo "################################################################################"
echo "Checking quota"
echo "################################################################################"

GetQuota

echo "$RunningSubjobs Subjobs are running"
echo "$WaitingSubjobs Subjobs are waiting"
echo "$InErrorSubjobs Subjobs are in error"
echo "$RunningTime/${LIMIT_RUNNING_SUBJOBS}% Running time is used"
echo "$CPUCost/${LIMIT_CPU_COST}% CPU cost is used"

if [ $(($RunningSubjobs+$WaitingSubjobs)) -gt $THRESHOLD_SUBJOBS ] || [ $RunningTime -gt $THRESHOLD_RUNNING_TIME ] || [ $CPUCost -gt $THRESHOLD_CPU_COST ]; then
        echo "Threshold exceeded, wait ..."
        echo "$(($RunningSubjobs+$WaitingSubjobs))/$THRESHOLD_SUBJOBS are running/waiting"
        echo "$RunningTime/$THRESHOLD_RUNNING_TIME Running Time was used"
        echo "$CPUCost/$THRESHOLD_CPU_COST CPU cost was used"
        echo "################################################################################"

        exit 1
fi

echo "################################################################################"
echo "Checking quotas passed, checking status of other masterjobs"
echo "################################################################################"

echo "$MasterjobsNotReady masterjobs are not running yet"
echo "$MasterjobsInError masterjobs are in error state"

if [ $MasterjobsNotReady -gt 1 ]; then
        echo "Masterjob not ready, wait ...."
        echo "################################################################################"

        exit 1
fi

if [ $MasterjobsInError -gt 0 ]; then
        echo "Masterjob in error, resubmit and wait ..."

        alien_ps -E -M | awk '{print $2}' | parallel --progress --bar "alien.py resubmit {}"
        echo "################################################################################"

        exit 1
fi

echo "################################################################################"
echo "All checks passed, we are good to go!"
echo "################################################################################"

exit 0
