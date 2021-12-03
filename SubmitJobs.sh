#!/bin/bash
# File              : SubmitJobs.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 25.08.2021
# Last Modified Date: 01.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# submit jobs to grid

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# if running locally, call aliroot and run.C macro with default values and bail out
if [ $ANALYSIS_MODE = "local" ]; then
    echo "################################################################################"
    echo "Running locally over $DataDir"
    echo "with centrality bin edges $(tr '\n' ' ' <<<$CENTRALITY_BIN_EDGES)"
    aliroot -q -l -b run.C
    echo "################################################################################"
    exit 0
fi

echo "################################################################################"
echo "running on Grid"

# protect against overwriting existing analysis results
if alien_find "${GRID_WORKING_DIR_ABS}/*" &>/dev/null; then
    echo "Working directory not empty. Creating backup..."
    alien_mv ${GRID_WORKING_DIR_ABS} ${GRID_WORKING_DIR_ABS}.bak || exit 1
fi

echo "################################################################################"
echo "Run steering macros in offline mode to generate necessary files"
aliroot -q -l -b run.C 

echo "################################################################################"
echo "Modify jdl to use XML collections in $GRID_XML_COLLECTION"
# TODO
# add support for specifing weights run by run
sed -i -e "s|${GRID_WORKING_DIR_ABS}/\$1,nodownload|${GRID_XML_COLLECTION}/\$1,nodownload|" $JDL_FILE_NAME

echo "################################################################################"
echo "Move generate files to $LOCAL_TMP_DIR"
mv $JDL_FILE_NAME $LOCAL_TMP_DIR
mv $ANALYSIS_MACRO_FILE_NAME $LOCAL_TMP_DIR
mv analysis.sh $LOCAL_TMP_DIR
mv analysis_validation.sh $LOCAL_TMP_DIR
mv analysis.root $LOCAL_TMP_DIR

echo "################################################################################"
echo "Copy everything we need to grid"
alien_cp "file:${LOCAL_TMP_DIR}/${JDL_FILE_NAME}" "alien:${GRID_WORKING_DIR_ABS}/" || exit 2
alien_cp "file:${LOCAL_TMP_DIR}/${ANALYSIS_MACRO_FILE_NAME}" "alien:${GRID_WORKING_DIR_ABS}/" || exit 2
alien_cp "file:${LOCAL_TMP_DIR}/analysis.sh" "alien:${GRID_WORKING_DIR_ABS}/" || exit 2
alien_cp "file:${LOCAL_TMP_DIR}/analysis_validation.sh" "alien:${GRID_WORKING_DIR_ABS}/" || exit 2
alien_cp "file:${LOCAL_TMP_DIR}/analysis.root" "alien:${GRID_WORKING_DIR_ABS}/" || exit 2

[ -f $MASTERJOB_ID_R1 ] && rm $MASTERJOB_ID_R1
touch $MASTERJOB_ID_R1

RunCounter="0"
NumberOfRuns=$(wc -l <<<$RUN_NUMBER)


# submit jobs run by run
for Run in $RUN_NUMBER; do

    until CheckQuota.sh; do
        GridTimeout.sh $TIMEOUT_LONG
    done

    echo "################################################################################"
    echo "Submit Run $Run with Task $TASK_BASENAME with centrality bin edges $(tr '\n' ' ' <<<$CENTRALITY_BIN_EDGES)"

    if [ $RUN_OVER_DATA -eq 1 ];then
        # submit run over data
        alien_submit $GRID_WORKING_DIR_ABS/flowAnalysis.jdl "000${Run}.xml" $Run | awk 'FNR==2 {print $NF}' | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" | tee -a $MASTERJOB_ID_R1
    else
        # submit run over MC production
        alien_submit $GRID_WORKING_DIR_ABS/flowAnalysis.jdl "${Run}.xml" $Run | awk 'FNR==2 {print $NF}' | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" | tee -a $MASTERJOB_ID_R1
    fi

    ((RunCounter++))
    echo "Submitted $RunCounter/$NumberOfRuns Runs"
    echo "Wait for Grid to catch up..."

    # don wait after last job is submitted
    if [ $RunCounter -lt $NumberOfRuns ];then
        GridTimeout.sh $TIMEOUT_SHORT
    fi

done

exit 0
