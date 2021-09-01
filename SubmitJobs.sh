#!/bin/bash
# File              : SubmitJobs.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 25.08.2021
# Last Modified Date: 01.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# submit jobs to grid

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# if running locally, call aliroot and run.C macro with default values and bail out
if [ $AnalysisMode = "local" ]; then
    echo "Running locally over $DataDir"
    aliroot -q -l -b run.C
    exit 0
fi

echo "running on Grid"

# protect against overwriting existing runs
echo "Create working directory $GridWorkingDirAbs"
alien_mkdir $GridWorkingDirAbs
# alien_rm $GridWorkingDirAbs/*

# will run with grind mode offline to generate all necessary files
echo "Run steering macros in offline mode to generate necessary files"
aliroot -q -l -b run.C &>/dev/null
echo "Modify jdl to use XML collections in $GridXmlCollection"
sed -i -e "s|${GridWorkingDirAbs}/\$1,nodownload|${GridXmlCollection}/\$1,nodownload|" $JdlFileName

echo "Copy everything we need to grid"
{
    alien_cp $JdlFileName alien://$GridWorkingDirAbs
    alien_cp $AnalysisMacroFileName alien://$GridWorkingDirAbs
    alien_cp analysis.sh alien://$GridWorkingDirAbs
    alien_cp analysis_validation.sh alien://$GridWorkingDirAbs
    alien_cp analysis.root alien://$GridWorkingDirAbs
} &>/dev/null

echo "Backup files"
BackupDir="Offline"
mkdir -p $BackupDir
mv $JdlFileName $BackupDir
mv $AnalysisMacroFileName $BackupDir
mv analysis.sh $BackupDir
mv analysis_validation.sh $BackupDir
mv analysis.root $BackupDir

Limit="1500"
Threshold_high="1350"
Threshold_low="300"

# submit jobs run by run
for Run in $RunNumber; do

    NumberActiveJobs=$(alien_ps -X | wc -l)
    echo "Checking quota"
    echo "$NumberActiveJobs/$Limit are running"

    while [ $NumberActiveJobs -gt $Threshold ]; do
        echo "Exeeded threshold, wait for things to calm down..."
        GridTimeout.sh $Timeout
    done

    echo "We are good to go!"
    echo "Submit Run $Run with Task $TaskBaseName in Centrality Bins $(tr '\n' ' ' <<<$CentralityBins)"
    alien_submit $GridWorkingDirAbs/flowAnalysis.jdl "000${Run}.xml" $Run

    [ $NumberActiveJobs -lt $Threshold_low ] && GridTimeout.sh 10

done

exit 0
