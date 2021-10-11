#!/bin/bash
# File              : SetupEnv.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 23.06.2021
# Last Modified Date: 06.10.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

echo 'export $GRID_UTILITY_SCRIPTS'
export GRID_UTILITY_SCRIPTS="$(dirname $(realpath ${BASH_SOURCE[0]}))"
echo "GRID_UTILITY_SCRIPTS=${GRID_UTILITY_SCRIPTS}"

echo 'add $GRID_UTILITY_SCRIPTS to $PATH'
export PATH="${GRID_UTILITY_SCRIPTS}:${PATH}"
echo "PATH=${PATH}"

# if [ ! -z $ROOT_INCLUDE_PATH ];then
#     echo 'add $GRID_UTILITY_SCRIPTS to $ROOT_INCLUDE_PATH'
#     export ROOT_INCLUDE_PATH="${GRID_UTILITY_SCRIPTS}:${ROOT_INCLUDE_PATH}"
#     echo "ROOT_INCLUDE_PATH=${ROOT_INCLUDE_PATH}"
# fi

return 0
