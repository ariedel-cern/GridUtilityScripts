#!/bin/bash
# File              : Bootstrap.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 27.10.2021
# Last Modified Date: 17.02.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# bootstrap all FinalResultProfile

[ ! -f config.json ] && echo "No config file!!!" && exit 1

# create directory to store bootstraped files
OutDir="Bootstrap"
mkdir -p "$OutDir"
rm -rf "${OutDir}/*"

# merge all files in a subsample to compute the subsample averages
MergedFile=""
FilesToMerge=""
FileList="Bootstrap.txt"

while read Subsample; do
    MergedFile="${Subsample}.root"
    FilesToMerge="$(jq -r --arg Subsample $Subsample '.[$Subsample][]' $GRID_UTILITY_SCRIPTS/SUBSAMPLES.json)"

    hadd -f -k -j $(nproc) $MergedFile $FilesToMerge || exit 1

    mv $MergedFile $OutDir
    echo $MergedFile >>$FileList

done < <(jq -r 'keys[]' $GRID_UTILITY_SCRIPTS/SUBSAMPLES.json)

# create file with whole sample average
FilesToMerge="$(find $OutDir -name "*.root")"
MergedFile="Mean.root"
hadd -f -k -j $(nproc) $MergedFile $FilesToMerge || exit 1
mv $MergedFile $OutDir

# call bootstrap macro
aliroot -q -l -b $GRID_UTILITY_SCRIPTS/Bootstrap.C\(\"$MergedFile\",\"$FileList\"\)

exit 0

# get list of all base tasks
# BaseName="$(jq -r '.task.BaseName' config.json)"
# CentralityBinEdges="$(jq -r '.task.CentralityBinEdges[]' config.json)"
# Array=($CentralityBinEdges)
#
# Tasks=""
#
# for i in "${!Array[@]}"; do
# 	if [ "$i" -eq "$((${#Array[@]} - 1))" ]; then
# 		continue
# 	elif [ "$i" -eq "$((${#Array[@]} - 2))" ]; then
# 		Tasks+="$(printf "%s_%.1f-%.1f" $BaseName ${Array[$i]} ${Array[$((i + 1))]})"
# 	else
# 		Tasks+="$(printf "%s_%.1f-%.1f," $BaseName ${Array[$i]} ${Array[$((i + 1))]})"
# 	fi
# done
#
# rm -rf *_Bootstrap.root
#
# echo "Performing Bootstrap"
#
# echo $Tasks | tr "," "\n" | parallel --bar --progress "aliroot -q -l -b $GRID_UTILITY_SCRIPTS/Bootstrap.C'(\"$GRID_UTILITY_SCRIPTS/SUBSAMPLES.json\",\"{}\")'"
#
# # find $OutputDir -type f -name "*Merged.root" | parallel --bar --progress "aliroot -b -l -q $GRID_UTILITY_SCRIPTS/ReTerminate.C'(\"{}\")'"
# exit 0
