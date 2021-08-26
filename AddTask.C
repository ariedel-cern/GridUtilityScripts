/**
 * File              : AddTask.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 07.05.2021
 * Last Modified Date: 26.08.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */
// Remark: This one is reviewed and refurbished as of 20210504 to work with ROOT
// 6
//         For the same legacy macros running with ROOT 5, see
//         ~/Students/ThreeMacros/ROOT5/

/////////////////////////////////////////////////////////////////////////////////////////////
//
// AddTask* macro for flow analysis
// Creates a Flow Event task and adds it to the analysis manager.
// Sets the cuts using the correction framework (CORRFW) classes.
// Also creates Flow Analysis tasks and connects them to the output of the flow
// event task.
//
/////////////////////////////////////////////////////////////////////////////////////////////

void AddTask(Float_t centerMin = 0., Float_t centerMax = 100.,
             Bool_t bRunOverAOD = kTRUE) {
  // File name:
  TString fileName(std::getenv("GridOutputRootFile"));

  // Get the pointer to the existing analysis manager via the static access
  // method.
  //==============================================================================
  AliAnalysisManager *mgr = AliAnalysisManager::GetAnalysisManager();
  if (!mgr) {
    Error("AddTask.C macro", "No analysis manager to connect to.");
    return NULL;
  }

  // Check the analysis type using the event handlers connected to the analysis
  // manager. The availability of MC handler can also be checked here.
  //==============================================================================
  if (!mgr->GetInputEventHandler()) {
    Error("AddTask.C macro", "This task requires an input event handler");
    return nullptr;
  }

  // Configure your analysis task here:
  AliAnalysisTaskAR *task = new AliAnalysisTaskAR(
      Form("%s_%.1f-%.1f", std::getenv("TaskBaseName"), centerMin, centerMax),
      kFALSE);

  // setters for qa histograms
  task->SetFillQAHistograms(kTRUE);

  // setters for track control histograms
  task->SetTrackControlHistogramBinning(kPT, 1000, 0., 6.);
  task->SetTrackControlHistogramBinning(kPHI, 360, 0., TMath::TwoPi());
  task->SetTrackControlHistogramBinning(kETA, 100, -1., 1.);
  task->SetTrackControlHistogramBinning(kTPCNCLS, 99, 60, 159.);
  task->SetTrackControlHistogramBinning(kITSNCLS, 10, 0., 10.);
  task->SetTrackControlHistogramBinning(kCHI2PERNDF, 100, 0.2, 5.);
  task->SetTrackControlHistogramBinning(kDCAZ, 100, -5., 5.);
  task->SetTrackControlHistogramBinning(kDCAXY, 100, -5., 5.);
  // setters for event control histograms
  task->SetEventControlHistogramBinning(kMUL, 200, 0, 20000);
  task->SetEventControlHistogramBinning(kCEN, 10, centerMin, centerMax);
  task->SetEventControlHistogramBinning(kNCONTRIB, 100, 0, 10000);
  task->SetEventControlHistogramBinning(kX, 20, -20, 20);
  task->SetEventControlHistogramBinning(kY, 20, -20, 20);
  task->SetEventControlHistogramBinning(kZ, 20, -20, 20);
  // set centrality selection criterion
  task->SetCentralityEstimator("V0M");

  // setters for track cuts
  task->SetTrackCuts(kPT, 0.2, 5.);
  task->SetTrackCuts(kPHI, 0, TMath::TwoPi());
  task->SetTrackCuts(kETA, -0.8, 0.8);
  task->SetTrackCuts(kCHARGE, 0.9, 1.1);
  task->SetTrackCuts(kTPCNCLS, 70, 159.);
  task->SetTrackCuts(kITSNCLS, 0., 8.);
  task->SetTrackCuts(kCHI2PERNDF, 0.3, 4.);
  task->SetTrackCuts(kDCAZ, -3.0, 3.0);
  task->SetTrackCuts(kDCAXY, -3.0, 3.0);
  // setters for event cuts
  task->SetEventCuts(kMUL, 10, 20000);
  task->SetEventCuts(kCEN, centerMin, centerMax);
  task->SetEventCuts(kNCONTRIB, 5, 1e6);
  task->SetEventCuts(kX, -10., 10.);
  task->SetEventCuts(kY, -10., 10.);
  task->SetEventCuts(kZ, -10., 10.);
  // other cuts
  task->SetFilterbit(128);
  task->SetPrimaryOnlyCut(kTRUE);

  // setters for final result profiles
  std::vector<std::vector<Int_t>> correlators = {{-2, 2}};
  task->SetCorrelators(correlators);

  // Add your task to the analysis manager:
  mgr->AddTask(task);
  cout << "Added to manager: " << task->GetName() << endl;

  // Define input/output containers:
  TString output = "AnalysisResults.root";
  /* determined by the framework, this is TDirectoryFile holding all lists */
  output += ":outputAnalysis";

  AliAnalysisDataContainer *cinput = mgr->GetCommonInputContainer();
  AliAnalysisDataContainer *coutput = NULL;
  coutput = mgr->CreateContainer(task->GetName(), TList::Class(),
                                 AliAnalysisManager::kOutputContainer, output);
  mgr->ConnectInput(task, 0, cinput);
  mgr->ConnectOutput(task, 1, coutput);

} // void AddTaskTEST(Float_t centerMin=0.,Float_t centerMax=100.,TString
  // fileNameBase="AnalysisResults",Bool_t bRunOverAOD=kFALSE)
