#!/bin/bash
# File              : ReTerminate.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 31.08.2021
# Last Modified Date: 31.08.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# reterminate merged .root files run by run

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# declare variables
if [ -f "ReTerminate.C" ]; then
    ReTerminateMacro="$(realpath ReTerminate.C)"
else
    ReTerminateMacro="$HOME/.local/bin/ReTerminate.C"
fi

echo "Reterminate merged files in $GridOutputDirRel"
echo "Using Macro $ReTerminateMacro"

while read MergedFile; do
    echo "Reterminate file $(basename $MergedFile) in $(dirname $MergedFile)"

    pushd $(dirname $MergedFile)

    # merge files
    aliroot -b -l -q $ReTerminateMacro\(\"$(basename $MergedFile)\"\)

    popd

done < <(find $GridOutputDirRel -type f -name "*Merged.root")

exit 0
