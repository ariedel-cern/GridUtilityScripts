#!/bin/bash
# File              : SubmitJobs.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 25.08.2021
# Last Modified Date: 26.08.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# submit jobs to grid

Threshold=1400

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# if running locally, call aliroot and run.C macro with default values and bail out
if [ $AnalysisMode = "local" ]; then
    echo "Running locally"
    aliroot -q -l -b run.C
    exit 0
fi

echo "Create working directory $GridWorkingDirAbs"
alien_mkdir $GridWorkingDirAbs
# alien_rm -rf $GridWorkingDirAbs

# submit jobs run by run
for Run in $RunNumber; do

    NumberActiveJobs=$(alien_ps -X | wc -l)
    echo "Checking quota"
    echo "$NumberActiveJobs/$Threshold are running"

    while [ $NumberActiveJobs -gt $Threshold ]; do
        echo "Exeeded threshold, wait for things to calm down..."
        GridTimeout.sh $Timeout
    done

    echo "We are good to go!"
    echo "Submit Run $Run with Task $TaskBaseName in Centrality Bins $(tr '\n' ' ' <<<$CentralityBins)"
    aliroot -q -l -b run.C\($Run,100,10\)

done

exit 0
