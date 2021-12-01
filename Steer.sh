#!/bin/bash
# File              : Steer.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 01.12.2021
# Last Modified Date: 01.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# master steering script for analysis

# before running make sure that weights are available and that the split for bootstrap is known

Submit.sh

Reincarnate.sh

CopyFromGrid.sh

CheckFileIntegrity.sh

Merge.sh
