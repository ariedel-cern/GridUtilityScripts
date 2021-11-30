#!/bin/bash
# File              : Reincarnate.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 30.11.2021
# Last Modified Date: 30.11.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# aggregate xml of all failed jobs and resubmit them in a new masterjob

source GridConfig.sh

MasterjobID=""
Run=""
SubjobsInError=""
GridOutputDir=""
JdlFileName=""
XmlCollection=""

# loop over done masterjobs and get the id of the failed subjobs
while read MasterjobMeta; do

    MasterjobID=$(awk '{print $1}' <<<$MasterjobMeta)
    Run=$(awk '{print $2}' <<<$MasterjobMeta)

    GridOutputDir="${GRID_OUTPUT_DIR_ABS}/${Run}/reincarnate"
    JdlFileName="${Run}_Reincarnate_${JDL_FILE_NAME}"
    XmlCollection="${Run}_Reincarnate.xml"

    echo "Reincarnate $MasterjobID corresponding to Run $Run"

    # get all failed subjobs
    SubjobsInError=$(alien_ps -m $MasterjobID | awk '$4~"E"{print $2}' | tr '\n' ',' | sed s'/,$//')

    # get xml collection of all failed AODs
    curl -L -k --key $HOME/.globus/userkey.pem --cert $HOME/.globus/usercert.pem:$(cat $HOME/.globus/grid) "http://alimonitor.cern.ch/jobs/xmlof.jsp?pid=$SubjobsInError" --output "${LOCAL_TMP_DIR}/$XmlCollection"

    # create new working directory on grid
    alien_mkdir -p $GridOutputDir

    # create new jdl file
    cp $LOCAL_TMP_DIR/$JDL_FILE_NAME $LOCAL_TMP_DIR/$JdlFileName

    # adept to reincarnation
    sed -i -e "s|${GRID_XML_COLLECTION}/\$1,nodownload|${GridOutputDir}/\$1,nodownload|" $LOCAL_TMP_DIR/$JdlFileName
    sed -i -e "/OutputDir/ s|${GRID_OUTPUT_DIR_ABS}|${GridOutputDir}|" $LOCAL_TMP_DIR/$JdlFileName
    sed -i -e "/SplitMaxInputFileNumber/ s/50/25/" $LOCAL_TMP_DIR/$JdlFileName

    # upload to grid
    echo "file:$LOCAL_TMP_DIR/$JdlFileName" "alien:$GridOutputDir"
    alien_cp "file:$LOCAL_TMP_DIR/$JdlFileName" "alien:${GridOutputDir}/"
    alien_cp "file:$LOCAL_TMP_DIR/$XmlCollection" "alien:${GridOutputDir}/"

    # submit new masterjob
    alien_submit "$GridOutputDir/$JdlFileName" "${XmlCollection}" $Run

done <$TMP_MASTERJOBS_META


exit 0
