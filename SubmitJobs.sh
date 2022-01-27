#!/bin/bash
# File              : SubmitJobs.sh
# Author            : Anton Riedel <anton.riedel@tum.de>
# Date              : 25.08.2021
# Last Modified Date: 27.01.2022
# Last Modified By  : Anton Riedel <anton.riedel@tum.de>

# submit jobs to grid

[ ! -f config.json ] && echo "No config file!!!" && exit 1

# if running locally, just call aliroot and bail out
if [ "$(jq -r '.task.AnalysisMode' config.json)" = "local" ]; then
	echo "################################################################################"
	DataDir="$(jq -r '.task.LocalDataDir' config.json)"
	echo "Running locally over $DataDir"
	[ ! -d $DataDir ] && echo "No local data found" && exit 2
	aliroot -q -l -b run.C\(\"config.json\",137161\)
	echo "################################################################################"
	exit 0
fi

echo "################################################################################"
echo "Running on Grid"

# get variables from config file
GridWorkDir="$(jq -r '.task.GridHomeDir' config.json)/$(jq -r '.task.GridWorkDir' config.json)"
GridXmlCollection="$(jq -r '.task.GridXmlCollection' config.json)"
Jdl="$(jq -r '.task.Jdl' config.json)"
Macro="$(jq -r '.task.AnalysisMacro' config.json)"

echo "clean up remote working dir"
alien_rm -R -f "alien:${GridWorkDir}"
alien_mkdir -s "alien:${GridWorkDir}"

echo "clean up local working dir"
rm -rf GridFiles
mkdir -p GridFiles
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
NumberAOD=""
StatusFile="$(jq -r '.StatusFile' config.json)"
echo "{}" >$StatusFile
LockFile="$(jq -r '.LockFile' config.json)"
UseWeights=$(jq -r '.task.UseWeights' config.json)
echo "################################################################################"

if [ "$UseWeights" = "false" ]; then
	echo "Do not use run specific weights, create dummy working dir for all runns"
	echo "Run steering macros in offline mode to generate necessary files"

	aliroot -q -l -b run.C\(\"config.json\",137161\) || exit 2

	echo "Modify jdl to use XML collection in ${GridXmlCollection}"
	sed -i -e "/nodownload/ s|${GridWorkDir}|${GridXmlCollection}|" $Jdl

	echo "Copy everything we need to grid"
	{
		alien_cp "file:${Jdl}" "alien:${GridWorkDir}/"
		alien_cp "file:${Macro}" "alien:${GridWorkDir}/"
		alien_cp "file:analysis.sh" "alien:${GridWorkDir}/"
		alien_cp "file:analysis_validation.sh" "alien:${GridWorkDir}/"
		alien_cp "file:analysis.root" "alien:${GridWorkDir}/"
	} || exit 2

	echo "Clean up local working dir"
	{
		mkdir -p "GridFiles/Dummy"
		mv "${Jdl}" "GridFiles/Dummy/"
		mv "${Macro}" "GridFiles/Dummy/"
		mv "analysis.sh" "GridFiles/Dummy/"
		mv "analysis_validation.sh" "GridFiles/Dummy/"
		mv "analysis.root" "GridFiles/Dummy/"
	}
fi

# submit jobs run by run
for Run in $Runs; do

	until CheckQuota.sh; do
		GridTimeout.sh $LongTimeout
	done

	echo "################################################################################"
	echo "Submit Run $Run with Task $BaseName"

	if [ "$UseWeights" == "true" ]; then

		echo "Generate all necessary files"

		echo "Run steering macros in offline mode to generate necessary files"
		aliroot -q -l -b run.C\(\"config.json\",$Run\) || exit 2

		echo "Modify jdl to use XML collection in ${GridXmlCollection}"
		sed -i -e "/nodownload/ s|${GridWorkDir}|${GridXmlCollection}|" $Jdl

		echo "Modify jdl to use run specific input"
		sed -i -e "/${Macro}/ s|${GridWorkDir}|${GridWorkDir}/${Run}|" $Jdl
		sed -i -e "/analysis.root/ s|${GridWorkDir}|${GridWorkDir}/${Run}|" $Jdl
		sed -i -e "/Executable/ s|${GridWorkDir}|${GridWorkDir}/${Run}|" $Jdl
		sed -i -e "/Validationcommand/ s|${GridWorkDir}|${GridWorkDir}/${Run}|" $Jdl

		echo "Copy everything we need to grid"
		{
			alien_mkdir -p "alien:${GridWorkDir}/${Run}/"
			alien_cp "file:${Jdl}" "alien:${GridWorkDir}/${Run}/" -retry 10
			alien_cp "file:${Macro}" "alien:${GridWorkDir}/${Run}/" -retry 10
			alien_cp "file:analysis.sh" "alien:${GridWorkDir}/${Run}/" -retry 10
			alien_cp "file:analysis_validation.sh" "alien:${GridWorkDir}/${Run}/" -retry 10
			alien_cp "file:analysis.root" "alien:${GridWorkDir}/${Run}/" -retry 10
		} || exit 2

		echo "Clean up local working directory"
		{
			mkdir -p "GridFiles/${Run}"
			mv "${Jdl}" "GridFiles/${Run}/"
			mv "${Macro}" "GridFiles/${Run}/"
			mv "analysis.sh" "GridFiles/${Run}/"
			mv "analysis_validation.sh" "GridFiles/${Run}/"
			mv "analysis.root" "GridFiles/${Run}/"
		} || exit 4

	fi

	JobId="null"

	until [ "$JobId" != "null" ]; do
		if [ "$UseWeights" == "true" ]; then
			JobId=$(alien_submit ${GridWorkDir}/${Run}/${Jdl} "000${Run}.xml" $Run -json | jq -r '.results[0].jobId')
		else
			JobId=$(alien_submit ${GridWorkDir}/${Jdl} "000${Run}.xml" $Run -json | jq -r '.results[0].jobId')
		fi
	done

	if [ "$RunOverData" == "true" ]; then
		Xml="${GridXmlCollection}/000${Run}.xml"
	else
		Xml="${GridXmlCollection}/${Run}.xml"
	fi

	# does not always work on the first try
	# alien.py cat works like a download, which fails from time to time
	NumberAOD="0"
	until [ "$NumberAOD" -ge 1 ]; do
		NumberAOD="$(alien.py cat $Xml | grep "event name" | tail -n1 | awk -F\" '{print $2}')"
	done

	((RunCounter++))
	echo "Submitted $RunCounter/$NumberOfRuns Runs"

	# update status file
	{
		flock 100
		jq --arg Run "$Run" --arg JobId "$JobId" --arg NumberAOD "$NumberAOD" '.[$Run]={"Status":"RUNNING","FilesCopied":0,"FilesChecked":0,"Merged":0, "R0":{"MasterjobID":$JobId, "Status":"SUBMITTED","SubjobTotal":-1,"SubjobDone":-1,"SubjobActive":-1,"SubjobWaiting":-1,"SubjobError":-1,"AODTotal":$NumberAOD,"AODError":-1},"R1":{"MasterjobID":-1, "Status":"NOT_SUBMITTED","SubjobTotal":-1,"SubjobDone":-1,"SubjobActive":-1,"SubjobWaiting":-1,"SubjobError":-1,"AODTotal":-1,"AODError":-1},"R2":{"MasterjobID":-1, "Status":"NOT_SUBMITTED","SubjobTotal":-1,"SubjobDone":-1,"SubjobActive":-1,"SubjobWaiting":-1,"SubjobError":-1,"AODTotal":-1,"AODError":-1},"R3":{"MasterjobID":-1, "Status":"NOT_SUBMITTED","SubjobTotal":-1,"SubjobDone":-1,"SubjobActive":-1,"SubjobWaiting":-1,"SubjobError":-1,"AODTotal":-1,"AODError":-1}}' $StatusFile | sponge $StatusFile
	} 100>$LockFile

	# dont wait after last job was submitted
	if [ "$RunCounter" -lt "$NumberOfRuns" ]; then
		echo "Wait for Grid to catch up..."
		GridTimeout.sh $ShortTimeout
	fi

done

exit 0
