#/bin/bash
# File              : CheckFileIntegrity.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 17.06.2021
# Last Modified Date: 01.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# check integrity of all .root files in the local output directory

# check integrity
Check_Integrity() {

    # return 1 if a check is not passed
    file $File || return 1
    rootls $File || return 1

    # ADD MORE CHECKS

    # return 0 if all checks are passed
    return 0
}

# source config file
[ ! -f GridConfig.sh ] && echo "No config file!!!" && exit 1
source GridConfig.sh

# declare variables
Files=$(find $GridOutputDirRel -type f -name "*.root")
NumberOfFiles=$(wc -l <<<$Files)
echo "Checking $NumberOfFiles root files in $GridOutputDirRel"

# count number of subshells
CounterSubshells=0
# count number of checked files
CounterFiles=0

# loop over all files and check file integrity
while read File; do

    # do not start too many jobs
    if [ $CounterSubshells -ge $(nproc) ]; then
        wait
        CounterSubshells=0
        echo "$CounterFiles/$NumberOfFiles files checked"
    fi

    # test file in subshell
    (
        echo "Testing $File"
        if ! Check_Integrity $File &>/dev/null; then
            echo "Fail... remove $File"
            rm $File
            sed -i -e "/${File//\//\\/}/d" $GlobalLog
        else
            echo "Pass... keep $File"
        fi
    ) &

    ((CounterSubshells++))
    ((CounterFiles++))

done <<<$Files

# wait for unfinished jobs
wait
echo "$CounterFiles/$NumberOfFiles files checked"

exit 0
