#!/bin/bash
# File              : Bootstrap.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 27.10.2021
# Last Modified Date: 01.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# get macro we are wrapping around
if [ -f "$GRID_UTILITY_SCRIPTS/Bootstrap.C" ]; then
    BootstrapMacro="$(realpath $GRID_UTILITY_SCRIPTS/Bootstrap.C)"
else
    echo "No macro found for merging..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

if [ -f "$GRID_UTILITY_SCRIPTS/Subsamples.C" ]; then
    SubsamplesMacro="$(realpath $GRID_UTILITY_SCRIPTS/Subsamples.C)"
else
    echo "No macro found for merging..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

# devide runs into chunks with approximately the same number of events
# use this placeholder for testing purposes for now
Subsamples="Subsamples.txt"

if [ ! -f $LOCAL_SUBSAMPLES_FILE ]; then
    Files="ReTerminated.txt"
    find $GRID_OUTPUT_DIR_REL -type f -name "*ReTerminated.root" >$Files
    aliroot -q -l -b $SubsamplesMacro\(\"$Files\",\"$LOCAL_SUBSAMPLES_FILE\"\)
fi

# clean up
rm $LOCAL_OUTPUT_BOOTSTRAP_FILE 2>/dev/null

for Bootstrap in $LOCAL_OUTPUT_BOOTSTRAP; do
    echo "Bootstrap $Bootstrap"
    aliroot -q -l -b $BootstrapMacro\(\"$LOCAL_SUBSAMPLES_FILE\",\"$Bootstrap\"\)
done

exit 0
