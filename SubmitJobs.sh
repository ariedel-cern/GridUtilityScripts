#!/bin/bash
# File              : SubmitJobs.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 25.08.2021
# Last Modified Date: 11.10.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# submit jobs to grid

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# exit if there is an unset variable
set -u

# if running locally, call aliroot and run.C macro with default values and bail out
if [ $ANALYSIS_MODE = "local" ]; then
    echo "Running locally over $DataDir"
    echo "with centrality bin edges $(tr '\n' ' ' <<<$CENTRALITY_BIN_EDGES)"
    aliroot -q -l -b run.C
    exit 0
fi

echo "running on Grid"

# protect against overwriting existing analysis results
if alien_find "${GRID_WORKING_DIR_ABS}/*" &>/dev/null; then
    echo "Working directory not empty. Creating backup..."
    alien_mv ${GRID_WORKING_DIR_ABS} ${GRID_WORKING_DIR_ABS}.bak
fi

# will run with offline mode to generate all necessary files
echo "Run steering macros in offline mode to generate necessary files"
aliroot -q -l -b run.C &>/dev/null
echo "Modify jdl to use XML collections in $GRID_XML_COLLECTION"
# TODO
# add support for specifing weights run by run
sed -i -e "s|${GRID_WORKING_DIR_ABS}/\$1,nodownload|${GRID_XML_COLLECTION}/\$1,nodownload|" $JDL_FILE_NAME

echo "Backup generated files"
BackupDir="Offline"
mkdir -p $BackupDir
mv $JDL_FILE_NAME $BackupDir
mv $ANALYSIS_MACRO_FILE_NAME $BackupDir
mv analysis.sh $BackupDir
mv analysis_validation.sh $BackupDir
mv analysis.root $BackupDir

echo "Copy everything we need to grid"
alien_cp "$BackupDir/" "alien://$GRID_WORKING_DIR_ABS/"

#TODO move these variables to gridconfig
# thresholds and limits
Limit_RunningSubjobs="1500"
Threshold_RunningSubjobs="1200"
Threshold_WaitingSubjobs="50"
Threshold_InErrorSubjobs="50"
Limit_RunningTime="100"
Threshold_RunningTime="90"
Limit_CPUCost="100"
Threshold_CPUCost="90"

# variables
RunningSubjobs="0"
InErrorSubjobs="0"
WaitingSubjobs="0"
RunningTime="0"
CPUCost="0"
MasterjobsNotReady="0"
MasterjobsInError="0"
SmallTimeout="20"

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

# submit jobs run by run
for Run in $RUN_NUMBER; do

    #TODO
    #keep log of submitted jobs
    #keep counter Submitted/Total Number of runs

    while :; do

        echo "################################################################################"
        echo "Checking quota"
        echo "################################################################################"

        GetQuota

        echo "$RunningSubjobs/$Limit_RunningSubjobs Subjobs are running"
        echo "$InErrorSubjobs Subjobs are in error"
        echo "$WaitingSubjobs Subjobs are waiting"
        echo "$RunningTime/${Limit_RunningTime}% Running time is used"
        echo "$CPUCost/${Limit_CPUCost}% CPU cost is used"

        if [ $RunningSubjobs -gt $Threshold_RunningSubjobs ] || [ $RunningTime -gt $Threshold_RunningTime ] || [ $CPUCost -gt $Threshold_CPUCost ]; then
            echo "Exeeded threshold, wait for things to calm down..."
            echo "Threshold for number of running jobs: $Threshold_RunningSubjobs"
            echo "Threshold for running time: $Threshold_RunningTime"
            echo "Threshold for CPU cost: $Threshold_CPUCost"

            GridTimeout.sh $TIMEOUT

            continue
        fi

        echo "################################################################################"
        echo "Checking quota passed, checking status of other subjobs"
        echo "################################################################################"

        if [ $InErrorSubjobs -gt $Threshold_InErrorSubjobs ]; then

            echo "$InErrorSubjobs Subjobs are in error state, resubmit them..."
            Resubmit.sh
            GridTimeout.sh $SmallTimeout

            continue
        fi

        if [ $WaitingSubjobs -gt $Threshold_WaitingSubjobs ]; then
            echo "$WaitingSubjobs Subjobs are waiting, lets wait as well..."
            GridTimeout.sh $SmallTimeout

            continue
        fi

        echo "################################################################################"
        echo "Checking status of other subjobs passed, checking status of other masterjobs"
        echo "################################################################################"

        echo "$MasterjobsNotReady masterjobs are not running yet"
        echo "$MasterjobsInError masterjobs are in error state"

        if [ $MasterjobsNotReady -gt 0 ]; then
            echo "Wait for other masterjobs to start running"

            GridTimeout.sh $SmallTimeout

            continue
        fi

        if [ $MasterjobsInError -gt 0 ]; then
            echo "Resubmit masterjobs in error state"

            alien_ps -E -M | awk '{print $2}' | parallel --status --bar "alien.py resubmit {}"

            GridTimeout.sh $SmallTimeout

            continue
        fi

        break

    done

    echo "################################################################################"
    echo "All checks passed, we are good to go!"
    echo "################################################################################"
    echo "Submit Run $Run with Task $TASK_BASENAME with centrality bin edges $(tr '\n' ' ' <<<$CENTRALITY_BIN_EDGES)"

    alien_submit $GRID_WORKING_DIR_ABS/flowAnalysis.jdl "000${Run}.xml" $Run

    echo "Wait for Grid to catch up..."

    GridTimeout.sh $SmallTimeout

done

exit 0
