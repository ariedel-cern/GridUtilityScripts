#!/bin/bash
# File              : GetMetaData.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 30.11.2021
# Last Modified Date: 01.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# update masterjob meta data and save it to file

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

MetaData=""
Run=""
Status=""
Total=""
Done=""
Waiting=""
Error=""

MasterJobsID=( "$MASTERJOB_ID_R1" "$MASTERJOB_ID_R2" "$MASTERJOB_ID_R3" )
MasterJobsMeta=( "$MASTERJOB_META_R1" "$MASTERJOB_META_R2" "$MASTERJOB_META_R3" )

for i in ${!MasterJobsID[@]}; do

        [ ! -f ${MasterJobsID[$i]} ] && break

        echo "Reincarnation $i"
        :> ${MasterJobsMeta[$i]}

        while read MasterJobID; do

            [ -z MasterjobID ] && break

            echo "Updateing $MasterJobID"

            MetaData=$(alien.py masterjob $MasterJobID)

            Run=$(alien_ps -jdl $MasterJobID | awk '/JDLArguments/{gsub("\"\;","",$4);print $4}' 2>/dev/null)
            Status=$(awk '/status:/{print $NF}' <<<$MetaData)
            Total=$(awk '/total/{print $(NF-1)}' <<<$MetaData)

            Done=$(awk '/DONE:/{print $NF}' <<<$MetaData)
            Done=${Done:=0}

            Waiting=$(awk '/WAITING:/{print $NF}' <<<$MetaData)
            Waiting=${Waiting:=0}

            Error=$(($Total-$Done-$Waiting))

            echo "$MasterJobID $Run $Status $Total $Done $Waiting $Error" >> ${MasterJobsMeta[$i]}

        done < ${MasterJobsID[$i]}
done

exit 0
