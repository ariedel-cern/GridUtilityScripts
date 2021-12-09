#!/bin/bash
# File              : KillAllJobs.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 05.08.2021
# Last Modified Date: 03.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# clean up and kill all running jobs on the Grid

alien_ps | awk '$4!="D" && $4!="K" {print $2}' | parallel --bar --progress "alien.py kill {}"

exit 0
