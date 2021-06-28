# Grid Utility Scripts

This a collection of scripts to ease the interaction with Grid during data analysis.

## Usage

You can either use the scripts directly from inside the repository or place them in PATH with the included `deploy.sh` script.
The script assumes that `$HOME/.local/bin` is in your PATH.
The scripts search for a file named `config` upon execution for the definition of certain variables.
There is an example, `config.example`, included which lists all necessary variables that need to be defined.

### deploy.sh

Creating symlinks for the utility scripts into `$HOME/.local/bin` which is assumed to be in your PATH.

### CopyFromGrid.sh

Copy files from Grid to the local machine.

### CheckFileIntegrity.sh

Check integrity of local files copied from the Grid.

### Merge.sh

Merged local files run by run.

### Resubmit.sh

Automatically resubmit failed jobs with a certain error status to the grid.
