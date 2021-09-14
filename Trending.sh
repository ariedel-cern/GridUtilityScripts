#!/bin/bash
# File              : Trending.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 05.08.2021
# Last Modified Date: 14.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# aggregate results to show their trend

source GridConfig.sh

DataFiles="DataFiles.txt"
find $GRID_OUTPUT_DIR_REL -type f -name "*Merged.root" | sort >$DataFiles
NumberOfRuns=$(wc -l <$DataFiles)

Output="Trending.root"

rm $Output 2>/dev/null
root -q -l -b Trending.C\(\"$DataFiles\",$NumberOfRuns,\"$Output\"\)

rm $DataFiles 2>/dev/null

exit 0
