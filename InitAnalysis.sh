#!/bin/bash
# File              : InitAnalysis.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 25.08.2021
# Last Modified Date: 03.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# initalize analysis

echo "Initialize analysis in $PWD"

if [ -z $GRID_UTILITY_SCRIPTS ]; then
    echo "Where are the GridUtilityScripts?"
    read $GRID_UTILITY_SCRIPTS
fi

[ ! -d $GRID_UTILITY_SCRIPTS ] && echo "GridUtilityScripts not found!!!" && exit 1

echo "Copy configuration files into $PWD"
cp $GRID_UTILITY_SCRIPTS/run.C.template run.C
cp $GRID_UTILITY_SCRIPTS/CreateAlienHandler.C.template CreateAlienHandler.C

if [ -f "AddTask.C" ]; then
    echo "Found existings AddTask.C, create backup..."
    mv AddTask.C AddTask.C.bak
fi
cp $GRID_UTILITY_SCRIPTS/AddTask.C.template AddTask.C

if [ -f "GridConfig.sh" ]; then
    echo "Found existings GridConfig.sh, create backup..."
    mv GridConfig.sh GridConfig.sh.bak
fi
cp $GRID_UTILITY_SCRIPTS/GridConfig.sh.template GridConfig.sh

exit 0
