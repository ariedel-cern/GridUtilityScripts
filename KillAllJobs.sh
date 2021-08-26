#!/bin/bash
# File              : KillAllJobs.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 05.08.2021
# Last Modified Date: 26.08.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

#clean up and kill all running jobs on the Grid

# loop variables
Subjobs=""
MasterjobCounter=0
SubjobCounter=0

# get all masterjobs not in Done state
Masterjobs="$(alien_ps -M | awk '$4!="D" {print $2}')"
NumberOfMasterJobs="$(wc -w <<<$Masterjobs)"

[ $NumberOfMasterJobs -eq 0 ] && echo "All Masterjobs are done. Get out!" && exit 0

echo "$NumberOfMasterJobs Masterjobs are not DONE. Let's kill them all!"

for Masterjob in $Masterjobs; do
    echo "Lets get rid of Masterjob $Masterjob"
    # get all subjobs not in Done state
    Subjobs="$(alien_ps -m $Masterjob | awk '$4!="D" {print $2}')"
    NumberOfSubjobs="$(wc -w $ <<<$Subjobs)"
    echo "To be safe, we will kill its $(wc -w <<<$SubJobs) Subjobs explicitly"
    SubjobCounter=0
    for Subjob in $Subjobs; do
        echo "Kill subjob $Subjob"
        alien.py kill $Subjob
        ((SubjobCounter++))
        echo "Killed ${SubjobCounter}/${NumberOfSubjobs}"
    done

    echo "Kill the Masterjob $Masterjob itself"
    alien.py masterjob $Masterjob kill
    ((MasterjobCounter++))
    echo "Killed ${MasterjobCounter}/${NumberOfMasterJobs}"
done

exit 0
