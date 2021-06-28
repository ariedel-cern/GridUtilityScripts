#/bin/bash
# File              : CheckFileIntegrity.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 17.06.2021
# Last Modified Date: 28.06.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# check integrity of all .root files in a given directory and subdirectories

# check integrity
Check_Integrity() {

	# return 1 if a check is not passed
	file $File || return 1
	rootls $File || return 1

	# return 0 if all checks are passed
	return 0
}

# get variables from config file
ConfigFile="config"
[ ! -f $ConfigFile ] && echo "No config file" && exit 1
SearchPath="$(awk -F'=' '/SearchPath/{print $2}' $ConfigFile)"
SearchPath=$(basename $SearchPath)
[ -z $SearchPath ] && echo "No directory to search through" && exit 1
echo "Checking .root files in $SearchPath"

# counter for paralle jobs
Counter=0
# loop over all root files and check file integrity
while read File; do

	# do not start too many jobs
	if [ $Counter -ge $(nproc) ]; then
		wait
		Counter=0
	fi

	# test file in subshell
	(
		echo "Testing $File"
		if ! Check_Integrity $File &>/dev/null; then
			echo "Fail... remove $File"
			rm $File
		else
			echo "Pass... keep $File"
		fi
	) &

	((Counter++))

done < <(find $SearchPath -type f -name "*.root")

# wait for unfinished jobs
wait

exit 0
