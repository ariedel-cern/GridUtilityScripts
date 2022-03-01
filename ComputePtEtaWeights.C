/**
 * File              : ComputePtEtaWeights.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 01.09.2021
 * Last Modified Date: 01.03.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"
#include <boost/algorithm/string.hpp>
#include <fstream>
#include <nlohmann/json.hpp>

Int_t ComputeKinematicWeights(const char *ConfigFileName,
                              const char *MergedFileName) {

  // load config file
  std::fstream ConfigFile(ConfigFileName);
  nlohmann::json Jconfig = nlohmann::json::parse(ConfigFile);

  // open file holding data
  TFile *dataFile = new TFile(MergedFileName, "READ");

  // open output directory
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(dataFile->Get(
      Jconfig["task"]["OutputTDirectory"].get<std::string>().c_str()));

  // open new file holding weights
  std::string weightFileName(MergedFileName);
  boost::replace_all(weightFileName, "Merged", "PtEtaWeights");
  TFile *weightFile = new TFile(weightFileName.c_str(), "RECREATE");

  // initalize objects
  TList *TaskList;
  TList *Hists = new TList();
  TH1D *ptHistReco, *ptHistSim, *ptWeightHist, *etaHistReco, *etaHistSim,
      *etaWeightHist;

  // loop over all tasks
  for (auto KeyTask : *(tdirFile->GetListOfKeys())) {
    // get the output list of a task
    TaskList = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));

    // get distributions after cut
    ptHistReco = dynamic_cast<TH1D *>(IterateList(
        TaskList, std::string("[kRECO]fTrackControlHistograms[kPT][kAFTER]")));
    ptHistSim = dynamic_cast<TH1D *>(IterateList(
        TaskList, std::string("[kSIM]fTrackControlHistograms[kPT][kAFTER]")));
    etaHistReco = dynamic_cast<TH1D *>(IterateList(
        TaskList, std::string("[kRECO]fTrackControlHistograms[kETA][kAFTER]")));
    etaHistSim = dynamic_cast<TH1D *>(IterateList(
        TaskList, std::string("[kSIM]fTrackControlHistograms[kETA][kAFTER]")));

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
    Hists->Add(ptWeightHist);
    Hists->Add(etaWeightHist);

    Hists->Write(TaskList->GetName(), TObject::kSingleKey);
    Hists->Clear();
  }

  weightFile->Close();
  dataFile->Close();

  return 0;
}
