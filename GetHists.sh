#!/bin/bash
# File              : GetHists.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 15.09.2021
# Last Modified Date: 16.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# filter out chosen histograms into seperate file

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# get macro we are wrapping around
if [ -f "$GRID_UTILITY_SCRIPTS/GetHists.C" ]; then
    GetHistsMacro="$(realpath $GRID_UTILITY_SCRIPTS/GetHists.C)"
else
    echo "No macro found for getting histograms..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

echo "Clean up old $LOCAL_OUTPUT_ROOT_FILE in $GRID_OUTPUT_DIR_REL"
find $GRID_OUTPUT_DIR_REL -name $LOCAL_OUTPUT_ROOT_FILE -exec rm -rf {} \+

for Search in $LOCAL_OUTPUT_HISTOGRAMS; do
    echo "Extract all $Search"
    find $GRID_OUTPUT_DIR_REL -name "*Merged.root" | parallel "aliroot -q -l -b $GetHistsMacro\(\\\"{}\\\",\\\"{//}/$LOCAL_OUTPUT_ROOT_FILE\\\",\\\"$Search\\\"\)"
done

exit 0
