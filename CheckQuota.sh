#!/bin/bash
# File              : CheckQuota.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.12.2021
# Last Modified Date: 20.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# check if we can submit another masterjob to grid

[ ! -f config.json ] && echo "No config file!!!" && exit 1

# get variables from config file
ThresholdActiveSubjobs="$(jq -r '.misc.ThresholdActiveSubjob' config.json)"
ThresholdRunningTime="$(jq -r '.misc.ThresholdRunningTime' config.json)"
ThresholdCpuCost="$(jq -r '.misc.ThresholdCpuCost' config.json)"

# variables
ActiveSubjobs="0"
CPUCost="0"
MasterjobsNotReady="0"
MasterjobsInError="0"

GetQuota() {
	# fill global variables
	ActiveSubjobs=$(alien_ps -X | wc -l)
	RunningTime=$(alien.py quota | awk '/Running time/{gsub("%","",$(NF-1));print int($(NF-1))}')
	CPUCost=$(alien.py quota | awk '/CPU Cost/{gsub("%","",$(NF-1));print int($(NF-1))}')
	MasterjobsNotReady=$(alien_ps -M -W | wc -l)
	MasterjobsInError=$(alien_ps -M -E | wc -l)
	return 0
}

echo "################################################################################"
echo "Checking quota"
echo "################################################################################"

GetQuota

echo "$ActiveSubjobs Subjobs are active"
echo "$RunningTime/100% Running time is used"
echo "$CPUCost/100% CPU cost is used"

if [ $ActiveSubjobs -gt $ThresholdActiveSubjobs ] || [ $RunningTime -gt $ThresholdRunningTime ] || [ $CPUCost -gt $ThresholdCpuCost ]; then
	echo "Threshold exceeded, wait ..."
	echo "$ActiveSubjobs/$ThresholdActiveSubjobs are running/waiting"
	echo "$RunningTime/$ThresholdRunningTime Running Time was used"
	echo "$CPUCost/$ThresholdCpuCost CPU cost was used"
	echo "################################################################################"

	exit 1
fi

echo "################################################################################"
echo "Checking quotas passed, checking status of other masterjobs"
echo "################################################################################"

echo "$MasterjobsNotReady masterjobs are not running yet"
if [ $MasterjobsNotReady -gt 0 ]; then
	echo "Another Masterjob is not running yet, wait ...."
	echo "################################################################################"

	exit 1
fi

if [ $MasterjobsInError -gt 0 ]; then
	echo "Another Masterjob is in error, resubmit and wait ..."

	alien_ps -E -M | awk '{print $2}' | parallel --progress --bar "alien.py resubmit {}"
	echo "################################################################################"

	exit 1
fi

echo "################################################################################"
echo "All checks passed, we are good to go!"
echo "################################################################################"

exit 0
