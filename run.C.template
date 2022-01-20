/**
 * File              : run.C.template
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 07.05.2021
 * Last Modified Date: 19.01.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include <fstream>
#include <nlohmann/json.hpp>
#include <string>

#ifdef __CLING__
// Tell  ROOT where to find AliRoot and AliPhysics headers:
R__ADD_INCLUDE_PATH($ALICE_ROOT)
R__ADD_INCLUDE_PATH($ALICE_PHYSICS)
#include "OADB/COMMON/MULTIPLICITY/macros/AddTaskMultSelection.C"
#include "OADB/macros/AddTaskPhysicsSelection.C"
#endif

#include "AddTask.C"
#include "CreateAlienHandler.C"

// local function declarations
void LoadLibraries();
TChain *CreateAODChain(const char *aDataDir, Int_t aRuns, Int_t offset);
TChain *CreateESDChain(const char *aDataDir, Int_t aRuns, Int_t offset);

void run(const char *ConfigFileName, Int_t RunNumber) {

  // Time
  TStopwatch timer;
  timer.Start();

  // load config file
  std::fstream ConfigFile(ConfigFileName);
  nlohmann::json Jconfig = nlohmann::json::parse(ConfigFile);

  // Load needed libraries
  LoadLibraries();

  // Make analysis manager
  AliAnalysisManager *mgr = new AliAnalysisManager("FlowAnalysisManager");

  // d) Chains:
  // only need for local analysis
  TChain *chain = NULL;
  Int_t nEvents = 100;
  Int_t offset = 0;

  if (std::string("local") ==
      Jconfig["task"]["AnalysisMode"].get<std::string>()) {
    if (Jconfig["task"]["RunOverAOD"].get<bool>()) {
      chain = CreateAODChain(
          Jconfig["task"]["LocalDataDir"].get<std::string>().c_str(), nEvents,
          offset);
    } else {
      chain = CreateESDChain(
          Jconfig["task"]["LocalDataDir"].get<std::string>().c_str(), nEvents,
          offset);
    }
  }

  // Connect plug-in to the analysis manager:
  if (std::string("grid") ==
      Jconfig["task"]["AnalysisMode"].get<std::string>()) {
    AliAnalysisGrid *alienHandler =
        CreateAlienHandler(ConfigFileName, RunNumber);
    if (!alienHandler) {
      return;
    }
    mgr->SetGridHandler(alienHandler);
  }

  // Event handlers
  if (Jconfig["task"]["RunOverAOD"].get<bool>()) {
    AliVEventHandler *aodH = new AliAODInputHandler();
    mgr->SetInputEventHandler(aodH);
  } else {
    AliVEventHandler *esdH = new AliESDInputHandler();
    mgr->SetInputEventHandler(esdH);
  }
  if (!Jconfig["task"]["RunOverData"].get<bool>()) {
    AliMCEventHandler *mc = new AliMCEventHandler();
    mgr->SetMCtruthEventHandler(mc);
  }

  // Task to check the offline trigger: for AODs this is not needed, indeed
  if (!Jconfig["task"]["RunOverAOD"].get<bool>()) {
    AddTaskPhysicsSelection(kTRUE);
  }

  //  Add the centrality determination task
  AliMultSelectionTask *task = AddTaskMultSelection(kFALSE); // user mode
  task->SetSelectedTriggerClass(
      AliVEvent::kINT7); // set the trigger (kINT7 is minimum bias)

  std::vector<Double_t> CentralityBinEdges =
      Jconfig["task"]["CentralityBinEdges"].get<std::vector<Double_t>>();

  // Setup analysis per centrality bin
  for (std::size_t i = 0; i < CentralityBinEdges.size() - 1; i++) {
    Float_t lowCentralityBinEdge = CentralityBinEdges.at(i);
    Float_t highCentralityBinEdge = CentralityBinEdges.at(i + 1);
    std::cout << std::endl
              << "Wagon for centrality bin (" << i << "/"
              << CentralityBinEdges.size() - 1 << "): " << lowCentralityBinEdge
              << "-" << highCentralityBinEdge << std::endl;
    AddTask(ConfigFileName, RunNumber, lowCentralityBinEdge,
            highCentralityBinEdge);
  }

  // Enable debug printouts
  mgr->SetDebugLevel(2);

  // Run the analysis
  if (!mgr->InitAnalysis()) {
    return;
  }
  mgr->PrintStatus();
  if (std::string("local") ==
      Jconfig["task"]["AnalysisMode"].get<std::string>()) {
    mgr->StartAnalysis("local", chain);
  } else if (std::string("grid") ==
             Jconfig["task"]["AnalysisMode"].get<std::string>()) {
    mgr->StartAnalysis("grid");
  }

  // Print real and CPU time used for analysis:
  timer.Stop();
  timer.Print();

  return;
}

void LoadLibraries() {
  // Load the needed libraries (most of them already loaded by aliroot).

  gSystem->Load("libCore");
  gSystem->Load("libTree");
  gSystem->Load("libGeom");
  gSystem->Load("libVMC");
  gSystem->Load("libXMLIO");
  gSystem->Load("libPhysics");
  gSystem->Load("libXMLParser");
  gSystem->Load("libProof");
  gSystem->Load("libMinuit");

  gSystem->Load("libSTEERBase");
  gSystem->Load("libCDB");
  gSystem->Load("libRAWDatabase");
  gSystem->Load("libRAWDatarec");
  gSystem->Load("libESD");
  gSystem->Load("libAOD");
  // gSystem->Load("libSTEER");
  gSystem->Load("libANALYSIS");
  gSystem->Load("libANALYSISalice");
  gSystem->Load("libTPCbase");

  /* not really neeeded:
  gSystem->Load("libTOFbase");
  gSystem->Load("libTOFrec");
  gSystem->Load("libTRDbase");
  gSystem->Load("libVZERObase");
  gSystem->Load("libVZEROrec");
  gSystem->Load("libT0base");
  gSystem->Load("libT0rec");
  gSystem->Load("libTENDER");
  gSystem->Load("libTENDERSupplies");
  */

  // Flow libraries:
  gSystem->Load("libPWGflowBase");
  gSystem->Load("libPWGflowTasks");

} // end of void LoadLibraries()

//===============================================================================================

TChain *CreateESDChain(const char *aDataDir, Int_t aRuns, Int_t offset) {
  // Helper macros for creating chains
  // adapted from original: CreateESDChain.C,v 1.10 jgrosseo Exp

  // creates chain of files in a given directory or file containing a list.
  // In case of directory the structure is expected as:
  // <aDataDir>/<dir0>/AliESDs.root
  // <aDataDir>/<dir1>/AliESDs.root
  // ...

  if (!aDataDir) {
    return 0;
  }

  Long_t id, size, flags, modtime;
  if (gSystem->GetPathInfo(aDataDir, &id, &size, &flags, &modtime)) {
    printf("WARNING: Sorry, but 'dataDir' set to %s I really coudn't found.\n",
           aDataDir);
    return 0;
  }

  TChain *chain = new TChain("esdTree");
  TChain *chaingAlice = 0;

  if (flags & 2) {
    TString execDir(gSystem->pwd());
    TSystemDirectory *baseDir = new TSystemDirectory(".", aDataDir);
    TList *dirList = baseDir->GetListOfFiles();
    Int_t nDirs = dirList->GetEntries();
    gSystem->cd(execDir);
    Int_t count = 0;
    for (Int_t iDir = 0; iDir < nDirs; ++iDir) {
      TSystemFile *presentDir = (TSystemFile *)dirList->At(iDir);
      if (!presentDir || !presentDir->IsDirectory() ||
          strcmp(presentDir->GetName(), ".") == 0 ||
          strcmp(presentDir->GetName(), "..") == 0) {
        continue;
      }

      if (offset > 0) {
        --offset;
        continue;
      }

      if (count++ == aRuns) {
        break;
      }

      TString presentDirName(aDataDir);
      presentDirName += "/";
      presentDirName += presentDir->GetName();
      chain->Add(presentDirName + "/AliESDs.root/esdTree");
      cout << "Adding to TChain the ESDs from " << presentDirName << endl;
    } // end of for (Int_t iDir=0; iDir<nDirs; ++iDir)
  }   // end of if(flags & 2)
  else {
    // Open the input stream:
    ifstream in;
    in.open(aDataDir);
    Int_t count = 0;
    // Read the input list of files and add them to the chain:
    TString esdfile;
    while (in.good()) {
      in >> esdfile;
      if (!esdfile.Contains("root"))
        continue; // protection

      if (offset > 0) {
        --offset;
        continue;
      }

      if (count++ == aRuns) {
        break;
      }

      // add esd file
      chain->Add(esdfile);
    } // end of while(in.good())
    in.close();
  }

  return chain;

} // end of TChain* CreateESDChain(const char* aDataDir, Int_t aRuns, Int_t
  // offset)

//===============================================================================================

TChain *CreateAODChain(const char *aDataDir, Int_t aRuns, Int_t offset) {
  // creates chain of files in a given directory or file containing a list.
  // In case of directory the structure is expected as:
  // <aDataDir>/<dir0>/AliAOD.root
  // <aDataDir>/<dir1>/AliAOD.root
  // ...

  if (!aDataDir)
    return 0;

  Long_t id, size, flags, modtime;
  if (gSystem->GetPathInfo(aDataDir, &id, &size, &flags, &modtime)) {
    printf("%s not found.\n", aDataDir);
    return 0;
  }

  TChain *chain = new TChain("aodTree");
  TChain *chaingAlice = 0;

  if (flags & 2) {
    TString execDir(gSystem->pwd());
    TSystemDirectory *baseDir = new TSystemDirectory(".", aDataDir);
    TList *dirList = baseDir->GetListOfFiles();
    Int_t nDirs = dirList->GetEntries();
    gSystem->cd(execDir);

    Int_t count = 0;

    for (Int_t iDir = 0; iDir < nDirs; ++iDir) {
      TSystemFile *presentDir = (TSystemFile *)dirList->At(iDir);
      if (!presentDir || !presentDir->IsDirectory() ||
          strcmp(presentDir->GetName(), ".") == 0 ||
          strcmp(presentDir->GetName(), "..") == 0)
        continue;

      if (offset > 0) {
        --offset;
        continue;
      }

      if (count++ == aRuns)
        break;

      TString presentDirName(aDataDir);
      presentDirName += "/";
      presentDirName += presentDir->GetName();
      chain->Add(presentDirName + "/AliAOD.root/aodTree");
      // cerr<<presentDirName<<endl;
    }

  } else {
    // Open the input stream
    ifstream in;
    in.open(aDataDir);

    Int_t count = 0;

    // Read the input list of files and add them to the chain
    TString aodfile;
    while (in.good()) {
      in >> aodfile;
      if (!aodfile.Contains("root"))
        continue; // protection

      if (offset > 0) {
        --offset;
        continue;
      }

      if (count++ == aRuns)
        break;

      // add aod file
      chain->Add(aodfile);
    }

    in.close();
  }

  return chain;

} // end of TChain* CreateAODChain(const char* aDataDir, Int_t aRuns, Int_t
  // offset)
