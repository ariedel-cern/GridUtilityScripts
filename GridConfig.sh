#!/bin/bash
# File              : GridConfig.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 25.08.2021
# Last Modified Date: 31.08.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# example configuration for running a analysis on grid

# miscellaneous variables
export TaskBaseName="Test"
export OutputTDirectoryFile=:"OutputAnalysis"
export Timeout="300"
export ParallelJobs="10"
export MaxCopyAttempts="5"

# define directories and files on grid
export GridHomeDir="/alice/cern.ch/user/a/ariedel"
export GridWorkingDirRel="20210825_LHC10h_Test0"
export GridWorkingDirAbs="${GridHomeDir}/${GridWorkingDirRel}"
# relative to working directory on grid
export GridOutputDirRel="output"
export GridOutputDirAbs="${GridWorkingDirAbs}/${GridOutputDirRel}"
export GridOutputRootFile="AnalysisResults.root"
export GridXmlCollection="${GridHomeDir}/XMLcollections/LHC10h/pass2/AOD/AOD160"
export JdlFileName="flowAnalysis.jdl"
export AnalysisMacroFileName="flowAnalysis.C"

# define directories and files on local machine
export LocalWorkingDir="$(realpath $(dirname ${BASH_SOURCE[0]}))"
export LocalTmpDir="/tmp"
export LocalCopyLog="CopyFromGridGloabl.log"
export LocalCopyProcessLog="CopyFromGridProcess.log"
export LocalCopySummaryLog="CopyFromGridSummary.log"

# set analysis mode
# has to be local or grid
export AnalysisMode="local"

# when runnnig on grid
# has to be test, offline, submit, full or terminate
# for submission, set runmode to offline
export GridRunMode="offline"
# set analysis tag
export AliPhysicsTag="vAN-20210825_ROOT6-1"
export InputFilesPerSubjob="50"
export RunsPerMasterjob="1"
export MasterResubmitThreshold="50"
export TimeToLive="44000"

# when running locally specify data directory
export DataDir="/home/vagrant/data/2010/LHC10h/000137161/ESDs/pass2/AOD160"
# export DataDir="/home/vagrant/sim/LHC10d4/120822/AOD056"
# when running over real data, set to 1
# when running over monte carlo data, set to 0
export RunOverData="1"
# export RunOverData="0"
# when running over AOD, set to 1
# when running over ESD, set to 0
export RunOverAOD="1"
# export RunOverAOD="0"

# configure centrality bins
export CentralityBins=$(
    cat <<'EOF'
0
80
EOF
)

# configure run numbers
export RunNumber=$(
    cat <<'EOF'
137161
EOF
)
# export RunNumber=$(cat <<'EOF'
# 139510
# 139507
# 139505
# 139503
# 139465
# 139438
# 139437
# 139360
# 139329
# 139328
# 139314
# 139310
# 139309
# 139173
# 139107
# 139105
# 139038
# 139037
# 139036
# 139029
# 139028
# 138872
# 138871
# 138870
# 138837
# 138732
# 138730
# 138666
# 138662
# 138653
# 138652
# 138638
# 138624
# 138621
# 138583
# 138582
# 138578
# 138534
# 138469
# 138442
# 138439
# 138438
# 138396
# 138364
# 138275
# 138225
# 138201
# 138197
# 138192
# 138190
# 137848
# 137844
# 137752
# 137751
# 137724
# 137722
# 137718
# 137704
# 137693
# 137692
# 137691
# 137686
# 137685
# 137639
# 137638
# 137608
# 137595
# 137549
# 137546
# 137544
# 137541
# 137539
# 137531
# 137530
# 137443
# 137441
# 137440
# 137439
# 137434
# 137432
# 137431
# 137430
# 137243
# 137236
# 137235
# 137232
# 137231
# 137230
# 137162
# 137161
# EOF)

echo "Sourced $(basename ${BASH_SOURCE[0]}) at $(date "+%Y-%m-%d_%H:%M:%S")"

return 0
