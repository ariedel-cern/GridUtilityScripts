#!/bin/bash
# File              : Bootstrap.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 27.10.2021
# Last Modified Date: 04.11.2021
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

if [ -f "$GRID_UTILITY_SCRIPTS/Subsamples.C" ]; then
    SubsamplesMacro="$(realpath $GRID_UTILITY_SCRIPTS/Subsamples.C)"
else
    echo "No macro found for merging..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

# devide runs into chunks with approximately the same number of events
if [ ! -f $LOCAL_SUBSAMPLES_FILE ]; then
    Files="ReTerminated.txt"
    find $GRID_OUTPUT_DIR_REL -type f -name "*ReTerminated.root" >$Files
    aliroot -q -l -b $SubsamplesMacro\(\"$Files\",\"$LOCAL_SUBSAMPLES_FILE\"\)
    rm $Files
    echo "Prefiltered runs into Subsamples"
    echo "USE CheckSubsamples.sh TO CHECK THE DISTRIBUTION AND ADJUST BY HAND"
    echo "Bailing out for now ..."
    exit 1
fi

# clean up
rm $LOCAL_OUTPUT_BOOTSTRAP_FILE 2>/dev/null

for Bootstrap in $LOCAL_OUTPUT_BOOTSTRAP; do
    echo "Bootstrap $Bootstrap"
    aliroot -q -l -b $BootstrapMacro\(\"$LOCAL_SUBSAMPLES_FILE\",\"$Bootstrap\"\)
done

exit 0
