#!/bin/bash
# File              : Bootstrap.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 27.10.2021
# Last Modified Date: 15.02.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# bootstrap all FinalResultProfile

[ ! -f config.json ] && echo "No config file!!!" && exit 1

rm -rf Bootstrap.root

echo "Performing Bootstrap"
aliroot -q -l -b $GRID_UTILITY_SCRIPTS/Bootstrap.C\(\"$GRID_UTILITY_SCRIPTS/SUBSAMPLES.json\"\)

exit 0
