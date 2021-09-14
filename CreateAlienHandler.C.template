/**
 * File              : CreateAlienHandler.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 31.05.2021
 * Last Modified Date: 06.09.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

AliAnalysisGrid *CreateAlienHandler(Int_t RunNumber) {
  // Check if user has a valid token, otherwise make one. This has limitations.
  // One can always follow the standard procedure of calling alien-token-init
  // then source /tmp/gclient_env_$UID in the current shell.
  AliAnalysisAlien *plugin = new AliAnalysisAlien();

  plugin->SetRunMode(std::getenv("GRID_RUN_MODE"));
  plugin->SetNtestFiles(2); // Relevant only for run mode "test". By default
  // 10 files will be copied locally and analysed in "test" mode

  // Set versions of used packages
  plugin->SetAPIVersion("V1.1x");
  plugin->SetAliPhysicsVersion(std::getenv("ALIPHYSICS_TAG"));

  Bool_t bRunOverData;
  if (std::stoi(std::getenv("RUN_OVER_DATA")) == 1) {
    bRunOverData = kTRUE;
  } else {
    bRunOverData = kFALSE;
  }
  // Declare input data to be processed - can be done in two ways:
  // METHOD 1: Create automatically XML collections using alien 'find' command.
  // ============================================================================
  //  Example 1: MC production (set in macro runFlowTask.C: bRunOverData =
  //  kFALSE)
  if (!bRunOverData) {
    plugin->SetGridDataDir("/alice/sim/MC_PRODUCTION");
    plugin->SetDataPattern(
        "*AliESDs.root"); // The default data pattern, other may be "*tag.root",
                          // "*ESD.tag.root", etc
    // const Int_t nMC_Runs = 1;
    // Int_t runNo[nMC_Runs] = {137161};
    // for (Int_t r = 0; r < nMC_Runs; r++) {
    //   plugin->AddRunNumber(runNo[r]);
    // }
    // handle runs in GridConfig.sh
    plugin->AddRunNumber(RunNumber);
    // plugin->AddRunNumber(119844); // Alternatively use e.g.
    // plugin->SetRunRange(105044,106044); to add more runs in one go
  } else {
    // ============================================================================
    //  Example 2: Real data (set in macro runFlowTask.C: bRunOverData = kTRUE,
    //  MCEP = kFALSE)
    // alien_find works this way: alien_find -x collection -l 10  -o 0
    // /alice/data/2010/LHC10h/000137161 *ESDs/pass2/AOD160/*AOD.root
    plugin->SetGridDataDir("/alice/data/2010/LHC10h");
    // plugin->SetDataPattern("*ESDs/pass2/*ESDs.root"); // running over ESDs
    plugin->SetDataPattern("*ESDs/pass2/AOD160/*AOD.root"); // running over AODs

    plugin->SetRunPrefix("000"); // IMPORTANT!
    plugin->SetOutputToRunNo();  // IMPORTANT!

    // Int_t runNo[90] = {
    //     139510, 139507, 139505, 139503, 139465, 139438, 139437, 139360,
    //     139329, 139328, 139314, 139310, 139309, 139173, 139107, 139105,
    //     139038, 139037, 139036, 139029, 139028, 138872, 138871, 138870,
    //     138837, 138732, 138730, 138666, 138662, 138653, 138652, 138638,
    //     138624, 138621, 138583, 138582, 138578, 138534, 138469, 138442,
    //     138439, 138438, 138396, 138364, 138275, 138225, 138201, 138197,
    //     138192, 138190, 137848, 137844, 137752, 137751, 137724, 137722,
    //     137718, 137704, 137693, 137692, 137691, 137686, 137685, 137639,
    //     137638, 137608, 137595, 137549, 137546, 137544, 137541, 137539,
    //     137531, 137530, 137443, 137441, 137440, 137439, 137434, 137432,
    //     137431, 137430, 137243, 137236, 137235, 137232, 137231, 137230,
    //     137162, 137161}; // Remark: 137366 and 137135 do NOT have AODs in
    //     AOD160

    // for (Int_t r = 0; r < 1; r++) {
    //   plugin->AddRunNumber(runNo[r]);
    // }
    plugin->AddRunNumber(RunNumber);

  } // end to else

  // ============================================================================

  // METHOD 2: Declare existing data files (raw collections, xml collections,
  // root file) If no path mentioned data is supposed to be in the work
  // directory (see SetGridWorkingDir()) XML collections added via this method
  // can be combined with the first method if the content is compatible (using
  // or not tags)
  // plugin->AddDataFile("hijingWithoutFlow10000Evts.xml");
  //   plugin->AddDataFile("/alice/data/2008/LHC08c/000057657/raw/Run57657.Merged.RAW.tag.root");
  // plugin->AddDataFile("/alice/cern.ch/user/a/ariedel/weights.root");
  // plugin->AddDataFile("Run137161.RAW.tag.root");
  // plugin->AddDataFile("file:///scratch/ga45can/tmp/aliceAnalysis/MCclosure/"
  //                     "Run137161.RAW.tag.root");
  plugin->SetCheckCopy(kFALSE);
  // Define alien work directory where all files will be copied. Relative to
  // alien $HOME.
  plugin->SetGridWorkingDir(std::getenv("GRID_WORKING_DIR_REL"));
  // Declare alien output directory. Relative to working directory.
  plugin->SetGridOutputDir(std::getenv(
      "GRID_OUTPUT_DIR_REL")); // In this case will be $HOME/work/output
  // Declare the analysis source files names separated by blancs. To be compiled
  // runtime using ACLiC on the worker nodes:
  // ... (if this is needed see in official tutorial example how to do it!)

  // Declare all libraries (other than the default ones for the framework. These
  // will be loaded by the generated analysis macro. Add all extra files (task
  // .cxx/.h) here.
  // plugin->SetAdditionalLibs("libCORRFW.so libTOFbase.so libTOFrec.so");
  plugin->SetAdditionalLibs(
      "libGui.so libProof.so libMinuit.so libXMLParser.so "
      "libRAWDatabase.so libRAWDatarec.so libCDB.so libSTEERBase.so "
      //"libSTEER.so libTPCbase.so libTOFbase.so libTOFrec.so "
      "libSTEER.so libTPCbase.so "
      //"libTRDbase.so libVZERObase.so libVZEROrec.so libT0base.so "
      //"libT0rec.so libTENDER.so libTENDERSupplies.so "
      "libPWGflowBase.so libPWGflowTasks.so");
  // Do not specify your outputs by hand anymore:
  plugin->SetDefaultOutputs(kTRUE);
  // To specify your outputs by hand set plugin->SetDefaultOutputs(kFALSE); and
  // comment in line plugin->SetOutputFiles("..."); and
  // plugin->SetOutputArchive("..."); bellow. Declare the output file names
  // separated by blancs. (can be like: file.root or
  // file.root@ALICE::Niham::File)
  // plugin->SetOutputFiles("AnalysisResults.root");
  // Optionally define the files to be archived.
  // plugin->SetOutputArchive("log_archive.zip:stdout,stderr@ALICE::NIHAM::File
  // root_archive.zip:*.root@ALICE::NIHAM::File");
  // plugin->SetOutputArchive("log_archive.zip:stdout,stderr");
  // plugin->SetOutputArchive("log_archive.zip:");
  // Optionally set a name for the generated analysis macro (default
  // MyAnalysis.C)
  plugin->SetAnalysisMacro(std::getenv("ANALYSIS_MACRO_FILE_NAME"));
  // Optionally set maximum number of input files/subjob (default 100, put 0 to
  // ignore)
  plugin->SetSplitMaxInputFileNumber(
      std::stoi(std::getenv("INPUT_FILES_PER_SUBJOB")));
  // Optionally set number of runs per masterjob:
  plugin->SetNrunsPerMaster(std::stoi(std::getenv("RUNS_PER_MASTERJOB")));
  // Optionally set overwrite mode. Will trigger overwriting input data
  // colections AND existing output files:
  plugin->SetOverwriteMode(kTRUE);
  // Optionally set number of failed jobs that will trigger killing waiting
  // sub-jobs.
  // plugin->SetMaxInitFailed(99);
  // Optionally resubmit threshold.
  plugin->SetMasterResubmitThreshold(
      std::stoi(std::getenv("MASTER_RESUBMIT_THRESHOLD")));
  // Optionally set time to live (default 30000 sec)
  plugin->SetTTL(std::stoi(std::getenv("TIME_TO_LIVE")));
  // Optionally set input format (default xml-single)
  plugin->SetInputFormat("xml-single");
  // Optionally modify the name of the generated JDL (default analysis.jdl)
  plugin->SetJDLName(std::getenv("JDL_FILE_NAME"));
  // Optionally modify job price (default 1)
  plugin->SetPrice(1);
  // Optionally modify split mode (default 'se')
  plugin->SetSplitMode("se");

  return plugin;
}
