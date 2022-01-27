#!/bin/bash
# File              : ReTerminate.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 31.08.2021
# Last Modified Date: 27.01.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# reterminate merged .root files run by run

[ ! -f config.json ] && echo "No config file!!!" && exit 1

OutputDir="$(jq -r '.task.GridOutputDir' config.json)"

echo "Reterminate merged files in $OutputFile"

find $OutputDir -type f -name "*Merged.root" | parallel --bar --progress "aliroot -b -l -q $GRID_UTILITY_SCRIPTS/ReTerminate.C'(\"{}\")'"
# find $OutputDir -type f -name "*Merged.root" -exec aliroot -b -l -q $GRID_UTILITY_SCRIPTS/ReTerminate.C\(\"{}\"\) \;

exit 0
