#!/bin/bash
# File              : CheckSubsamples.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 04.11.2021
# Last Modified Date: 04.11.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

source GridConfig.sh

# get macro we are wrapping around
if [ -f "$GRID_UTILITY_SCRIPTS/CheckSubsamples.C" ]; then
    CheckSubsamplesMacro="$(realpath $GRID_UTILITY_SCRIPTS/CheckSubsamples.C)"
else
    echo "No macro found for merging..."
    echo 'Did you set $GRID_UTILITY_SCRIPTS properly?'
    exit 2
fi

aliroot -q -l -b $CheckSubsamplesMacro\(\"$LOCAL_SUBSAMPLES_FILE\"\)

exit 0
