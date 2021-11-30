#!/bin/bash
# File              : SubmitJobs.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 25.08.2021
# Last Modified Date: 30.11.2021
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
    alien_mv ${GRID_WORKING_DIR_ABS} ${GRID_WORKING_DIR_ABS}.bak || exit 1
fi

# will run with offline mode to generate all necessary files
echo "Run steering macros in offline mode to generate necessary files"
aliroot -q -l -b run.C
echo "Modify jdl to use XML collections in $GRID_XML_COLLECTION"
# TODO
# add support for specifing weights run by run
sed -i -e "s|${GRID_WORKING_DIR_ABS}/\$1,nodownload|${GRID_XML_COLLECTION}/\$1,nodownload|" $JDL_FILE_NAME

mv $JDL_FILE_NAME $LOCAL_TMP_DIR
mv $ANALYSIS_MACRO_FILE_NAME $LOCAL_TMP_DIR
mv analysis.sh $LOCAL_TMP_DIR
mv analysis_validation.sh $LOCAL_TMP_DIR
mv analysis.root $LOCAL_TMP_DIR

echo "Copy everything we need to grid"
alien_cp "file://$LOCAL_TMP_DIR/$JDL_FILE_NAME" "alien://$GRID_WORKING_DIR_ABS/" || exit 2
alien_cp "file://$LOCAL_TMP_DIR/$ANALYSIS_MACRO_FILE_NAME" "alien://$GRID_WORKING_DIR_ABS/" || exit 2
alien_cp "file://$LOCAL_TMP_DIR/$analysis.sh" "alien://$GRID_WORKING_DIR_ABS/" || exit 2
alien_cp "file://$LOCAL_TMP_DIR/$analysis_validation.sh" "alien://$GRID_WORKING_DIR_ABS/" || exit 2
alien_cp "file://$LOCAL_TMP_DIR/$analysis.root" "alien://$GRID_WORKING_DIR_ABS/" || exit 2

[ -f $TMP_MASTERJOBS ] && rm $TMP_MASTERJOBS
touch $TMP_MASTERJOBS

# variables
RunningSubjobs="0"
InErrorSubjobs="0"
WaitingSubjobs="0"
RunningTime="0"
CPUCost="0"
MasterjobsNotReady="0"
MasterjobsInError="0"
SmallTimeout="20"
RunCounter="0"
NumberOfRuns=$(wc -l <<<$RUN_NUMBER)

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

    while :; do

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
            echo "Exeeded threshold, wait for things to calm down..."
            echo "$(($RunningSubjobs+$WaitingSubjobs))/$THRESHOLD_SUBJOBS are running/waiting"
            echo "$RunningTime/$THRESHOLD_RUNNING_TIME Running Time was used"
            echo "$CPUCost/$THRESHOLD_CPU_COST CPU cost was used"

            GridTimeout.sh $TIMEOUT

            continue
        fi

        echo "################################################################################"
        echo "Checking quota passed, checking status of other subjobs"
        echo "################################################################################"

        if [ $InErrorSubjobs -gt $THRESHOLD_ERROR_SUBJOBS ]; then

            echo "$InErrorSubjobs Subjobs are in error state, resubmit them..."
            Resubmit.sh
            GridTimeout.sh $SmallTimeout

            continue
        fi

        echo "################################################################################"
        echo "Checking status of other subjobs passed, checking status of other masterjobs"
        echo "################################################################################"

        echo "$MasterjobsNotReady masterjobs are not running yet"
        echo "$MasterjobsInError masterjobs are in error state"

        if [ $MasterjobsNotReady -gt 1 ]; then
            echo "Wait for other masterjobs to start running"

            GridTimeout.sh $SmallTimeout

            continue
        fi

        if [ $MasterjobsInError -gt 0 ]; then
            echo "Resubmit masterjobs in error state"

            alien_ps -E -M | awk '{print $2}' | parallel --progress --bar "alien.py resubmit {}"

            GridTimeout.sh $SmallTimeout

            continue
        fi

        break

    done

    echo "################################################################################"
    echo "All checks passed, we are good to go!"
    echo "################################################################################"
    echo "Submit Run $Run with Task $TASK_BASENAME with centrality bin edges $(tr '\n' ' ' <<<$CENTRALITY_BIN_EDGES)"

    if [ $RUN_OVER_DATA -eq 1 ];then
        # submit run over data
        alien_submit $GRID_WORKING_DIR_ABS/flowAnalysis.jdl "000${Run}.xml" $Run | awk 'FNR==2 {print $NF}' | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" | tee -a $TMP_MASTERJOBS
    else
        # submit run over MC production
        alien_submit $GRID_WORKING_DIR_ABS/flowAnalysis.jdl "${Run}.xml" $Run | awk 'FNR==2 {print $NF}' | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" | tee -a $TMP_MASTERJOBS
    fi

    ((RunCounter++))
    echo "Submitted $RunCounter/$NumberOfRuns Runs"
    echo "Wait for Grid to catch up..."

    if [ $RunCounter -lt $NumberOfRuns ];then
        # don wait after last job is submitted
        GridTimeout.sh $SmallTimeout
    fi

done

exit 0
