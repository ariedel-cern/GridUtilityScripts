#!/bin/bash
# File              : Merge.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 24.03.2021
# Last Modified Date: 06.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# merge .root files run by run

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# get macro we are wrapping around
MergedFile=""
FilesToMergeList="FilesToMergeList.txt"
if [ -f "$GRID_UTILITY_SCRIPTS/Merge.C" ]; then
    MergeMacro="$(realpath $GRID_UTILITY_SCRIPTS/Merge.C)"
else
    echo "No macro found for merging..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

echo "Merging $GRIDOUTPUTROOTFILE run by run in $GRIDOUTPUTDIRREL"
echo "Using Macro $MergeMacro"

while read Run; do
    echo "Start merging run $(basename $Run) in $(dirname $Run)"

    # go into subdirectory
    pushd $Run

    # create list of files we want to merge and write the list to a file
    find . -type f -name $GRIDOUTPUTROOTFILE >$FilesToMergeList

    # construct filename for merged file
    MergedFile="$(basename $Run)_Merged.root"

    # merge files
    aliroot -b -l -q $MergeMacro\(\"$FilesToMergeList\",\"$MergedFile\"\)

    # go back
    popd

done < <(find $GRIDOUTPUTDIRREL -maxdepth 1 -mindepth 1 -type d)

exit 0
