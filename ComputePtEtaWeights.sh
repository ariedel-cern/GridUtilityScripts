#!/bin/bash
# File              : ComputePtEtaWeights.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.09.2021
# Last Modified Date: 01.03.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# compute kinematic weights run by run

[ ! -f config.json ] && echo "No config file!!!" && exit 1

OutputDir="$(jq -r '.task.GridOutputDir' config.json)"
echo "Compute kinematic weights run by run in $OutputDir"

find $OutputDir -type f -name "*Merged.root" | parallel --bar --progress "aliroot -b -l -q ${GRID_UTILITY_SCRIPTS}/ComputePtEtaWeights.C'(\"config.json\",\"{}\")'"

exit 0
