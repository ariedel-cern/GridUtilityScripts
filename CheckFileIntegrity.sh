#/bin/bash
# File              : CheckFileIntegrity.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 17.06.2021
# Last Modified Date: 14.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# check integrity of all .root files in the local output directory

# check integrity
Check_Integrity() {

    # set flag
    local Flag=0

    # check file
    {
        file -E $1 || Flag=1
        rootls $1 || Flag=1
    } &>/dev/null
    # ADD MORE CHECKS

    # remove file if a check is not passed
    if [ $Flag -eq 1 ]; then
        echo "$1 did not pass checks. Remove..."
        rm $1
    # else
    #     echo "$1 passed checks"
    fi

    return 0
}

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

echo "Checking .root files in $GRID_OUTPUT_DIR_REL"

#since we want to run a shell function, we have to export it
export -f Check_Integrity
find $GRID_OUTPUT_DIR_REL -type f -name "*.root" | parallel --progress --bar Check_Integrity {}

exit 0
