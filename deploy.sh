#!/bin/bash
# File              : deploy.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 23.06.2021
# Last Modified Date: 01.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

echo "Deploy Grid Utility Scripts to $HOME/.local/bin"
echo "$HOME/.local/bin is assumed to be in your PATH"

Path="$HOME/.local/bin"
GridUtilityScripts="$(dirname $(realpath $BASH_SOURCE[0]))"

mkdir -p $Path 2>/dev/null

ln -sf $GridUtilityScripts/GridTimeout.sh $Path/GridTimeout.sh
ln -sf $GridUtilityScripts/InitAnalysis.sh $Path/InitAnalysis.sh
ln -sf $GridUtilityScripts/SubmitJobs.sh $Path/SubmitJobs.sh
ln -sf $GridUtilityScripts/Resubmit.sh $Path/Resubmit.sh
ln -sf $GridUtilityScripts/CopyFromGrid.sh $Path/CopyFromGrid.sh
ln -sf $GridUtilityScripts/CheckFileIntegrity.sh $Path/CheckFileIntegrity.sh
ln -sf $GridUtilityScripts/Merge.sh $Path/Merge.sh
ln -sf $GridUtilityScripts/ReTerminate.sh $Path/ReTerminate.sh
ln -sf $GridUtilityScripts/ComputeWeights.sh $Path/ComputeWeights.sh

exit 0
