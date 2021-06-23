#!/bin/bash
# File              : Merge.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 24.03.2021
# Last Modified Date: 23.06.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# merge .root files run by run

# global vairables
ConfigFile="config"
SearchPath=""
FileToMerge=""
FileToMergeList="FileToMergeList.txt"
if [ -f "Merge.C"];then
		MergeMacro="$(realpath Merge.C)"
else
		MergeMacro="$HOME/.local/bin/Merge.C"
fi
MergedFile=""

# get variables from config file
[ ! -f $ConfigFile ] && echo "No config file" && exit 1
SearchPath="$(awk -F'=' '/SearchPath/{print $2}' $ConfigFile)"
SearchPath=$(basename $SearchPath)
[ -z $SearchPath ] && echo "No directory to search through" && exit 1
FileToMerge="$(awk -F'=' '/FileToCopy/{print $2}' $ConfigFile)"
[ -z $FileToMerge ] && echo "No file to copy" && exit 1
echo "Merging runs in $SearchPath"
echo "Merging files $FileToMerge"
echo "Using Macro $MergeMacro"

while read Run; do
    echo "Start merging run $(basename $Run) in $(dirname $Run)"

	# go into subdirectory
	cd $Run

	# create list of files we want to merge and write the list to a file
	find . -type f -name $FileToMerge >$FileToMergeList

	# construct filename for merged file
	MergedFile="$(basename $Run)_Merged.root"

	# merge files
	root -b -l -q $MergeMacro\(\"$FileToMergeList\",\"$MergedFile\"\)

	# go back
	cd - >/dev/null
done < <(find $SearchPath -maxdepth 1 -mindepth 1 -type d)

exit 0
