#!/bin/bash
# File              : ComputeWeights.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.09.2021
# Last Modified Date: 01.09.2021
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

while read MergedFile; do
    echo "Compute weights for run $(dirname $MergedFile)"

    # go into subdirectory
    pushd $(dirname $MergedFile)

    # merge files
    aliroot -b -l -q $ComputeWeightsMacro\(\"$(basename $MergedFile)\"\)

    # go back
    popd

done < <(find $GridOutputDirRel -type f -name "*Merged.root")

exit 0
