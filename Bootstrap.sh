#!/bin/bash
# File              : Bootstrap.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 27.10.2021
# Last Modified Date: 02.11.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

source GridConfig.sh

# get macro we are wrapping around
if [ -f "$GRID_UTILITY_SCRIPTS/Bootstrap.C" ]; then
    BootstrapMacro="$(realpath $GRID_UTILITY_SCRIPTS/Bootstrap.C)"
else
    echo "No macro found for merging..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

# devide runs into chunks with approximately the same number of events
# use this placeholder for testing purposes for now
SubSamples="SubSamples.txt"

# clean up
rm $LOCAL_OUTPUT_BOOTSTRAP_FILE 2>/dev/null

for Bootstrap in $LOCAL_OUTPUT_BOOTSTRAP;do
    echo "Bootstrap $Bootstrap"
    aliroot -q -l -b $BootstrapMacro\(\"$SubSamples\",\"$Bootstrap\"\)
done

exit 0
