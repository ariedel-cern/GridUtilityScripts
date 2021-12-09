#!/bin/bash
# File              : KillFailedJobs.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 05.08.2021
# Last Modified Date: 03.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# kill all jobs in error state

alien_ps -E | awk '{print $2}' | parallel --progress --bar "alien.py kill {}"

exit 0
