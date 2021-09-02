#!/bin/bash
# File              : ComputeWeights.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.09.2021
# Last Modified Date: 02.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# compute weights run by run

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# get macro we are wrapping around
if [ -f "$GRID_UTILITY_SCRIPTS/ComputeWeights.C" ]; then
    ComputeWeightsMacro="$(realpath $GRID_UTILITY_SCRIPTS/ComputeWeights.C)"
else
    echo "No macro found for computing weights..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

echo "Compute weights run by run in $GridOutputDirRel"
echo "Using Macro $ComputeWeightsMacro"

find $GridOutputDirRel -type f -name "*Merged.root" | parallel --bar --progress "aliroot -b -l -q $ComputeWeightsMacro'(\"{}\")'"

exit 0
