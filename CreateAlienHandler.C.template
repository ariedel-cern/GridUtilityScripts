/**
 * File              : CreateAlienHandler.C.template
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 31.05.2021
 * Last Modified Date: 19.01.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include <fstream>
#include <nlohmann/json.hpp>
#include <string>

AliAnalysisGrid *CreateAlienHandler(const char *ConfigFileName,
                                    Int_t RunNumber) {

  // load config file
  std::fstream ConfigFile(ConfigFileName);
  nlohmann::json Jconfig = nlohmann::json::parse(ConfigFile);

  // Check if user has a valid token, otherwise make one. This has limitations.
  // One can always follow the standard procedure of calling alien-token-init
  // then source /tmp/gclient_env_$UID in the current shell.
  AliAnalysisAlien *plugin = new AliAnalysisAlien();

  plugin->SetRunMode("offline");
  plugin->SetNtestFiles(1); // Relevant only for run mode "test". By default
  // 10 files will be copied locally and analysed in "test" mode

  // Set versions of used packages
  plugin->SetAPIVersion("V1.1x");
  plugin->SetAliPhysicsVersion(
      Jconfig["task"]["AnalysisTag"].get<std::string>().c_str());

  plugin->SetGridDataDir(
      Jconfig["task"]["GridDataDir"].get<std::string>().c_str());
  plugin->SetDataPattern(
      Jconfig["task"]["DataPattern"].get<std::string>().c_str());

  if (Jconfig["task"]["RunOverData"].get<bool>()) {
    plugin->SetRunPrefix("000"); // IMPORTANT!
    plugin->SetOutputToRunNo();  // IMPORTANT!
  }

  // dummy run number
  plugin->AddRunNumber(RunNumber);

  // ============================================================================

  // METHOD 2: Declare existing data files (raw collections, xml collections,
  // root file) If no path mentioned data is supposed to be in the work
  // directory(see SetGridWorkingDir()) XML collections added via this method
  // can be combined with the first method if the content is compatible
  // (using or not tags)
  // plugin->AddDataFile("hijingWithoutFlow10000Evts.xml");
  //   plugin->AddDataFile("/alice/data/2008/LHC08c/000057657/raw/Run57657.Merged.RAW.tag.root");
  // plugin->AddDataFile("/alice/cern.ch/user/a/ariedel/weights.root");
  // plugin->AddDataFile("Run137161.RAW.tag.root");
  // plugin->AddDataFile("file:///scratch/ga45can/tmp/aliceAnalysis/MCclosure/"
  //                     "Run137161.RAW.tag.root");
  //
  plugin->SetCheckCopy(kFALSE);
  // Define alien work directory where all files will be copied. Relative to
  // alien $HOME.
  plugin->SetGridWorkingDir(
      Jconfig["task"]["GridWorkDir"].get<std::string>().c_str());
  // Declare alien output directory. Relative to working directory.
  plugin->SetGridOutputDir(
      Jconfig["task"]["GridOutputDir"]
          .get<std::string>()
          .c_str()); // In this case will be $HOME/work/output
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
  plugin->SetAnalysisMacro(
      Jconfig["task"]["AnalysisMacro"].get<std::string>().c_str());
  // Optionally set maximum number of input files/subjob (default 100, put 0 to
  // ignore)
  plugin->SetSplitMaxInputFileNumber(
      Jconfig["task"]["FilesPerSubjob"].get<std::vector<Int_t>>().at(0));
  // Optionally set number of runs per masterjob:
  plugin->SetNrunsPerMaster(1);
  // Optionally set overwrite mode. Will trigger overwriting input data
  // colections AND existing output files:
  plugin->SetOverwriteMode(kTRUE);
  // Optionally set number of failed jobs that will trigger killing waiting
  // sub-jobs.
  // plugin->SetMaxInitFailed(99);
  // Optionally resubmit threshold.
  plugin->SetMasterResubmitThreshold(50);
  // Optionally set time to live (default 30000 sec)
  plugin->SetTTL(Jconfig["task"]["TimeToLive"].get<std::vector<Int_t>>().at(0));
  // Optionally set input format (default xml-single)
  plugin->SetInputFormat("xml-single");
  // Optionally modify the name of the generated JDL (default analysis.jdl)
  plugin->SetJDLName(Jconfig["task"]["Jdl"].get<std::string>().c_str());
  // Optionally modify job price (default 1)
  plugin->SetPrice(1);
  // Optionally modify split mode (default 'se')
  plugin->SetSplitMode("se");

  return plugin;
}
