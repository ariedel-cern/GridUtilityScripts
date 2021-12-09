/**
 * File              : ComputeKinematicWeights.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 01.09.2021
 * Last Modified Date: 27.10.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"
#include <boost/algorithm/string.hpp>
#include <boost/range/iterator_range_core.hpp>

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
  TList *TaskList;
  TList *Hists = new TList();
  TH1D *phiHist, *phiWeightHist, *ptHistReco, *ptHistSim, *ptWeightHist,
      *etaHistReco, *etaHistSim, *etaWeightHist;

  // loop over all tasks
  for (auto KeyTask : *(tdirFile->GetListOfKeys())) {

    // get the output list of a task
    TaskList = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));

    // get distributions after cut
    phiHist = dynamic_cast<TH1D *>(IterateList(
        TaskList, std::string("[kRECO]fTrackControlHistograms[kPHI][kAFTER]")));
    ptHistReco = dynamic_cast<TH1D *>(IterateList(
        TaskList, std::string("[kRECO]fTrackControlHistograms[kPT][kAFTER]")));
    ptHistSim = dynamic_cast<TH1D *>(IterateList(
        TaskList, std::string("[kSIM]fTrackControlHistograms[kPT][kAFTER]")));
    etaHistReco = dynamic_cast<TH1D *>(IterateList(
        TaskList, std::string("[kRECO]fTrackControlHistograms[kETA][kAFTER]")));
    etaHistSim = dynamic_cast<TH1D *>(IterateList(
        TaskList, std::string("[kSIM]fTrackControlHistograms[kETA][kAFTER]")));

    // compute phi weights
    phiWeightHist = dynamic_cast<TH1D *>(phiHist->Clone("PhiWeights"));
    phiWeightHist->SetTitle("#varphi weights");
    Double_t scale = phiHist->GetEntries() / phiHist->GetNbinsX();
    for (Int_t i = 1; i <= phiHist->GetNbinsX(); i++) {
      phiWeightHist->SetBinContent(i, scale * (1. / phiHist->GetBinContent(i)));
    }

    // compute pt weights
    ptWeightHist = dynamic_cast<TH1D *>(ptHistSim->Clone("PtWeights"));
    ptWeightHist->SetTitle("p_{T} weights");
    ptWeightHist->Divide(ptHistReco);

    // scale with the inverse ratio of the average bin content
    scale = (ptHistReco->GetEntries() / ptHistReco->GetNbinsX()) /
            (ptHistSim->GetEntries() / ptHistSim->GetNbinsX());
    for (Int_t i = 1; i <= ptWeightHist->GetNbinsX(); i++) {
      ptWeightHist->SetBinContent(i, scale * ptWeightHist->GetBinContent(i));
    }

    // compute eta weights
    etaWeightHist = dynamic_cast<TH1D *>(etaHistSim->Clone("EtaWeights"));
    etaWeightHist->Divide(etaHistReco);
    etaWeightHist->SetTitle("#eta weights");

    // scale with the inverse ratio of the average bin content
    scale = (etaHistReco->GetEntries() / etaHistReco->GetNbinsX()) /
            (etaHistSim->GetEntries() / etaHistSim->GetNbinsX());
    for (Int_t i = 1; i <= etaWeightHist->GetNbinsX(); i++) {
      etaWeightHist->SetBinContent(i, scale * etaWeightHist->GetBinContent(i));
    }

    // write weight histograms to file
    Hists->Add(phiWeightHist);
    Hists->Add(ptWeightHist);
    Hists->Add(etaWeightHist);

    Hists->Write(TaskList->GetName(), TObject::kSingleKey);
    Hists->Clear();
  }

  weightFile->Close();
  dataFile->Close();

  return 0;
}
