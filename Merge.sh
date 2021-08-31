#!/bin/bash
# File              : Merge.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 24.03.2021
# Last Modified Date: 31.08.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# merge .root files run by run

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# declare variables
MergedFile=""
FileToMergeList="FileToMergeList.txt"
if [ -f "Merge.C" ]; then
    MergeMacro="$(realpath Merge.C)"
else
    MergeMacro="$HOME/.local/bin/Merge.C"
fi

echo "Merging runs in $GridOutputDirRel"
echo "Merging files $GridOutputRootFile"
echo "Using Macro $MergeMacro"

while read Run; do
    echo "Start merging run $(basename $Run) in $(dirname $Run)"

    # go into subdirectory
    cd $Run

    # create list of files we want to merge and write the list to a file
    find . -type f -name $GridOutputRootFile >$FileToMergeList

    # construct filename for merged file
    MergedFile="$(basename $Run)_Merged.root"

    # merge files
    root -b -l -q $MergeMacro\(\"$FileToMergeList\",\"$MergedFile\"\)

    # go back
    cd - >/dev/null
done < <(find $GridOutputDirRel -maxdepth 1 -mindepth 1 -type d)

exit 0
