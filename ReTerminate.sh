#!/bin/bash
# File              : ReTerminate.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 31.08.2021
# Last Modified Date: 02.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# reterminate merged .root files run by run

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# get macro we are wrapping around
if [ -f "$GRID_UTILITY_SCRIPTS/ReTerminate.C" ]; then
    ReTerminateMacro="$(realpath $GRID_UTILITY_SCRIPTS/ReTerminate.C)"
else
    echo "No macro found for merging..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

echo "Reterminate merged files in $GridOutputDirRel"
echo "Using Macro $ReTerminateMacro"

find $GridOutputDirRel -type f -name "*Merged.root" | parallel "aliroot -b -l -q $ReTerminateMacro'(\"{}\")'"

exit 0
