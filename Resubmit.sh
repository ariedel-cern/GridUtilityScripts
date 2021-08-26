#!/bin/bash
# File              : Resubmit.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 23.06.2021
# Last Modified Date: 26.08.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# search for jobs in grid that failed and resubmit them

# signal handling for gracefully stoping endless loop
Flag=0
trap 'echo && echo "Stopping the loop" && Flag=1' SIGINT

#source config file
source GridConfig.sh

# global variables
# list of error states where automatic resubmitting is reasonable
RetryError="EV ESV ESP EIB EE Z"
Counter=0

# loop variables
Counter=""
FailedJobs=""
NumberOfFailedJobs=""
JobID=""
JobErrorState=""
JobWorkDir=""

while [ $Flag -eq 0 ]; do

    # resource config in every iteration
    source GridConfig.sh

    FailedJobs=$(alien_ps -E)
    NumberOfFailedJobs=$(wc -l <<<$FailedJobs)

    [ $NumberOfFailedJobs -eq "0" ] && echo "There are no jobs in error state, Yuhuu" && exit 0

    echo "There are $NumberOfFailedJobs Jobs in error state!!!"
    Counter=0
    while read Job; do
        JobID=$(awk '{print $2}' <<<$Job)
        JobErrorState=$(awk '{print $4}' <<<$Job)
        if [[ $RetryError =~ $JobErrorState ]]; then
            echo "Try resubmitting job $JobID"
            JobWorkDir="$(alien_ps -jdl $JobID | awk '/OutputDir/ { gsub(/"/,""); sub(/;/,""); print $3}')"
            echo "Clean up $JobWorkDir"
            alien_rm -rf $JobWorkDir 2>/dev/null
            alien.py resubmit $JobID
            ((Counter++))
            echo "Resubmitted ${Counter}/${NumberOfFailedJobs}"
            [ $? -eq 122 ] && echo "Reached limit. Wait for next round..." && break
        else
            echo "FATAL... There is a REAL problem with job $JobID"
        fi
    done < <(alien_ps -E)
    echo "Done with resubmitting"
    [ $Flag -ne 0 ] && break
    GridTimeout.sh $Timeout
done

exit 0
