#!/bin/bash
# File              : CentralityDependence.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 20.02.2022
# Last Modified Date: 01.03.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# plot observables as a function of centrality
# i.e. plot the integrate values as a function of their centrality

[ ! -f "Bootstrap.root" ] && echo "Bootstrap has not been performed yet! Break..." && exit 1

aliroot -q -l -b $GRID_UTILITY_SCRIPTS/CentralityDependence.C'("Bootstrap.root")'

exit 0
