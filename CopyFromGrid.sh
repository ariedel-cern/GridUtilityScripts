#!/bin/bash
# File              : CopyFromGrid.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 16.06.2021
# Last Modified Date: 29.06.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# script for searching through a directory on grind and copying all matching files to local machine

# signal handling for gracefully stoping endless loop
Flag=0
trap 'echo && echo "Stopping the loop" && Flag=1' SIGINT

# parse arguments
# expect $1 to be path to configuration file CopyFromGrid.config
ConfigFile=${1:-CopyFromGrid.config}
if [ ! -f $ConfigFile ];then
	echo "No local config file, fallback to global default"
	ConfigFile=$HOME/config/CopyFromGrid.config
fi

# declare variables
SearchPath=""
FileToCopy=""
Pause=""
ParallelJobs=""
MaxCopyAttempts=""
CopyAttempts=""
RemoteFiles=""
LocalFile=""
State=""
NumberOfRemoteFiles=""
NumberOfCopiedFiles=""
NumberOfBlacklistedFiles=""

# logging
TmpDir="tmp"
mkdir -p $TmpDir
LogFile="CopyFromGrid.log"
[ ! -f $LogFile ] && touch $LogFile
ProcessLogFile="Process.log"

# cleanup and aggregate results into global logfile after each iteration
Cleanup(){
	echo "Cleanup"
	# merge all logfiles from the different subshells
	find $2 -name "*${3}" -exec cat {} + >>$1
	# remove logfiles from the different subshells
	find $2 -name "*${3}" -exec rm -rf {} \;
	# protect against writing an entry multiple times
	sort -u $LogFile -o $LogFile
}

# start endless loop
while [ $Flag -eq 0 ]; do

	echo "Start endless loop iteration"
	echo "Tail log files in $(realpath $TmpDir)"
	echo "Gracefully stop with CRTL-C"

	# load configuration in each iteration
	[ ! -f $ConfigFile ] && echo "No config file" && exit 1
	SearchPath="$(awk -F'=' '/SearchPath/{print $2}' $ConfigFile)"
	[ -z $SearchPath ] && echo "No directory to search through" && exit 1
	FileToCopy="$(awk -F'=' '/FileToCopy/{print $2}' $ConfigFile)"
	[ -z $FileToCopy ] && echo "No file to copy" && exit 1
	Pause="$(awk -F'=' '/Pause/{print $2}' $ConfigFile)"
	[ -z $Pause ] && echo "No Pause" && exit 1
	ParallelJobs="$(awk -F'=' '/ParallelJobs/{print $2}' $ConfigFile)"
	[ -z $ParallelJobs ] && echo "No number of parallel jobs" && exit 1
	MaxCopyAttempts="$(awk -F'=' '/MaxCopyAttempts/{print $2}' $ConfigFile)"
	[ -z $MaxCopyAttempts ] && echo "No numer of maximal retries" && exit 1

	# search for remote files on grid
	RemoteFiles="$(alien_find "alien://${SearchPath}/**/${FileToCopy}")"
	[ -z RemoteFiles ] && echo "No files found on grid" && exit 1

	NumberOfRemoteFiles="$(wc -l <<<$RemoteFiles)"
	NumberOfCopiedFiles="$(grep "COPIED" "$LogFile" | wc -l)"
	NumberOfBlacklistedFiles="$(grep "BLACKLISTED" "$LogFile" | wc -l)"


	echo "${NumberOfCopiedFiles}/${NumberOfRemoteFiles} are copied to local machine"
	echo "${NumberOfBlacklistedFiles} are blacklisted"

	# start jobs in parallel for downloads
	for ((i = 0; i < $ParallelJobs; i++)); do
		echo "Start parallel Download $i"
		# go into subshell
		(
			# loop over all remote files in this chunk
			while read RemoteFile; do

				# get entries from log file
				State=$(grep $RemoteFile $LogFile | head -1 | awk '{print $2}')
				CopyAttempts=$(grep "$RemoteFile" $LogFile | head -1 | awk '{print $3}')

				# set default values if they were not found
				State=${State:=NOT_COPIED}
				CopyAttempts=${CopyAttempts:=0}

				if [ $State = "BLACKLISTED" -o $State = "COPIED" ];then
					# if so, bail out
					continue
				fi

				# construct filename for the local file such that we preserve subdirectory structure from the grid
				LocalFile="$(basename $SearchPath)${RemoteFile##${SearchPath}}"
				# attempt to copy file
				while :;do
					((CopyAttempts++))
					# attempt to copy
					if alien_cp "alien://${RemoteFile}" "$LocalFile" &>/dev/null;then
						# if successfule, bail out
						State="COPIED"
						break
					fi
					# if not, keep trying

					# check number of attempts, if greater then maximum
					if [ $CopyAttempts -ge $MaxCopyAttempts ];then
						# bail out
						State="BLACKLISTED"
						break
					fi
				done

				# create log entry
				echo "$RemoteFile $State $CopyAttempts"
			# split all found remote files into chunks (without spliting lines)
		    done < <(split -n l/$((i+1))/$ParallelJobs <<<$RemoteFiles)
		# redirect to process log file
		) >"${TmpDir}/${i}_${ProcessLogFile}" &
	done

	echo "Wait for downloads to finish"
	wait

	# only cleanup and pause when not interrupted
	if [ $Flag -eq 0 ];then
		Cleanup $LogFile $TmpDir $ProcessLogFile
		echo "Pause"
		sleep $Pause
	fi
done

echo "Wait for last jobs to finish"
wait
Cleanup $LogFile $TmpDir $ProcessLogFile

#if the temporary directory where we aggregated the log files is empty, remove it
rmdir $TmpDir

exit 0
