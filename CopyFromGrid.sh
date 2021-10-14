#!/bin/bash
# File              : CopyFromGrid.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 16.06.2021
# Last Modified Date: 14.10.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# script for searching through a directory on grind and copying all matching files to local machine

# signal handling for gracefully stoping endless loop
Flag=0
trap 'echo && echo "Stopping the loop" && Flag=1' SIGINT

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

LOCAL_TMP_DIR="${LOCAL_TMP_DIR}/CopyFromGrid_$BASHPID"
mkdir -p $LOCAL_TMP_DIR
FilesOnGrid="${LOCAL_TMP_DIR}/FilesGrid"
FilesOnDisk="${LOCAL_TMP_DIR}/FilesDisk"
FilesDiffGridDisk="${LOCAL_TMP_DIR}/FilesDiffGridDisk"
FilesCopy="${LOCAL_TMP_DIR}/FilesCopy"
FilesFailedCopy="${LOCAL_TMP_DIR}/FilesFailedCopy"
touch $FilesFailedCopy
CopyLog="${LOCAL_TMP_DIR}/CopyLog"

# start endless loop
while [ $Flag -eq 0 ]; do

    # source config in every iteration
    source GridConfig.sh
    # fix overwrite of environment variables
    LOCAL_TMP_DIR="${LOCAL_TMP_DIR}/CopyFromGrid_$BASHPID"

    # search for files on grid
    alien_find "alien://${GRID_WORKING_DIR_ABS}/**/${GRID_OUTPUT_ROOT_FILE}" | sed -e "s|${GRID_WORKING_DIR_ABS}/||" | sort -u >$FilesOnGrid

    # search for files on local disk
    find -type f -path "./${GRID_OUTPUT_DIR_REL}/**/${GRID_OUTPUT_ROOT_FILE}" -printf '%P\n' | sort -u >$FilesOnDisk

    # get diff between files on grid and disk and write them to file with the format
    # {Absolute path on grid} {relative locally}
    # so we can pass this file to alien_cp and start N number of jobs
    diff $FilesOnGrid $FilesOnDisk | awk '$1=="<" {print $2}' | sort -u | xargs -n1 -I{} echo "alien://${GRID_WORKING_DIR_ABS}/{} file://./{}" >$FilesCopy

    # remove files which failed to copy and write all remainig files to a file with the format
    # diff $FilesDiffGridDisk $FilesFailedCopy | awk '$1=="<" {print $2}' | sort -u | xargs -n1 -I{} echo "alien://${GRID_WORKING_DIR_ABS}/{} file://./{}" >$FilesCopy

    # when there are a lot of files, creating the directory seems to be a bottleneck for alien_cp, lets create the directories beforehand
    echo "create local directory structure"
    awk '{gsub("file://./","",$2);print $2}' $FilesCopy | parallel --bar --progress "mkdir -p {//}"

    echo "# files on grid       : $(wc -l $FilesOnGrid)"
    echo "# files locally       : $(wc -l $FilesOnDisk)"
    echo "# files left to copy  : $(wc -l $FilesCopy) "
    echo "Watch log $CopyLog"

    # copy files
    # let alien handle parallel downloads
    alien_cp -T $COPY_JOBS -input $FilesCopy &>$CopyLog

    # search for failed copies
    awk '$1=="Failed" {print $3}' $CopyLog | sed -e "s|${GRID_WORKING_DIR_ABS}/||" | sort -u >$FilesFailedCopy
    echo "# files failed to copy: $(wc -l $FilesFailedCopy)"

    echo "Copied all files in this batch. Wait for the next..."

    GridTimeout.sh $TIMEOUT
done

# cleanup
rm -rf $LOCAL_TMP_DIR

exit 0
