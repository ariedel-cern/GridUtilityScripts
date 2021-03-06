#!/bin/bash
# File              : GridTimeout.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 26.08.2021
# Last Modified Date: 10.02.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# use this script for waiting for timeout in GridUtilityScripts

time=$(($1 - 1))
while [ $time -ge 0 ]; do
	echo -ne "Timeout: $time\033[0K\r"
	sleep 1
	((time--))
done
echo

exit 0
