#!/bin/bash
# File              : Resubmit.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 23.06.2021
# Last Modified Date: 02.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# search for jobs on grid that failed and resubmit them

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# signal handling for gracefully stoping endless loop
Flag=0
trap 'echo && echo "Stopping the loop" && Flag=1' SIGINT

Resubmit() {
    # resubmit jobs in error state or kill them if they reach the threshold
    # $1 is expected to be the job ID

    # count how often the job finished in some error state
    local NumberOfFailures=$(alien_ps -trace $1 | grep "The job finished on the worker node with status ERROR_" | wc -l)

    if [ $NumberOfFailures -gt $MaxResubmitAttempts ]; then
        alien.py kill $1
    else
        alien.py resubmit $1
    fi

    return 0
}
export -f Resubmit

while [ $Flag -eq 0 ]; do

    # source config in every iteration
    source GridConfig.sh

    alien_ps -E | awk '{print $2}' | parallel --bar --progress Resubmit {}

    echo "Done with resubmitting this batch. Wait for more..."
    GridTimeout.sh $Timeout
done

exit 0
