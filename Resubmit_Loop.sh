#!/bin/bash
# File              : Resubmit_Loop.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 07.09.2021
# Last Modified Date: 08.09.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# resubmit jobs in an endless loop

trap 'echo && echo "Stopping the loop" && Flag=1' SIGINT

Flag="0"

while [ $Flag -eq "0" ];
    do
        source GridConfig.sh
        Resubmit.sh
        GridTimeout.sh $TIMEOUT
done

exit 0
