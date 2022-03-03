/**
 * File              : ComputeCentralityProbabilities.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 10.09.2021
 * Last Modified Date: 03.03.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"
#include <boost/algorithm/string.hpp>
#include <nlohmann/json.hpp>

Int_t ComputeCentralityProbabilities(const char *configFileName,
                                     const char *dataFileName) {

  // load config file
  std::fstream ConfigFile(configFileName);
  nlohmann::json Jconfig = nlohmann::json::parse(ConfigFile);

  // open file holding data
  TFile *dataFile = new TFile(dataFileName, "READ");

  // open output directory
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(dataFile->Get(
      Jconfig["task"]["OutputTDirectory"].get<std::string>().c_str()));

  // open new file holding probabilities
  std::string probabilitiesFileName(dataFileName);
  boost::replace_all(probabilitiesFileName, "Merged",
                     "CentralityProbabilities");
  TFile *probabilitiesFile =
      new TFile(probabilitiesFileName.c_str(), "RECREATE");

  // initalize objects
  TList *TaskList;
  TList *Hists = new TList();
  TH1D *cenHist, *cenProbHist;

  // loop over all tasks
  for (auto KeyTask : *(tdirFile->GetListOfKeys())) {
    // get the output list of a task
    TaskList = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));

    cenHist = dynamic_cast<TH1D *>(IterateList(
        TaskList, std::string("[kRECO]fEventControlHistograms[kCEN][kAFTER]")));

    // compute centrality probabilities
    cenProbHist =
        dynamic_cast<TH1D *>(cenHist->Clone("CentralityProbabilities"));
    cenProbHist->SetTitle("centrality probabilities");
    for (Int_t i = 1; i <= cenProbHist->GetNbinsX(); i++) {
      if (cenHist->GetBinContent(i) < 1.) {
        cenProbHist->SetBinContent(i, 0.);
      } else {
        cenProbHist->SetBinContent(i, 1. / cenHist->GetBinContent(i));
      }
    }

    cenProbHist->Scale(1. / cenProbHist->GetMaximum(), "nosw2");
    // write weight histograms to file
    Hists->Add(cenProbHist);

    Hists->Write(TaskList->GetName(), TObject::kSingleKey);
    Hists->Clear();
  }

  probabilitiesFile->Close();
  dataFile->Close();

  return 0;
}
