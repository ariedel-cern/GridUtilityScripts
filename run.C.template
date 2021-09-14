/**
 * File              : run.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 07.05.2021
 * Last Modified Date: 06.09.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

// Include macros (see
// https://alice-doc.github.io/alice-analysis-tutorial/analysis/ROOT5-to-6.html):
//    For this to have an effect, it is assumted that some local AliROOT env is
//    initialized, so that env variables ALICE_ROOT and ALICE_PHYSICS are set
#ifdef __CLING__
// Tell  ROOT where to find AliRoot and AliPhysics headers:
R__ADD_INCLUDE_PATH($ALICE_ROOT)
R__ADD_INCLUDE_PATH($ALICE_PHYSICS)
#include "OADB/COMMON/MULTIPLICITY/macros/AddTaskMultSelection.C"
#include "OADB/macros/AddTaskPhysicsSelection.C"
#endif

// local macros
#include "AddTask.C"
#include "CreateAlienHandler.C"

// local function declarations
void LoadLibraries();
TChain *CreateAODChain(const char *aDataDir, Int_t aRuns, Int_t offset);
TChain *CreateESDChain(const char *aDataDir, Int_t aRuns, Int_t offset);

// 2/ The main macro:
void run(Int_t RunNumber = 137161, Int_t nEvents = 100, Int_t offset = 0) {
  // Body:
  // a) Time;
  // b) Load needed libraries;
  // c) Make analysis manager;
  // d) Chains;
  // e) Connect plug-in to the analysis manager;
  // f) Event handlers;
  // g) Task to check the offline trigger: for AODs this is not needed, indeed;
  // h) Add the centrality determination task;
  // i) Setup analysis per centrality bin;
  // j) Enable debug printouts;
  // k) Run the analysis;
  // l) Print real and CPU time used for analysis.

  // get configuration from the environemnt
  const char *analysisMode = std::getenv("ANALYSIS_MODE");
  const char *dataDir = std::getenv("DataDir");
  Bool_t bRunOverData = kTRUE;
  if (std::stoi(std::getenv("RUN_OVER_DATA")) == 1) {
    bRunOverData = kTRUE;
  } else {
    bRunOverData = kFALSE;
  }
  Bool_t bRunOverAOD = kTRUE;
  if (std::stoi(std::getenv("RUN_OVER_AOD")) == 1) {
    bRunOverAOD = kTRUE;
  } else {
    bRunOverAOD = kFALSE;
  }

  // centrality bins
  // Int_t binfirst = 0; // where do we start numbering bins
  // Int_t binlast = 0;  // where do we stop numbering bins
  // const Int_t numberOfCentralityBins = 1;
  // Float_t centralityArray[numberOfCentralityBins + 1] = {
  //     0.0, 100.0}; // in centrality percentile
  std::vector<Int_t> CentralityBins;
  std::stringstream StreamCenBins(std::getenv("CENTRALITY_BIN_EDGES"));
  std::string edge;
  while (StreamCenBins >> edge) {
    CentralityBins.push_back(std::stoi(edge));
  }

  // a) Time:
  TStopwatch timer;
  timer.Start();

  // b) Load needed libraries:
  LoadLibraries();

  // c) Make analysis manager:
  AliAnalysisManager *mgr = new AliAnalysisManager("FlowAnalysisManager");

  // d) Chains:
  TChain *chain = NULL;
  if (TString(analysisMode).EqualTo("local")) {
    if (bRunOverAOD) {
      chain = CreateAODChain(dataDir, nEvents, offset);
    } else {
      chain = CreateESDChain(dataDir, nEvents, offset);
    }
  }

  // e) Connect plug-in to the analysis manager:
  if (TString(analysisMode).EqualTo("grid")) {
    AliAnalysisGrid *alienHandler = CreateAlienHandler(RunNumber);
    if (!alienHandler) {
      return;
    }
    mgr->SetGridHandler(alienHandler);
  }

  // f) Event handlers:
  if (bRunOverAOD) {
    AliVEventHandler *aodH = new AliAODInputHandler();
    mgr->SetInputEventHandler(aodH);
  } else {
    AliVEventHandler *esdH = new AliESDInputHandler();
    mgr->SetInputEventHandler(esdH);
  }
  if (!bRunOverData) {
    AliMCEventHandler *mc = new AliMCEventHandler();
    mgr->SetMCtruthEventHandler(mc);
  }

  // g) Task to check the offline trigger: for AODs this is not needed, indeed
  if (!bRunOverAOD) {
    AddTaskPhysicsSelection(!bRunOverData);
  }

  // h) Add the centrality determination task:
  AliMultSelectionTask *task = AddTaskMultSelection(kFALSE); // user mode
  task->SetSelectedTriggerClass(
      AliVEvent::kINT7); // set the trigger (kINT7 is minimum bias)

  // i) Setup analysis per centrality bin:
  for (std::size_t i = 0; i < CentralityBins.size() - 1; i++) {
    Float_t lowCentralityBinEdge = CentralityBins.at(i);
    Float_t highCentralityBinEdge = CentralityBins.at(i + 1);
    Printf("\nWagon for centrality bin %i: %.1f-%.1f", int(i),
           lowCentralityBinEdge, highCentralityBinEdge);
    AddTask(lowCentralityBinEdge, highCentralityBinEdge, bRunOverAOD);
  }

  // j) Enable debug printouts:
  mgr->SetDebugLevel(2);

  // k) Run the analysis:
  if (!mgr->InitAnalysis()) {
    return;
  }
  mgr->PrintStatus();
  if (TString(analysisMode).EqualTo("local")) {
    mgr->StartAnalysis("local", chain);
  } else if (TString(analysisMode).EqualTo("grid")) {
    mgr->StartAnalysis("grid");
  }

  // l) Print real and CPU time used for analysis:
  timer.Stop();
  timer.Print();

  return;

} // end of void run(...)

//===============================================================================================

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
