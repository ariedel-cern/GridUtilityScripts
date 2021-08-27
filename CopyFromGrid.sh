#!/bin/bash
# File              : CopyFromGrid.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 16.06.2021
# Last Modified Date: 27.08.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# script for searching through a directory on grind and copying all matching files to local machine

# signal handling for gracefully stoping endless loop
Flag=0
trap 'echo && echo "Stopping the loop" && Flag=1' SIGINT

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# declare variables
CopyAttempts=""
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

# create temporary directory if it does not exist already
mkdir -p $LocalTmpDir

# # check if there is a logfile from a previous analysis
# if [ -f $LocalCopyLog ]; then
#     echo "Found log file from previous run, validate it..."
#     # if so, validate it
#     while read RemoteFile; do
#         LocalFile=${RemoteFile##${GridWorkingDirAbs}/}
#         #         # check if the file exists
#         if [ -f $LocalFile ]; then
#             # if so, bail out
#             continue
#         else
#             # if not, remove the entry
#             echo "$LocalFile not found, remove entry..."
#             sed -i -e "/${RemoteFile//\//\\/}/d" $GlobalLog
#         fi
#     done < <(awk '/COPIED/{print $1}' $GlobalLog)
# else
#     # if not, create an empty one
#     touch $GlobalLog
# fi

# start endless loop
while [ $Flag -eq 0 ]; do

    # resource config file
    source GridConfig.sh
    touch $LocalCopyLog

    echo "Job PID: ${BASHPID}"
    LocalTmpDir="$LocalTmpDir/CopyFromGrid_${BASHPID}"
    mkdir -p $LocalTmpDir
    LocalCopySummaryLog="$LocalTmpDir/$LocalCopySummaryLog"
    : >LocalCopySummaryLog

    echo "Tail log files in $(realpath $LocalTmpDir)"
    echo "Tail and watch $(realpath ${LocalCopySummaryLog}) for summary (no atomic write)"

    # search for remote files on grid
    RemoteFiles="$(alien_find "alien://${GridWorkingDirAbs}/**/${GridOutputRootFile}")"
    [ -z RemoteFiles ] && echo "No files found on grid" && exit 1

    # keep count of files
    NumberOfRemoteFiles="$(wc -l <<<$RemoteFiles)"
    NumberOfCopiedFiles="$(grep "COPIED" "$LocalCopyLog" | wc -l)"
    NumberOfBlacklistedFiles="$(grep "BLACKLISTED" "$LocalCopyLog" | wc -l)"

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
        echo "Process_$i 0 $ChunkSize" >>$LocalCopySummaryLog

        # go into subshell
        (
            FileCounter=0
            # loop over all remote files in this chunk
            while read RemoteFile; do

                # get entries from log file
                # add protection against multiple entries
                # it is difficult to send a shell variable which contains slashes to awk
                State=$(grep $RemoteFile $LocalCopyLog | head -1 | awk '{print $2}')
                CopyAttempts=$(grep "$RemoteFile" $LocalCopyLog | head -1 | awk '{print $3}')

                # set default values if there was no entry
                State=${State:=NOT_COPIED}
                CopyAttempts=${CopyAttempts:=0}

                # check if file is already copied or blacklisted
                if [ ! $State = "BLACKLISTED" -a ! $State = "COPIED" ]; then
                    # if not, copy it

                    # construct filename for the local file such that we preserve subdirectory structure from the grid
                    LocalFile=${RemoteFile##${GridWorkingDirAbs}/}

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
                sed -i -e "$((i + 1)) c Process_$i $FileCounter $ChunkSize" $LocalCopySummaryLog

                # split all found remote files into chunks (without spliting lines)
            done <<<$Chunk

            # redirect to process log file
        ) >"${LocalTmpDir}/${i}_${LocalCopyProcessLog}" &

        # print to screen
        echo "Process $i of $(($ParallelJobs - 1)) is processing $ChunkSize files: PID $(echo $!)"

    done

    echo "Wait for downloads to finish"
    wait

    # only cleanup and pause when no interrupt signal was sent
    if [ $Flag -eq 0 ]; then
        Cleanup $LocalCopyLog $LocalTmpDir $LocalCopyProcessLog
        rm $LocalCopySummaryLog
        GridTimeout.sh $Timeout
    fi
done

echo "##############################################################################"
echo "##############################################################################"
echo "##############################################################################"
echo "Wait for last jobs to finish"
wait
Cleanup $LocalCopyLog $LocalTmpDir $LocalCopyProcessLog
rm $LocalCopySummaryLog 2>/dev/null
rmdir $LocalTmpDir

exit 0
