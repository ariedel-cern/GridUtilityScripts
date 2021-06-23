#!/bin/bash
# File              : Resubmit.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 23.06.2021
# Last Modified Date: 23.06.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# search for jobs in grid that failed and resubmit them

# signal handling for gracefully stoping endless loop
Flag=0
trap 'echo && echo "Stopping the loop" && Flag=1' SIGINT

# global variables
# list of error states where automatic resubmissing is reasonable
RetryError="EV ESV ESP" 
Timeout=30
Counter=0

# loop variables
Masterjobs=""
Masterjob=""
MasterjobState=""
Job=""
JobErrorState=""

while [ $Flag -eq 0 ];do

		echo "Start endless loop iteration"
		echo "Check your qutoa"
		alien.py quota
		Counter=0
		Masterjobs=$(alien_ps -M)
		echo "Found $(wc -l <<<$Masterjobs) Masterjobs"

		while read Mjob;do
				Masterjob=$(awk '{print $2}' <<< "$Mjob")
				MasterjobState=$(awk '{print $4}' <<< "$Mjob")

				[ $MasterjobState = "D" ]  && echo "Masterjob $Masterjob is DONE" && ((Counter++))

				[ $MasterjobState = "S" ]  && echo "Masterjob $Masterjob is SPLITTING, watch for subjobs"
		done <<<$Masterjobs

		[ "$Counter" -eq "$(wc -l <<<$Masterjobs)" ] && echo "All Masterjobs are DONE... exit" && exit 0

		echo "Iterate over Jobs in error state"
		while read Jobs;do
				Job=$(awk '{print $2}' <<< $Jobs)
				JobErrorState=$(awk '{print $4}' <<< $Jobs)
				if [[ $RetryError =~ $JobErrorState ]];then
						echo "Try resubmitting job $Job"
						alien.py resubmit $Job
				else
						echo "FATAL... There is a problem with job $Job"
				fi
		done < <(alien_ps -E)
		echo "Done with resubmitting"
		echo "Wait ${Timeout}s before starting with next the round"

		sleep $Timeout
done

exit 0
