#!/bin/bash
# File              : Bootstrap.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 27.10.2021
# Last Modified Date: 17.02.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# bootstrap all FinalResultProfile

[ ! -f config.json ] && echo "No config file!!!" && exit 1

# Mean="Bootstrap/Mean_ReTerminated.root"
# FileList="Bootstrap.txt"
# aliroot -q -l -b $GRID_UTILITY_SCRIPTS/Bootstrap.C\(\"$Mean\",\"$FileList\"\)
# exit 4

# create directory to store bootstraped files
OutDir="Bootstrap"
mkdir -p "$OutDir"
rm -rf "${OutDir}/*.root"

# merge all files in a subsample to compute the subsample averages
MergedFile=""
FilesToMerge=""
FileList="Bootstrap.txt"
: >$FileList

while read Subsample; do
	MergedFile="${Subsample}_Merged.root"
	FilesToMerge="$(jq -r --arg Subsample $Subsample '.[$Subsample][]' $GRID_UTILITY_SCRIPTS/SUBSAMPLES.json)"

	hadd -f -k -j $(nproc) $MergedFile $FilesToMerge || exit 1

	mv $MergedFile $OutDir
	echo "${OutDir}/${MergedFile/Merged/ReTerminated}" >>$FileList

done < <(jq -r 'keys[]' $GRID_UTILITY_SCRIPTS/SUBSAMPLES.json)

# create file with whole sample average
FilesToMerge="$(find $OutDir -name "*_Merged.root")"
MergedFile="Mean_Merged.root"
hadd -f -k -j $(nproc) $MergedFile $FilesToMerge || exit 1
mv $MergedFile $OutDir
Mean="${OutDir}/${MergedFile/Merged/ReTerminated}"

# reterminate before bootstrap
find $OutDir -type f -name "*_Merged.root" | parallel --bar --progress "aliroot -b -l -q $GRID_UTILITY_SCRIPTS/ReTerminate.C'(\"{}\")'"

# call bootstrap macro
aliroot -q -l -b $GRID_UTILITY_SCRIPTS/Bootstrap.C\(\"$Mean\",\"$FileList\"\)

exit 0
