#!/bin/bash
# File              : KillAllJobs.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 05.08.2021
# Last Modified Date: 05.08.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

#clean up and kill all running jobs on the Grid

# loop variables
Subjobs=""

# get all masterjobs not in Done state
Masterjobs="$(alien_ps -M | awk '$4!="D" {print $2}')"
NMasterjobs="$(wc -w <<<$Masterjobs)"

[ $NMasterjobs -eq 0 ] && echo "All Jobs are done. Get out!" && exit 0

echo "$NMasterjobs are not DONE. Let's kill them all!"

for Masterjob in $Masterjobs;do
        echo "Lets get rid of $Masterjob"
        # get all subjobs not in Done state
        Subjobs="$(alien_ps -m $Masterjob | awk '$4!="D" {print $2}')"
        echo "To be safe, we will kill its $(wc -w <<<$SubJobs) subjobs explicitly"
        for Subjob in $Subjobs;do
                echo "Kill subjob $Subjob"
                alien.py kill $Subjob
        done
        echo "Kill the masterjob itself"
        alien.py masterjob $Masterjob kill
done

exit 0
