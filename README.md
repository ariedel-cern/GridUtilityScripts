# Grid Utility Scripts

This a collection of scripts to ease the interaction with Grid during data analysis.

## Usage

Either source `SetupEnv.sh` or set `$GRID_UTILITY_SCRIPTS`, which should point to this repo, in your `.bashrc` and add it to your `$PATH`.
This way you can easily access all scripts and macros.

## Scripts

### SetupEnv.sh
Export `$GRID_UTILITY_SCRIPTS`, which is the path to this repo and add it to `$PATH`.
Only use this if you do not set these environment variables in your `.bashrc`.

### InitAnalysis.sh
Initialize analysis in a new directory by copying over the default steering macros and the example `GridConfig.sh`.

### SubmitJobs.sh
Submit jobs to the Grid. This script can also be used as a wrapper script to run analysis locally.

### Resubmit.sh
Automatically resubmit failed jobs with a certain error status to the grid.

### CopyFromGrid.sh
Copy files from Grid to the local machine.

### CheckFileIntegrity.sh
Check integrity of local files copied from the Grid.

### Merge.sh
Wrapper script around the macro with the same name. Merge local files run by run.

### Reterminate.sh
Wrapper script around the macro with the same name. Reterminate local files after merging.

### ComputeWeights.sh
Wrapper script around the macro with the same name. Compute weights from merged files run by run. 

### KillAllJobs.sh
Kill all jobs which are not in DONE state. Nice for wrapping up the analysis.

### KillAllFailedJobs.sh
Similar to above, but just killing all jobs which in an ERROR state.

## Steering macros

### run.C
Main steering macro. Calls all other macros to run the analysis.

### CreateAlienHandler.C
Configure .jdl and other related files so we do not have to do it manually.

### AddTask.C
Configure task by editing this macro.
