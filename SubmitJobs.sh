#!/bin/bash
# File              : SubmitJobs.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 25.08.2021
# Last Modified Date: 09.12.2021
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# submit jobs to grid

[ ! -f config.json ] && echo "No config file!!!" && exit 1

# if running locally, just call aliroot and bail out
if [ "$(jq -r '.task.AnalysisMode' config.json)" = "local" ]; then
	echo "################################################################################"
	echo "Running locally over $(jq -r '.task.LocalDataDir' config.json)"
	aliroot -q -l -b run.C\(\"config.json\"\)
	echo "################################################################################"
	exit 0
fi

echo "################################################################################"
echo "Running on Grid"

# get variables from config file
GridWorkDir="$(jq -r '.task.GridHomeDir' config.json)/$(jq -r '.task.GridWorkDir' config.json)"
XmlCollection="$(jq -r '.task.GridXmlCollection' config.json)"
Jdl="$(jq -r '.task.Jdl' config.json)"
Macro="$(jq -r '.task.AnalysisMacro' config.json)"

# create remote and local working directory
alien_rm -R -f "alien:${GridWorkDir}"
alien_mkdir -s "alien:${GridWorkDir}"

echo "Run steering macros in offline mode to generate necessary files"
aliroot -q -l -b run.C\(\"config.json\"\) || exit 2

echo "Modify jdl to use XML collections in ${XmlCollection}"
# TODO
# add support for specifing weights run by run
sed -i -e "/nodownload/ s|${GridWorkDir}|${XmlCollection}|" $Jdl

echo "Copy everything we need to grid"
cat >SubmitCopy <<EOF
file:${Jdl} alien:${GridWorkDir}/
file:${Macro} alien:${GridWorkDir}/
file:analysis.sh alien:${GridWorkDir}/
file:analysis_validation.sh alien:${GridWorkDir}/
file:analysis.root alien:${GridWorkDir}/
EOF

alien_cp -f -input SubmitCopy || exit 3

echo "################################################################################"

# get more variables from config file
RunCounter="0"
JobId=""
LongTimeout="$(jq -r '.misc.LongTimeout' config.json)"
ShortTimeout="$(jq -r '.misc.ShortTimeout' config.json)"
BaseName="$(jq -r '.task.BaseName' config.json)"
RunOverData="$(jq -r '.task.RunOverData' config.json)"
Runs="$(jq -r '.Runs[]' config.json)"
RunCounter="0"
NumberOfRuns=$(wc -l <<<$Runs)
StatusFile="$(jq -r '.StatusFile' config.json)"
echo "{}" >$StatusFile
RunStatus="Run.tmp.json"
TmpSave="Submit.tmp.json"
LockFile="$(jq -r '.LockFile' config.json)"

# submit jobs run by run
for Run in $Runs; do

	until CheckQuota.sh; do
		GridTimeout.sh $LongTimeout
	done

	echo "################################################################################"
	echo "Submit Run $Run with Task $BaseName"

	if [ $RunOverData == "true" ]; then
		# submit run over data
		JobId=$(alien_submit $GridWorkDir/flowAnalysis.jdl "000${Run}.xml" $Run -json | jq -r '.results[0].jobId')
	else
		# submit run over MC production
		JobId=$(alien_submit $GridWorkDir/flowAnalysis.jdl "${Run}.xml" $Run -json | jq -r '.results[0].jobId')
	fi

	((RunCounter++))
	echo "Submitted $RunCounter/$NumberOfRuns Runs"

	# update status file
	(
		flock 100
		jq --arg Run "$Run" --arg JobId "$JobId" '.[$Run]={"Status":"RUNNING","FilesCopied":"NONE","FilesChecked":"NONE","Merged":"NONE", "R0":{"MasterjobID":$JobId, "Status":"SUBMITTED","SubjobTotal":-1,"SubjobDone":-1,"SubjobActive":-1,"SubjobError":-1},"R1":{"MasterjobID":-1, "Status":"NOT_SUBMITTED","SubjobTotal":-1,"SubjobDone":-1,"SubjobActive":-1,"SubjobError":-1},"R2":{"MasterjobID":-1, "Status":"NOT_SUBMITTED","SubjobTotal":-1,"SubjobDone":-1,"SubjobActive":-1,"SubjobError":-1},"R3":{"MasterjobID":-1, "Status":"NOT_SUBMITTED","SubjobTotal":-1,"SubjobDone":-1,"SubjobActive":-1,"SubjobError":-1}}' $StatusFile | sponge $StatusFile
	) 100>$LockFile

	# dont wait after last job was submitted
	if [ $RunCounter -lt $NumberOfRuns ]; then
		echo "Wait for Grid to catch up..."
		GridTimeout.sh $ShortTimeout
	fi

done

exit 0
