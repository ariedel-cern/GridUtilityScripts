#!/bin/bash
# File              : CopyFromGrid.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 16.06.2021
# Last Modified Date: 06.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# script for searching through a directory on grind and copying all matching files to local machine

# signal handling for gracefully stoping endless loop
Flag=0
trap 'echo && echo "Stopping the loop" && Flag=1' SIGINT

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

LOCALTMPDIR="${LOCALTMPDIR}/CopyFromGrid_$BASHPID"
mkdir -p $LOCALTMPDIR
FilesOnGrid="${LOCALTMPDIR}/FilesGrid"
FilesOnDisk="${LOCALTMPDIR}/FilesDisk"
FilesDiffGridDisk="${LOCALTMPDIR}/FilesDiffGridDisk"
FilesCopy="${LOCALTMPDIR}/FilesCopy"
FilesFailedCopy="${LOCALTMPDIR}/FilesFailedCopy"
touch $FilesFailedCopy
CopyLog="${LOCALTMPDIR}/CopyLog"

# start endless loop
while [ $Flag -eq 0 ]; do

    # source config in every iteration
    source GridConfig.sh
    # fix overwrite of environment variables
    LOCALTMPDIR="${LOCALTMPDIR}/CopyFromGrid_$BASHPID"

    # search for files on grid
    alien_find "alien://${GRIDWORKINGDIRABS}/**/${GRIDOUTPUTROOTFILE}" | sed -e "s|${GRIDWORKINGDIRABS}/||" | sort -u >$FilesOnGrid

    # search for files on local disk
    find -type f -path "./${GRIDOUTPUTDIRREL}/**/${GRIDOUTPUTROOTFILE}" -printf '%P\n' | sort -u >$FilesOnDisk

    # get diff between files on grid and disk and write them to file with the format
    # {Absolute path on grid} {relative locally}
    # so we can pass this file to alien_cp and start N number of jobs
    diff $FilesOnGrid $FilesOnDisk | awk '$1=="<" {print $2}' | sort -u | xargs -n1 -I{} echo "alien://${GRIDWORKINGDIRABS}/{} file://./{}" >$FilesCopy

    # remove files which failed to copy and write all remainig files to a file with the format
    # diff $FilesDiffGridDisk $FilesFailedCopy | awk '$1=="<" {print $2}' | sort -u | xargs -n1 -I{} echo "alien://${GRIDWORKINGDIRABS}/{} file://./{}" >$FilesCopy

    echo "# files on grid       : $(wc -l $FilesOnGrid)"
    echo "# files locally       : $(wc -l $FilesOnDisk)"
    echo "# files failed to copy: $(wc -l $FilesFailedCopy)"
    echo "# files left to copy  : $(wc -l $FilesCopy) "
    echo "Watch log $CopyLog"

    # copy files
    alien_cp -T $COPYJOBS -input $FilesCopy &>$CopyLog

    # search for failed copies
    awk '$1=="Failed" {print $3}' $CopyLog | sed -e "s|${GRIDWORKINGDIRABS}/||" | sort -u >$FilesFailedCopy

    echo "Copied all files in this batch. Wait for the next..."

    GridTimeout.sh $TIMEOUT
done

rm -rf $LOCALTMPDIR

exit 0
