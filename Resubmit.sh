#!/bin/bash
# File              : Resubmit.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 23.06.2021
# Last Modified Date: 30.06.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# search for jobs in grid that failed and resubmit them

# signal handling for gracefully stoping endless loop
Flag=0
trap 'echo && echo "Stopping the loop" && Flag=1' SIGINT

# global variables
# list of error states where automatic resubmitting is reasonable
RetryError="EV ESV ESP EIB EE"
Timeout=30
Counter=0

# loop variables
Masterjob=""
Masterjobs=""
MasterjobID=""
MasterjobState=""
JobID=""
JobErrorState=""

while [ $Flag -eq 0 ];do

		echo "Start endless loop iteration"
		echo "Check your qutoa"
		alien.py quota
		Counter=0
		Masterjobs=$(alien_ps -M)
		echo "Found $(wc -l <<<$Masterjobs) Masterjobs"

		while read Masterjob;do
				MasterjobID=$(awk '{print $2}' <<< "$Masterjob")
				MasterjobState=$(awk '{print $4}' <<< "$Masterjob")

				case $MasterjobState in
						"D")
								echo "Masterjob $MasterjobID is DONE"
								((Counter++))
								;;
						"S")
								echo "Masterjob $MasterjobID is SPLITTING, watch for subjobs"
								;;
						"I")
								echo "Masterjob $MasterjobID is INSERTING, watch for subjobs"
								;;
						"ES")
								echo "Masterjob $MasterjobID is in ERRORSPLIT, resubmit"
								alien.py $MasterjobID resumit
								;;
				esac
		done <<<$Masterjobs

		[ "$Counter" -eq "$(wc -l <<<$Masterjobs)" ] && echo "All Masterjobs are DONE... exit" && exit 0

		echo "Iterate over Jobs in error state"
		while read Jobs;do
				JobID=$(awk '{print $2}' <<< $Jobs)
				JobErrorState=$(awk '{print $4}' <<< $Jobs)
				if [[ $RetryError =~ $JobErrorState ]];then
						echo "Try resubmitting job $JobID"
						alien.py resubmit $JobID
				else
						echo "FATAL... There is a problem with job $JobID"
				fi
		done < <(alien_ps -E)
		echo "Done with resubmitting"
		[ $Flag -ne 0 ] && break
		echo "Wait ${Timeout}s before starting with next the round"

		sleep $Timeout
done

exit 0
