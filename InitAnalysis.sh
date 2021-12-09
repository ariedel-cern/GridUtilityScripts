#!/bin/bash
# File              : InitAnalysis.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 25.08.2021
# Last Modified Date: 09.12.2021
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
	echo "Found existings AddTask.C, don't overwrite..."
	cp $GRID_UTILITY_SCRIPTS/AddTask.C.template AddTask.C.new
else
	cp $GRID_UTILITY_SCRIPTS/AddTask.C.template AddTask.C
fi

if [ -f "config.json" ]; then
	echo "Found existings config.json, don't overwrite..."
	cp $GRID_UTILITY_SCRIPTS/config.json.template config.json.new
else
	cp $GRID_UTILITY_SCRIPTS/config.json.template config.json
fi

exit 0
