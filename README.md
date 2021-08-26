# Grid Utility Scripts

This a collection of scripts to ease the interaction with Grid during data analysis.

## Usage

Place the scirpts in `$PATH` with the included `deploy.sh` script.
The script assumes that `$HOME/.local/bin` is in your `$PATH`.
The scripts source `GridConfig.sh` upon execution to set environment variables.
Both the scirpts and macros pull those variables from the environment to configure the analysis.
There is an example `GridConfig.sh` included which lists all necessary variables that need to be defined.
The only files which need to be edited to configure a certain analysis after initalizing it is `GridConfig.sh` and `AddTask.C`.

## Scirpts

### deploy.sh
Creating symlinks for the utility scripts into `$HOME/.local/bin` which is assumed to be in your `$PATH`.

### InitAnalysis.sh
Initialize analysis in a new directory by copying over the default steering macros and the example `GridConfig.sh`. If you specify the environment variable `$GRID_UTILITY_SCRIPTS` pointing to the folder of this repository they will be copied automatically.

### SubmitJobs.sh
Submit jobs to the Grid. This script can also be used as a wrapper script to run analysis locally.

### Resubmit.sh
Automatically resubmit failed jobs with a certain error status to the grid.

### CopyFromGrid.sh
Copy files from Grid to the local machine.

### CheckFileIntegrity.sh
Check integrity of local files copied from the Grid.

### Merge.sh
Merged local files run by run.

### KillAllJobs.sh
Kill all jobs which are not in DONE state. Nice for wrapping up the analysis.

### KillAllFailedJobs.sh
Similar to above, but just killing all jobs which in an ERROR state.

## Steering macros

### run.C
Main steering macro. Calls all other macros to run the analysis.

### CreateAlienHandler.C
Configure jdl files so we do not have to do it manually.

### AddTask.C
Configure task by editing this macro.
