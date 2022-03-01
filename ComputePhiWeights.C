/**
 * File              : ComputePhiWeights.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 01.09.2021
 * Last Modified Date: 01.03.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"
#include <boost/algorithm/string.hpp>
#include <fstream>
#include <nlohmann/json.hpp>

Int_t ComputePhiWeights(const char *ConfigFileName,
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
  boost::replace_all(weightFileName, "Merged", "PhiWeights");
  TFile *weightFile = new TFile(weightFileName.c_str(), "RECREATE");

  // initalize objects
  TList *TaskList;
  TList *Hists = new TList();
  TH1D *phiHist, *phiWeightHist;

  // loop over all tasks
  for (auto KeyTask : *(tdirFile->GetListOfKeys())) {
    // get the output list of a task
    TaskList = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));

    phiHist = dynamic_cast<TH1D *>(IterateList(
        TaskList, std::string("[kRECO]fTrackControlHistograms[kPHI][kAFTER]")));

    // compute phi weights
    phiWeightHist = dynamic_cast<TH1D *>(phiHist->Clone("PhiWeights"));
    phiWeightHist->SetTitle("#varphi weights");
    Double_t scale = phiHist->GetEntries() / phiHist->GetNbinsX();
    for (Int_t i = 1; i <= phiHist->GetNbinsX(); i++) {
      if (phiHist->GetBinContent(i) < 0.5) {
        phiWeightHist->SetBinContent(i, 0);
      } else {
        phiWeightHist->SetBinContent(i,
                                     scale * (1. / phiHist->GetBinContent(i)));
      }
    }

    // write weight histograms to file
    Hists->Add(phiWeightHist);

    Hists->Write(TaskList->GetName(), TObject::kSingleKey);
    Hists->Clear();
  }

  weightFile->Close();
  dataFile->Close();

  return 0;
}
