/**
 * File              : ComputeKinematicWeights.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 01.09.2021
 * Last Modified Date: 14.10.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include <boost/algorithm/string.hpp>

Int_t ComputeKinematicWeights(const char *dataFileName) {

  cout << dataFileName << endl;
  // open file holding data
  TFile *dataFile = new TFile(dataFileName, "READ");

  // open output directory
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(
      dataFile->Get(std::getenv("OUTPUT_TDIRECTORY_FILE")));

  // open new file holding weights
  std::string weightFileName(dataFileName);
  boost::replace_all(weightFileName, "Merged", "KinematicWeights");
  TFile *weightFile = new TFile(weightFileName.c_str(), "RECREATE");

  // initalize objects
  TList *TaskList, *ControlHistogramsList, *TrackControlHistogramsList;
  TH1D *phiHist, *phiWeightHist;
  TH1D *ptHistReco, *ptHistSim, *ptWeightHist;
  TH1D *etaHistReco, *etaHistSim, *etaWeightHist;
  Int_t counter = 0;

  // loop over all tasks
  // there should be only one
  for (auto KeyTask : *(tdirFile->GetListOfKeys())) {

    if (counter > 1) {
      cout << "There is more than 1 task. Something smells fishy ..." << endl
           << "Breaking out" << endl;
      break;
    }

    // get the output list of a task
    TaskList = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));
    // get top list of control histograms
    ControlHistogramsList =
        dynamic_cast<TList *>(TaskList->FindObject("ControlHistograms"));
    // get list of track control histograms
    TrackControlHistogramsList = dynamic_cast<TList *>(
        ControlHistogramsList->FindObject("TrackControlHistograms"));
    // get phi distribution after cut
    phiHist = dynamic_cast<TH1D *>(TrackControlHistogramsList->FindObject(
        "[kRECO]fTrackControlHistograms[kPHI][kAFTER]"));

    // get pt distribution after cut
    ptHistReco = dynamic_cast<TH1D *>(TrackControlHistogramsList->FindObject(
        "[kRECO]fTrackControlHistograms[kPT][kAFTER]"));
    ptHistSim = dynamic_cast<TH1D *>(TrackControlHistogramsList->FindObject(
        "[kSIM]fTrackControlHistograms[kPT][kAFTER]"));

    // get eta distribution after cut
    etaHistReco = dynamic_cast<TH1D *>(TrackControlHistogramsList->FindObject(
        "[kRECO]fTrackControlHistograms[kETA][kAFTER]"));
    etaHistSim = dynamic_cast<TH1D *>(TrackControlHistogramsList->FindObject(
        "[kSIM]fTrackControlHistograms[kETA][kAFTER]"));

    counter++;
  }

  // compute phi weights
  phiWeightHist = dynamic_cast<TH1D *>(phiHist->Clone("PhiWeights"));
  phiWeightHist->SetTitle("#varphi weights");
  Double_t scale = phiHist->GetEntries() / phiHist->GetNbinsX();
  for (Int_t i = 1; i <= phiHist->GetNbinsX(); i++) {
    phiWeightHist->SetBinContent(i, scale * (1. / phiHist->GetBinContent(i)));
  }

  // compute pt weights
  if (ptHistSim) {
    ptWeightHist = dynamic_cast<TH1D *>(ptHistSim->Clone("PtWeights"));
    ptWeightHist->SetTitle("p_{T} weights");
    ptWeightHist->Divide(ptHistReco);

    // scale with the inverse ratio of the average bin content
    scale = (ptHistReco->GetEntries() / ptHistReco->GetNbinsX()) /
            (ptHistSim->GetEntries() / ptHistSim->GetNbinsX());
    for (Int_t i = 1; i <= ptWeightHist->GetNbinsX(); i++) {
      ptWeightHist->SetBinContent(i, scale * ptWeightHist->GetBinContent(i));
    }
  }

  // compute eta weights
  if (etaHistSim) {
    etaWeightHist = dynamic_cast<TH1D *>(etaHistSim->Clone("EtaWeights"));
    etaWeightHist->Divide(etaHistReco);
    etaWeightHist->SetTitle("#eta weights");

    // scale with the inverse ratio of the average bin content
    scale = (etaHistReco->GetEntries() / etaHistReco->GetNbinsX()) /
            (etaHistSim->GetEntries() / etaHistSim->GetNbinsX());
    for (Int_t i = 1; i <= etaWeightHist->GetNbinsX(); i++) {
      etaWeightHist->SetBinContent(i, scale * etaWeightHist->GetBinContent(i));
    }
  }

  // write weight histograms to file
  phiWeightHist->Write();
  ptWeightHist->Write();
  etaWeightHist->Write();

  weightFile->Close();
  dataFile->Close();

  return 0;
}
