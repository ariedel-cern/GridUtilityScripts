#!/bin/bash
# File              : Resubmit.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 23.06.2021
# Last Modified Date: 03.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# search for jobs on grid that failed and resubmit them

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

Resubmit() {
	# resubmit jobs in error state or kill them if they reached the threshold
	# $1 is expected to be the job ID

	# count how often the job finished in some error state
	local NumberOfFailures=$(alien_ps -trace $1 | grep "The job finished on the worker node with status ERROR_" | wc -l)

	if [ $NumberOfFailures -gt $MAX_RESUBMIT ]; then
		alien.py kill $1
	else
		# cleanup output directory before resubmitting
		alien_rm -rf $(alien_ps -jdl $1 | awk '$1=="OutputDir" {gsub(";","",$3);gsub("\"","",$3);print $3}') &>/dev/null
		alien.py resubmit $1
	fi

	return 0
}
export -f Resubmit

alien_ps -E | awk '{print $2}' | parallel --bar --progress Resubmit {}

exit 0
