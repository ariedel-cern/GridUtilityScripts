```
 File              : README.md
 Author            : Anton Riedel <anton.riedel@tum.de>
 Date              : 14.09.2021
 Last Modified Date: 14.09.2021
 Last Modified By  : Anton Riedel <anton.riedel@tum.de>
```

# Grid Utility Scripts

This a collection of scripts to ease the interaction with Grid during data analysis.

## Usage

Either source `SetupEnv.sh` directly or in your `.bashrc`. Run this command inside the repository
```
echo "source $(realpath SetupEnv.sh) &>/dev/null" >> $HOME.bashrc
```
to automatically add it to your `.bashrc`.
This way you can easily access all scripts and macros.

## Scripts

### SetupEnv.sh
Export `$GRID_UTILITY_SCRIPTS`, which is the path to this repo and add it to `$PATH`.

### InitAnalysis.sh
Initialize analysis in a new directory by copying over the templated steering macros and `GridConfig.sh`.

### SubmitJobs.sh
Submit jobs to the Grid. This script can also be used as a wrapper script to run analysis locally.

### Resubmit.sh
Automatically resubmit failed jobs to the grid.

### CopyFromGrid.sh
Copy files from Grid to the local machine.

### CheckFileIntegrity.sh
Check integrity of local files copied from the Grid.

### KillAllJobs.sh
Kill all jobs which are not finished or killed yet. Nice for wrapping up the analysis.

### KillAllFailedJobs.sh
Similar to above, but just killing jobs which are in an ERROR state.

### Merge.sh
Wrapper script around the macro with the same name. Merge local files run by run.

### Reterminate.sh
Wrapper script around the macro with the same name. Reterminate local files after merging.

### ComputeKinematicWeights.sh
Wrapper script around the macro with the same name. Compute kinematic weights from merged files run by run. 

### ComputeCentralityProbabilities.sh
Wrapper script around the macro with the same name. Compute centrality probabilities for centrality flattening from merged files run by run. 

### GetHists.sh
Wrapper script around the macro with the same name. Search for histograms specified in `GridConfig.sh` run by run, task by task and dump the histograms into a seperate ROOT file. Convient if you want to use a certain histograms for further analysis.

## Steering macros

### run.C.template
Template of main steering macro. Calls all other macros to run the analysis. Does not need to be modified in general.

### CreateAlienHandler.C.template
Configure .jdl and other related files so we do not have to do it manually. Does not need to be modified in general.

### AddTask.C.template
Configure task by editing this macro.

## Config file

### GridConfig.sh.template
Configure whole analysis by editing this shell script. It will be periodically sourced by all other scripts to configure the analysis.
