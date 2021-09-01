#!/bin/bash
# File              : ReTerminate.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 31.08.2021
# Last Modified Date: 01.09.2021
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

while read MergedFile; do
    echo "Reterminate file $(basename $MergedFile) in $(dirname $MergedFile)"

    # go into subdirectory
    pushd $(dirname $MergedFile)

    # merge files
    aliroot -b -l -q $ReTerminateMacro\(\"$(basename $MergedFile)\"\)

    # go back
    popd

done < <(find $GridOutputDirRel -type f -name "*Merged.root")

exit 0
