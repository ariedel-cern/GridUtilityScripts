#!/bin/bash
# File              : UpdateMetaData.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 30.11.2021
# Last Modified Date: 30.11.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# update masterjob meta data and save it to file

source GridConfig.sh

:>$TMP_MASTERJOBS_META

MetaData=""
Run=""
Status=""
Done=""
Total=""

while read MasterjobID; do

    echo "Updateing $MasterjobID"

    MetaData=$(alien.py masterjob $MasterjobID)

    Run=$(alien_ps -jdl $MasterjobID | awk '/JDLArguments/{gsub("\"\;","",$4);print $4}' 2>/dev/null)
    Status=$(awk '/status:/{print $NF}' <<<$MetaData)
    Done=$(awk '/DONE:/{print $NF}' <<<$MetaData)
    Total=$(awk '/total/{print $(NF-1)}' <<<$MetaData)

    echo "$MasterjobID $Run $Status $Total $Done" >> $TMP_MASTERJOBS_META


done < $TMP_MASTERJOBS
