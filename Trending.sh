#!/bin/bash
# File              : Trending.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 05.08.2021
# Last Modified Date: 01.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# aggregate results to show their trend

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# get macro we are wrapping around
if [ -f "$GRID_UTILITY_SCRIPTS/Trending.C" ]; then
    TrendingMacro="$(realpath $GRID_UTILITY_SCRIPTS/Trending.C)"
else
    echo "No macro found for merging..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

DataFiles="DataFiles.txt"
find $GRID_OUTPUT_DIR_REL -type f -name "*ReTerminated.root" | sort >$DataFiles
NumberOfRuns=$(wc -l <$DataFiles)

# clean up
rm $LOCAL_OUTPUT_TRENDING_FILE 2>/dev/null

for Trend in $LOCAL_OUTPUT_TRENDING;do
    echo "Trend observable $Trend"
    root -q -l -b $TrendingMacro\(\"$DataFiles\",$NumberOfRuns,\"$Trend\"\)
done

rm $DataFiles 2>/dev/null

exit 0
