#!/bin/bash
# File              : CopyFromGrid.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 16.06.2021
# Last Modified Date: 23.06.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# script for searching through a directory on grind and copying all matching files to local machine

# signal handling for gracefully stoping endless loop
Flag=0
trap 'echo && echo "Stopping the loop" && Flag=1' SIGINT

# global vairables
ConfigFile="config"
SearchPath=""
FileToCopy=""
Pause=5
ParallelJobs=10
MaxRetries=3
LogDir="Log"
mkdir -p $LogDir
BlacklistedFiles="${LogDir}/BlacklistedFiles.log"
# : >$BlacklistedFiles

# get variables from config file
[ ! -f $ConfigFile ] && echo "No config file" && exit 1
SearchPath="$(awk -F'=' '/SearchPath/{print $2}' $ConfigFile)"
[ -z $SearchPath ] && echo "No directory to search through" && exit 1
FileToCopy="$(awk -F'=' '/FileToCopy/{print $2}' $ConfigFile)"
[ -z $FileToCopy ] && echo "No file to copy" && exit 1
echo "Searching through $SearchPath on Grid"
echo "Copying $FileToCopy"

# variables used in the loop
LocalFile=""
Retries=0
RemoteFiles=""

# start endless loop
while [ $Flag -eq 0 ]; do
	echo "Start endless loop iteration"
	echo "Tail log files in $LogDir"
	echo "Gracefully stop with CRTL-C"

	# search for remote files
	RemoteFiles="$(alien_find "alien://${SearchPath}/*/${FileToCopy}")"

	# start jobs in parallel for downloads
	for ((i = 1; i <= $ParallelJobs; i++)); do
		echo "Start parallel Download $i"
		# go into subshell
		(
			# loop over all remote files in this chunk
			while read RemoteFile; do
				# reset retries
				Retries=0

				echo "Found $RemoteFile on Grid"

				# check if file is blacklisted, will be empty on the first run
				if grep -Fxqr "$RemoteFile" "$BlacklistedFiles" 2>/dev/null; then
					echo "$RemoteFile is blacklisted, skip"
					continue
				fi

				# construct filename for the local file such that we preserve subdirectory structure from the grid
				LocalFile="$(basename $SearchPath)${RemoteFile##${SearchPath}}"
				# LocalFile="$(basename $SearchPath)/${File/${SearchPath}\//}"
				echo "Copy to $LocalFile locally"

				# attempt to copy file
				while ! alien_cp $RemoteFile $LocalFile; do
					if [ $Retries -ge $MaxRetries ]; then
						echo "Limit reached, give up on $RemoteFile, add to blacklist"
						echo $RemoteFile >>"${BlacklistedFiles}_${i}"
						break
					fi
					((Retries++))
					echo "Something went wrong... Retry $Retries"
				done
			done < <(split -n l/$i/$ParallelJobs <<<$RemoteFiles)
			# split all found remote files into chunks (without spliting lines)
		) &>"${LogDir}/${i}_ParallelDownload.log" &
	done
	echo "Wait for downloads to finish"
	wait

	#clean up logs of blacklisted files
	echo "Cleanup"
	find $LogDir -name "$(basename $BlacklistedFiles)_*" -exec cat {} + >>"$BlacklistedFiles"
	find $LogDir -name "$(basename $BlacklistedFiles)_*" -exec rm {} \;

	echo "Pause"
	sleep $Pause
done

echo "Wait for last jobs to finish"
wait

#clean up logs of blacklisted files
echo "Last cleanup"
find $LogDir -name "$(basename $BlacklistedFiles)_*" -exec cat {} + >>"$BlacklistedFiles"
find $LogDir -name "$(basename $BlacklistedFiles)_*" -exec rm {} \;

exit 0
