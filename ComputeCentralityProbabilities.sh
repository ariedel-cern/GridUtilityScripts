#!/bin/bash
# File              : ComputeCentralityProbabilities.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 10.09.2021
# Last Modified Date: 10.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# compute centrality probabilities run by run

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# get macro we are wrapping around
if [ -f "$GRID_UTILITY_SCRIPTS/ComputeCentralityProbabilities.C" ]; then
    ComputeProbabilitiesMacro="$(realpath $GRID_UTILITY_SCRIPTS/ComputeCentralityProbabilities.C)"
else
    echo "No macro found for computing centrality probabilities..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

echo "Compute probabilities run by run in $GRIDOUTPUTDIRREL"
echo "Using Macro $ComputeProbabilitiesMacro"

find $GRIDOUTPUTDIRREL -type f -name "*Merged.root" | parallel --bar --progress "aliroot -b -l -q $ComputeProbabilitiesMacro'(\"{}\")'"

exit 0
