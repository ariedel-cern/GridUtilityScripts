/**
 * File              : AddTask.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 07.05.2021
 * Last Modified Date: 27.08.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

// AddTask* macro for flow analysis
// Creates a Flow Event task and adds it to the analysis manager.
// Sets the cuts using the correction framework (CORRFW) classes.
// Also creates Flow Analysis tasks and connects them to the output of the flow
// event task.

void AddTask(Float_t centerMin = 0., Float_t centerMax = 100.,
             Bool_t bRunOverAOD = kTRUE) {
  TString OutputFile(std::getenv("GridOutputRootFile"));

  // Get the pointer to the existing analysis manager via the static access
  // method.
  AliAnalysisManager *mgr = AliAnalysisManager::GetAnalysisManager();
  if (!mgr) {
    Error("AddTask.C macro", "No analysis manager to connect to.");
    return NULL;
  }

  // Check the analysis type using the event handlers connected to the analysis
  // manager. The availability of MC handler can also be checked here.
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
  task->SetEventControlHistogramBinning(kMUL, 2000, 0, 1600);
  task->SetEventControlHistogramBinning(kMULQ, 300, 0, 3000);
  task->SetEventControlHistogramBinning(kMULW, 300, 0, 3000);
  task->SetEventControlHistogramBinning(kMULREF, 300, 0, 3000);
  task->SetEventControlHistogramBinning(kNCONTRIB, 300, 0, 3000);
  task->SetEventControlHistogramBinning(kCEN, 10, centerMin, centerMax);
  task->SetEventControlHistogramBinning(kX, 120, -12, 12);
  task->SetEventControlHistogramBinning(kY, 120, -12, 12);
  task->SetEventControlHistogramBinning(kZ, 120, -12, 12);
  task->SetEventControlHistogramBinning(kVPOS, 100, 0, 20);
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
  task->SetEventCuts(kMUL, 2, 1600);
  task->SetEventCuts(kMULQ, 2, 3000);
  task->SetEventCuts(kMULW, 2, 3000);
  task->SetEventCuts(kMULREF, 2, 3000);
  task->SetEventCuts(kNCONTRIB, 2, 3000);
  task->SetEventCuts(kCEN, centerMin, centerMax);
  task->SetEventCuts(kX, -10., 10.);
  task->SetEventCuts(kY, -10., 10.);
  task->SetEventCuts(kZ, -10., 10.);
  task->SetEventCuts(kVPOS, 1e-6, 18.);
  // other cuts
  task->SetFilterbit(128);
  task->SetPrimaryOnlyCut(kTRUE);
  task->SetCenCorCut(1.1, 2);

  // setters for correlators we want to compute
  std::vector<std::vector<Int_t>> correlators = {{-2, 2}};
  task->SetCorrelators(correlators);

  // Add your task to the analysis manager:
  mgr->AddTask(task);
  cout << "Added to manager: " << task->GetName() << endl;

  // Define input/output containers:
  OutputFile += ":outputAnalysis";

  AliAnalysisDataContainer *cinput = mgr->GetCommonInputContainer();
  AliAnalysisDataContainer *coutput = NULL;
  coutput =
      mgr->CreateContainer(task->GetName(), TList::Class(),
                           AliAnalysisManager::kOutputContainer, OutputFile);
  mgr->ConnectInput(task, 0, cinput);
  mgr->ConnectOutput(task, 1, coutput);
}
