#!/bin/bash
# File              : KillAllFailedJobs.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 05.08.2021
# Last Modified Date: 06.08.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# get all masterjobs not in Done state
Jobs="$(alien_ps -E | awk '{print $2}')"
NJobs="$(wc -w <<<$Jobs)"

[ $NJobs -eq 0 ] && echo "No Jobs in error state...." && exit 0

for Job in $Jobs; do
        echo "Kill $Job"
        alien.py kill $Job
done

exit 0
