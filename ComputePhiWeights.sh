#!/bin/bash
# File              : ComputePhiWeights.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.09.2021
# Last Modified Date: 01.03.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# compute phi weights run by run

[ ! -f config.json ] && echo "No config file!!!" && exit 1

OutputDir="$(jq -r '.task.GridOutputDir' config.json)"
echo "Compute phi weights run by run in $OutputDir"

find $OutputDir -type f -name "*Merged.root" | parallel --bar --progress "aliroot -b -l -q ${GRID_UTILITY_SCRIPTS}/ComputePhiWeights.C'(\"config.json\",\"{}\")'"

exit 0
