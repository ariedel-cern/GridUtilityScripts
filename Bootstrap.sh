#!/bin/bash
# File              : Bootstrap.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 27.10.2021
# Last Modified Date: 27.10.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

source GridConfig.sh

# get macro we are wrapping around
if [ -f "$GRID_UTILITY_SCRIPTS/Bootstrap.C" ]; then
    BootstrapMacro="$(realpath $GRID_UTILITY_SCRIPTS/Bootstrap.C"
else
    echo "No macro found for bootstrap..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

DataFiles="DataFiles.txt"
find $GRID_OUTPUT_DIR_REL -type f -name "*ReTerminated.root" | sort >$DataFiles
NumberOfRuns=$(wc -l <$DataFiles)

# clean up
Output="Bootstrap.root"
rm $Output 2>/dev/null

for Trend in $LOCAL_OUTPUT_TRENDING;do
    echo "Trend $Trend"
    root -q -l -b $BootstrapMacro\(\"$SubSamples\",$NumberOfRuns,\"$LOCAL_OUTPUT_TRENDING_FILE\",\"$Trend\"\)
done

rm $DataFiles 2>/dev/null

exit 0
