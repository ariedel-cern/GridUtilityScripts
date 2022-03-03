#!/bin/bash
# File              : ComputeCentralityProbabilities.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 10.09.2021
# Last Modified Date: 03.03.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# compute centrality probabilities run by run

[ ! -f config.json ] && echo "No config file!!!" && exit 1

OutputDir="$(jq -r '.task.GridOutputDir' config.json)"
echo "Compute centrality probabilities run by run in $OutputDir"

find $OutputDir -type f -name "*Merged.root" | parallel --bar --progress "aliroot -b -l -q ${GRID_UTILITY_SCRIPTS}/ComputeCentralityProbabilities.C'(\"config.json\",\"{}\")'"

exit 0
