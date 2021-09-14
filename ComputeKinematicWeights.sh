#!/bin/bash
# File              : ComputeKinematicWeights.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.09.2021
# Last Modified Date: 10.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# compute kinematic weights run by run

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# get macro we are wrapping around
if [ -f "$GRID_UTILITY_SCRIPTS/ComputeKinematicWeights.C" ]; then
    ComputeWeightsMacro="$(realpath $GRID_UTILITY_SCRIPTS/ComputeKinematicWeights.C)"
else
    echo "No macro found for computing kinematic weights..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

echo "Compute weights run by run in $GRIDOUTPUTDIRREL"
echo "Using Macro $ComputeWeightsMacro"

find $GRIDOUTPUTDIRREL -type f -name "*Merged.root" | parallel --bar --progress "aliroot -b -l -q $ComputeWeightsMacro'(\"{}\")'"

exit 0
