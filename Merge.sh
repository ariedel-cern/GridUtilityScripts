#!/bin/bash
# File              : Merge.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 24.03.2021
# Last Modified Date: 17.01.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# merge .root files run by run

[ ! -f config.json ] && echo "No config file!!!" && exit 1

echo "Merging $(jq -r '.task.GridOutputFile' config.json) run by run in $(jq -r '.task.GridOutputDir' config.json)"

MergedFile=""
OutputFile="$(jq -r '.task.GridOutputFile' config.json)"

while read Run; do
	echo "Start merging run $(basename $Run) in $(dirname $Run)"

	# go into subdirectory
	pushd $Run

	# construct filename for merged file
	MergedFile="$(basename $Run)_Merged.root"

	# merge files using hadd in parallel!!!
	hadd -f -k -j $(nproc) $MergedFile $(find . -type f -name "$OutputFile")

	# go back
	popd

done < <(find "$(jq -r '.task.GridOutputDir' config.json)" -maxdepth 1 -mindepth 1 -type d)

exit 0
