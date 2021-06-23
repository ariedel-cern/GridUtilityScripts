#!/bin/bash
# File              : deploy.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 23.06.2021
# Last Modified Date: 23.06.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

echo 'Deploy Grid Utility Scripts to $HOME/.local/bin'
echo '$HOME/.local/bin is assumed to be in your PATH'

DeployPath="$HOME/.local/bin"
GUSpath="$(dirname $(realpath $BASH_SOURCE[0]))"

mkdir -p $DeployPath 2>/dev/null

ln -sf $GUSpath/CopyFromGrid.sh $DeployPath/CopyFromGrid.sh
ln -sf $GUSpath/CheckFileIntegrity.sh $DeployPath/CheckFileIntegrity.sh
ln -sf $GUSpath/Merge.sh $DeployPath/Merge.sh
ln -sf $GUSpath/Merge.C $DeployPath/Merge.C

exit 0
