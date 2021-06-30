#/bin/bash
# File              : CheckFileIntegrity.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 17.06.2021
# Last Modified Date: 30.06.2021
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

# parse arguments
# expect $1 to be path to configuration file CopyFromGrid.config
ConfigFile=${1:-CopyFromGrid.config}
if [ ! -f $ConfigFile ]; then
	echo "No local config file, fallback to global default"
	ConfigFile=$HOME/config/CopyFromGrid.config
fi

# get variables from config file
[ ! -f $ConfigFile ] && echo "No config file" && exit 1
SearchPath="$(awk -F'=' '/SearchPath/{print $2}' $ConfigFile)"
[ -z $SearchPath ] && echo "No directory in config file" && exit 1
SearchPath=$(basename $SearchPath)
[ ! -d $SearchPath ] && echo "No directory to search through" && exit 1
GlobalLog="$(awk -F'=' '/GlobalLog/{print $2}' $ConfigFile)"
[ -z $GlobalLog ] && echo "No global log file in config file" && exit 1
echo $GlobalLog
[ ! -f $GlobalLog ] && echo "No global log file found" && exit 1

Files=$(find $SearchPath -type f -name "*.root")
NumberOfFiles=$(wc -l <<<$Files)
echo "Checking .root $NumberOfFiles files in $(realpath $SearchPath)"

# count number of subshells
CounterSubshells=0
# count number of checked files
CounterFiles=0

# loop over all files and check file integrity
while read File; do

	# do not start too many jobs
	if [ $CounterSubshells -ge $(nproc) ]; then
		wait
		CounterSubshells=0
		echo "$CounterFiles/$NumberOfFiles files checked"
	fi

	# test file in subshell
	(
		echo "Testing $File"
		if ! Check_Integrity $File &>/dev/null; then
			echo "Fail... remove $File"
			rm $File
			sed -i -e "/${File//\//\\/}/d" $GlobalLog
		else
			echo "Pass... keep $File"
		fi
	) &

	((CounterSubshells++))
	((CounterFiles++))

done <<<$Files

# wait for unfinished jobs
wait
echo "$CounterFiles/$NumberOfFiles files checked"
echo "DONE"

exit 0
