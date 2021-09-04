/**
 * File              : AddTask.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 07.05.2021
 * Last Modified Date: 05.09.2021
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
    return;
  }

  // Check the analysis type using the event handlers connected to the analysis
  // manager. The availability of MC handler can also be checked here.
  if (!mgr->GetInputEventHandler()) {
    Error("AddTask.C macro", "This task requires an input event handler");
    return;
  }

  // Configure your analysis task here:
  AliAnalysisTaskAR *task = new AliAnalysisTaskAR(
      Form("%s_%.1f-%.1f", std::getenv("TaskBaseName"), centerMin, centerMax),
      kFALSE);

  // set limits for control histograms and cuts
  // transverse momentum
  Double_t pt_min = 0.2;
  Double_t pt_max = 5.0;
  Int_t pt_bins = (pt_max - pt_min) * 100;
  // azimuthal angle
  Double_t phi_min = 0.0;
  Double_t phi_max = TMath::TwoPi();
  Int_t phi_bins = 360.;
  // pseudo rapidity
  Double_t eta_min = -0.8;
  Double_t eta_max = 0.8;
  Int_t eta_bins = (eta_max - eta_min) * 100;
  // absolute value of charge
  Double_t charge_min = 0.9;
  Double_t charge_max = 1.1;
  // number of clusters in the TPC
  Double_t tpcncls_min = 60.;
  Double_t tpcncls_max = 159.;
  Int_t tpcncls_bins = tpcncls_max - tpcncls_min;
  // number of clusters in the ITS
  Double_t itsncls_min = 0.;
  Double_t itsncls_max = 10.;
  Int_t itsncls_bins = itsncls_max - itsncls_min;
  // chi2/NDF of the track fit
  Double_t chi2perndf_min = 1.;
  Double_t chi2perndf_max = 4.5;
  Int_t chi2perndf_bins = (chi2perndf_max - chi2perndf_min) * 100;
  // distance of closest approach in Z direction
  Double_t dcaz_min = -3.;
  Double_t dcaz_max = 3.;
  Int_t dcaz_bins = (dcaz_max - dcaz_min) * 10;
  // distance of closest approach in XY plane
  Double_t dcaxy_min = -3.;
  Double_t dcaxy_max = 3.;
  Int_t dcaxy_bins = (dcaxy_max - dcaxy_min) * 10;
  // multiplicity, estimated by number of tracks per event
  Double_t mul_min = 0.;
  Double_t mul_max = 15000.;
  Int_t mul_bins = (mul_max - mul_min) / 10;
  // multiplicity, estimated by number of tracks per event that survive track
  // cuts this is also the number of tracks we fill into qvector
  Double_t mulq_min = 2.;
  Double_t mulq_max = 3000.;
  Int_t mulq_bins = (mulq_max - mulq_min) / 10;
  // multiplicity, estimated by sum of all paritcle weights
  Double_t mulw_min = 2.;
  Double_t mulw_max = 3000.;
  Int_t mulw_bins = (mulw_max - mulw_min) / 10;
  // reference multiplicity from AODHeadter
  Double_t mulref_min = 2.;
  Double_t mulref_max = 3000.;
  Int_t mulref_bins = (mulref_max - mulref_min) / 10;
  // multiplicity, estimated by number of contributor to primary vertex
  Double_t ncontrib_min = 0.;
  Double_t ncontrib_max = 3000.;
  Int_t ncontrib_bins = (ncontrib_max - ncontrib_min) / 10;
  // x coordinate of primary vertex
  Double_t x_min = -10.;
  Double_t x_max = 10.;
  Int_t x_bins = (x_max - x_min) * 10.;
  // y coordinate of primary vertey
  Double_t y_min = -10.;
  Double_t y_max = 10.;
  Int_t y_bins = (y_max - y_min) * 10.;
  // z coordinate of primary vertez
  Double_t z_min = -10.;
  Double_t z_max = 10.;
  Int_t z_bins = (z_max - z_min) * 10.;
  // distance of primary vertex from the origin
  Double_t pos_min = 1e-6;
  Double_t pos_max = 18.;
  Int_t pos_bins = (pos_max - pos_min) * 100.;

  // most setters expect enumerations as arguments
  // those enumerations are defined in AliAnalysisTaskAR.h

  // setters for track control histograms
  task->SetTrackControlHistogramBinning(kPT, pt_bins, pt_min, pt_max);
  task->SetTrackControlHistogramBinning(kPHI, phi_bins, phi_min, phi_max);
  task->SetTrackControlHistogramBinning(kETA, eta_bins, eta_min, eta_max);
  task->SetTrackControlHistogramBinning(kCHARGE, 5, -2.5, 2.5);
  task->SetTrackControlHistogramBinning(kTPCNCLS, tpcncls_bins, tpcncls_min,
                                        tpcncls_max);
  task->SetTrackControlHistogramBinning(kITSNCLS, itsncls_bins, itsncls_min,
                                        itsncls_max);
  task->SetTrackControlHistogramBinning(kCHI2PERNDF, chi2perndf_bins,
                                        chi2perndf_min, chi2perndf_max);
  task->SetTrackControlHistogramBinning(kDCAZ, dcaz_bins, dcaz_min, dcaz_max);
  task->SetTrackControlHistogramBinning(kDCAXY, dcaxy_bins, dcaxy_min,
                                        dcaz_max);
  // setters for event control histograms
  task->SetEventControlHistogramBinning(kMUL, mul_bins, mul_min, mul_max);
  task->SetEventControlHistogramBinning(kMULQ, mulq_bins, mulq_min, mulq_max);
  task->SetEventControlHistogramBinning(kMULW, mulw_bins, mulw_min, mulw_max);
  task->SetEventControlHistogramBinning(kMULREF, mulref_bins, mulref_min,
                                        mulref_max);
  task->SetEventControlHistogramBinning(kNCONTRIB, ncontrib_bins, ncontrib_min,
                                        ncontrib_max);
  task->SetEventControlHistogramBinning(
      kCEN, (centerMax - centerMin) * 1., centerMin,
      centerMax); // centrality is set to 99 for MC
  task->SetEventControlHistogramBinning(kX, x_bins, x_min, x_max);
  task->SetEventControlHistogramBinning(kY, y_bins, y_min, y_max);
  task->SetEventControlHistogramBinning(kZ, z_bins, z_min, z_max);
  task->SetEventControlHistogramBinning(kVPOS, pos_bins, pos_min, pos_max);

  // setter for correlation cuts on centrality
  task->SetFillQAHistograms(kTRUE);
  for (int i = 0; i < LAST_ECENESTIMATORS; i++) {
    for (int j = i + 1; j < LAST_ECENESTIMATORS; j++) {
      task->SetCenCorQAHistogramBinning(
          i, static_cast<Int_t>(centerMax - centerMin) * 1, centerMin,
          centerMax, j, static_cast<Int_t>(centerMax - centerMin) * 1,
          centerMin, centerMax);
    }
  }
  // setter for correlation cuts on multiplicity
  Double_t MulCor[kMulEstimators][3] = {
      {static_cast<Double_t>(mul_bins), mul_min, mul_max},
      {static_cast<Double_t>(mulq_bins), mulq_min, mulq_max},
      {static_cast<Double_t>(mulw_bins), mulw_min, mulw_max},
      {static_cast<Double_t>(mulref_bins), mulref_min, mulref_max},
      {static_cast<Double_t>(ncontrib_bins), ncontrib_min, ncontrib_max},
  };
  for (int i = 0; i < kMulEstimators; i++) {
    for (int j = i + 1; j < kMulEstimators; j++) {
      task->SetMulCorQAHistogramBinning(
          i, static_cast<Int_t>(MulCor[i][0]), MulCor[i][1], MulCor[i][2], j,
          static_cast<Int_t>(MulCor[j][0]), MulCor[j][1], MulCor[j][2]);
    }
  }

  // setters for track cuts
  task->SetTrackCuts(kPT, pt_min, pt_max);
  task->SetTrackCuts(kPHI, phi_min, phi_max);
  task->SetTrackCuts(kETA, eta_min, eta_max);
  task->SetTrackCuts(kCHARGE, charge_min, charge_max);
  task->SetTrackCuts(kTPCNCLS, tpcncls_min, tpcncls_max);
  task->SetTrackCuts(kITSNCLS, itsncls_min, itsncls_max);
  task->SetTrackCuts(kCHI2PERNDF, chi2perndf_min, chi2perndf_max);
  task->SetTrackCuts(kDCAZ, dcaz_min, dcaz_max);
  task->SetTrackCuts(kDCAXY, dcaxy_min, dcaxy_max);
  // setters for event cuts
  task->SetEventCuts(kMUL, mul_min, mul_max);
  task->SetEventCuts(kMULQ, mulq_min, mulq_max);
  task->SetEventCuts(kMULW, mulw_min, mulw_max);
  task->SetEventCuts(
      kMULREF, mulref_min,
      mulref_max); // reference multiplicity is set to -999 for MC
  task->SetEventCuts(kNCONTRIB, ncontrib_min, ncontrib_max);
  task->SetEventCuts(kCEN, centerMin,
                     centerMax); // centrality is set to 99 for MC
  task->SetEventCuts(kX, x_min, x_max);
  task->SetEventCuts(kY, y_min, y_max);
  task->SetEventCuts(kZ, z_min, z_max);
  task->SetEventCuts(kVPOS, pos_min, pos_max);
  // correlation cuts
  // open these up for running over MC data
  task->SetCenCorCut(1.2, 10);  // slope, offset
  task->SetMulCorCut(1.4, 300); // slope, offset
  // other cuts
  task->SetFilterbit(128); // typical 1,128,256,768
  task->SetPrimaryOnlyCut(kTRUE);
  task->SetCentralityEstimator(kV0M); // choices kV0M,kCL0,kCL1,kSPDTRACKLETS

  // setters for correlators we want to compute
  std::vector<std::vector<Int_t>> correlators = {{-2, 2}};
  task->SetCorrelators(correlators);

  // add task to the analysis manager
  mgr->AddTask(task);
  cout << "Added to manager: " << task->GetName() << endl;

  // Define input/output containers:
  OutputFile += TString(":") + TString(std::getenv("OutputTDirectoryFile"));

  AliAnalysisDataContainer *cinput = mgr->GetCommonInputContainer();
  AliAnalysisDataContainer *coutput = nullptr;
  coutput =
      mgr->CreateContainer(task->GetName(), TList::Class(),
                           AliAnalysisManager::kOutputContainer, OutputFile);
  mgr->ConnectInput(task, 0, cinput);
  mgr->ConnectOutput(task, 1, coutput);
}
