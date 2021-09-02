#!/bin/bash
# File              : deploy.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 23.06.2021
# Last Modified Date: 02.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

echo 'export $GRID_UTILITY_SCRIPTS'
export GRID_UTILITY_SCRIPTS="$(dirname $(realpath ${BASH_SOURCE[0]}))"
echo "GRID_UTILITY_SCRIPTS=${GRID_UTILITY_SCRIPTS}"

echo 'add $GRID_UTILITY_SCRIPTS to $PATH'
export PATH="${GRID_UTILITY_SCRIPTS}:${PATH}"
echo "PATH=${PATH}"

return 0
