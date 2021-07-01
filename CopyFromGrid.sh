#!/bin/bash
# File              : CopyFromGrid.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 16.06.2021
# Last Modified Date: 01.07.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# script for searching through a directory on grind and copying all matching files to local machine

# signal handling for gracefully stoping endless loop
Flag=0
trap 'echo && echo "Stopping the loop" && Flag=1' SIGINT

# parse arguments
# expect $1 to be path to configuration file CopyFromGrid.config
ConfigFile=${1:-CopyFromGrid.config}
if [ ! -f $ConfigFile ]; then
	echo "No local config file, fallback to global default"
	ConfigFile=$HOME/config/CopyFromGrid.config
fi

# declare variables
GlobalLog=""
ProcessLog=""
SummaryLog=""
SearchPath=""
FileToCopy=""
Pause=""
ParallelJobs=""
CopyAttempts=""
MaxCopyAttempts=""
RemoteFiles=""
RemoteFile=""
LocalFile=""
State=""
NumberOfRemoteFiles=""
NumberOfCopiedFiles=""
NumberOfBlacklistedFiles=""
Chunk=""
ChunkSize=""
FileCounter=""

# cleanup and aggregate results into global logfile
Cleanup() {
	echo "Cleanup"
	# merge all logfiles from the different subshells
	find $2 -name "*${3}" -exec cat {} + >>$1
	# remove logfiles from the different subshells
	find $2 -name "*${3}" -exec rm -rf {} \;
	# protect against writing an entry multiple times
	sort -u $1 -o $1
}

# get some variables from config file for inital setup
GlobalLog="$(awk -F'=' '/GlobalLog/{print $2}' $ConfigFile)"
[ -z $GlobalLog ] && echo "No log file specified" && exit 1
SearchPath="$(awk -F'=' '/SearchPath/{print $2}' $ConfigFile)"
[ -z $SearchPath ] && echo "No directory to search through" && exit 1
TmpDir="$(awk -F'=' '/TmpDir/{print $2}' $ConfigFile)"
[ -z $TmpDir ] && echo "No temporary directory specified" && exit 1
# create unique subfolder based on PID in $TmpDir
TmpDir="${TmpDir}/${BASHPID}_CopyFromGrid"

# create TmpDir if it does not exist already
mkdir -p $TmpDir

# check if there is a logfile from a previous analysis
if [ -f $GlobalLog ]; then
	echo "Found log file from previous run, validate it..."
	# if so, validate it
	while read RemoteFile; do
		LocalFile="$(basename $SearchPath)${RemoteFile##${SearchPath}}"
		# check if the file exists
		if [ -f $LocalFile ]; then
			# if so, bail out
			continue
		else
			# if not, remove the entry
			echo "$LocalFile not found, remove entry..."
			sed -i -e "/${RemoteFile//\//\\/}/d" $GlobalLog
		fi
	done < <(awk '/COPIED/{print $1}' $GlobalLog)
else
	# if not, create an empty one
	touch $GlobalLog
fi

# start endless loop
while [ $Flag -eq 0 ]; do

	# load configuration in each iteration
	[ ! -f $ConfigFile ] && echo "No config file" && exit 1
	SearchPath="$(awk -F'=' '/SearchPath/{print $2}' $ConfigFile)"
	[ -z $SearchPath ] && echo "No directory to search through" && exit 1
	FileToCopy="$(awk -F'=' '/FileToCopy/{print $2}' $ConfigFile)"
	[ -z $FileToCopy ] && echo "No file to copy" && exit 1
	Pause="$(awk -F'=' '/Pause/{print $2}' $ConfigFile)"
	[ -z $Pause ] && echo "No Pause" && exit 1
	ParallelJobs="$(awk -F'=' '/ParallelJobs/{print $2}' $ConfigFile)"
	[ -z $ParallelJobs ] && echo "No number of subjobs" && exit 1
	MaxCopyAttempts="$(awk -F'=' '/MaxCopyAttempts/{print $2}' $ConfigFile)"
	[ -z $MaxCopyAttempts ] && echo "No number of maximal copy attempts" && exit 1
	ProcessLog="$(awk -F'=' '/ProcessLog/{print $2}' $ConfigFile)"
	[ -z $ProcessLog ] && echo "No log for subjobs specified" && exit 1
	SummaryLog="$(awk -F'=' '/SummaryLog/{print $2}' $ConfigFile)"
	[ -z $SummaryLog ] && echo "No log for summary specified" && exit 1
	SummaryLog="${TmpDir}/${SummaryLog}"
	: >$SummaryLog

	# be verbose
	echo "##############################################################################"
	echo "##############################################################################"
	echo "##############################################################################"
	echo "Start endless loop iteration"
	echo "Tail log files in $(realpath $TmpDir)"
	echo "Tail and watch $(realpath $SummaryLog) for summary (no atomic write)"
	echo "Masterjob PID: ${BASHPID}"
	echo "Gracefully stop with CRTL-C"

	# search for remote files on grid
	RemoteFiles="$(alien_find "alien://${SearchPath}/**/${FileToCopy}")"
	[ -z RemoteFiles ] && echo "No files found on grid" && exit 1

	# keep count of files
	NumberOfRemoteFiles="$(wc -l <<<$RemoteFiles)"
	NumberOfCopiedFiles="$(grep "COPIED" "$GlobalLog" | wc -l)"
	NumberOfBlacklistedFiles="$(grep "BLACKLISTED" "$GlobalLog" | wc -l)"

	# be more verbose
	echo "$NumberOfCopiedFiles/$NumberOfRemoteFiles files are already copied to local machine"
	echo "$NumberOfBlacklistedFiles/$NumberOfRemoteFiles files are blacklisted"
	echo "$(($NumberOfCopiedFiles + $NumberOfBlacklistedFiles))/$NumberOfRemoteFiles files are accounted for"

	# stop if all files are accounted for
	if [ $(($NumberOfCopiedFiles + $NumberOfBlacklistedFiles)) -eq $NumberOfRemoteFiles ]; then
		echo "No more files left to copy"
		break
	fi

	# start jobs in parallel for downloads
	for ((i = 0; i < $ParallelJobs; i++)); do

		# split number of found files into chunks
		Chunk=$(split -n l/$((i + 1))/$ParallelJobs <<<$RemoteFiles)
		ChunkSize=$(wc -l <<<$Chunk)

		# create entry in summary log
		echo "Process_$i 0 $ChunkSize" >>$SummaryLog

		# go into subshell
		(
			FileCounter=0
			# loop over all remote files in this chunk
			while read RemoteFile; do

				# get entries from log file
				# add protection against multiple entries
				# it is difficult to send a shell variable which contains slashes to awk
				State=$(grep $RemoteFile $GlobalLog | head -1 | awk '{print $2}')
				CopyAttempts=$(grep "$RemoteFile" $GlobalLog | head -1 | awk '{print $3}')

				# set default values if there was no entry
				State=${State:=NOT_COPIED}
				CopyAttempts=${CopyAttempts:=0}

				# check if file is already copied or blacklisted
				if [ ! $State = "BLACKLISTED" -a ! $State = "COPIED" ]; then
					# if not, copy it

					# construct filename for the local file such that we preserve subdirectory structure from the grid
					LocalFile="$(basename $SearchPath)${RemoteFile##${SearchPath}}"

					# attempt to copy the file
					while :; do
						((CopyAttempts++))

						# attempt to copy
						if alien_cp "alien://${RemoteFile}" "$LocalFile" &>/dev/null; then
							# if successful, bail out
							State="COPIED"
							break
						fi

						# check number of attempts, if greater then maximum
						if [ $CopyAttempts -ge $MaxCopyAttempts ]; then
							# bail out
							State="BLACKLISTED"
							break
						fi
					done

					# create log entry
					echo "$RemoteFile $State $CopyAttempts"
				fi

				# increase file counter
				((FileCounter++))

				# change entry in summary
				sed -i -e "$((i + 1)) c Process_$i $FileCounter $ChunkSize" $SummaryLog

				# split all found remote files into chunks (without spliting lines)
			done <<<$Chunk

			# redirect to process log file
		) >"${TmpDir}/${i}_${ProcessLog}" &

		# print to screen
		echo "Process $i of $(($ParallelJobs - 1)) is processing $ChunkSize files: PID $(echo $!)"

	done

	echo "Wait for downloads to finish"
	wait

	# only cleanup and pause when no interrupt signal was sent
	if [ $Flag -eq 0 ]; then
		Cleanup $GlobalLog $TmpDir $ProcessLog
		echo "Pause"
		sleep $Pause
	fi
done

echo "##############################################################################"
echo "##############################################################################"
echo "##############################################################################"
echo "Broken out of endless loop"
echo "Wait for last jobs to finish"
wait
Cleanup $GlobalLog $TmpDir $ProcessLog
rm $SummaryLog

# try to remove TmpDir
rmdir $TmpDir

exit 0
