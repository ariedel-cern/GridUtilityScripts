#!/bin/bash
# File              : Merge.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 24.03.2021
# Last Modified Date: 14.10.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# merge .root files run by run

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

echo "Merging $GRID_OUTPUT_ROOT_FILE run by run in $GRID_OUTPUT_DIR_REL"

MergedFile=""

while read Run; do
    echo "Start merging run $(basename $Run) in $(dirname $Run)"

    # go into subdirectory
    pushd $Run

    # construct filename for merged file
    MergedFile="$(basename $Run)_Merged.root"

    # merge files using hadd in parallel!!!
    hadd -f -k -j $(nproc) $MergedFile $(find . -type f -name $GRID_OUTPUT_ROOT_FILE)

    # go back
    popd

done < <(find $GRID_OUTPUT_DIR_REL -maxdepth 1 -mindepth 1 -type d)

exit 0
