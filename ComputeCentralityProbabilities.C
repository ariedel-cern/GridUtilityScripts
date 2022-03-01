/**
 * File              : ComputeCentralityProbabilities.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 10.09.2021
 * Last Modified Date: 01.03.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include <boost/algorithm/string.hpp>
#include <nlohmann/json.hpp>

Int_t ComputeCentralityProbabilities(const char *configFileName,
                                     const char *dataFileName) {

  // load config file
  std::fstream ConfigFile(ConfigFileName);
  nlohmann::json Jconfig = nlohmann::json::parse(ConfigFile);

  // open file holding data
  TFile *dataFile = new TFile(dataFileName, "READ");

  // open output directory
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(
      dataFile->Get(std::getenv("OUTPUT_TDIRECTORY_FILE")));

  // open new file holding probabilitys
  std::string probabilitiesFileName(dataFileName);
  boost::replace_all(probabilitiesFileName, "Merged",
                     "CentralityProbabilities");
  TFile *probabilitiesFile =
      new TFile(probabilitiesFileName.c_str(), "RECREATE");

  // initalize objects
  TList *TaskList, *ControlHistogramsList, *EventControlHistogramsList;
  TH1D *cenHist, *cenProbHist;
  Double_t norm;

  // loop over all tasks
  // there should be only one
  for (auto KeyTask : *(tdirFile->GetListOfKeys())) {

    // get the output list of a task
    TaskList = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));
    // get top list of control histograms
    ControlHistogramsList =
        dynamic_cast<TList *>(TaskList->FindObject("ControlHistograms"));
    // get list of track control histograms
    EventControlHistogramsList = dynamic_cast<TList *>(
        ControlHistogramsList->FindObject("EventControlHistograms"));
    // get phi distribution after cut
    cenHist = dynamic_cast<TH1D *>(EventControlHistogramsList->FindObject(
        "[kRECO]fEventControlHistograms[kCEN][kAFTER]"));

    cenProbHist = dynamic_cast<TH1D *>(cenHist->Clone("CenProb"));
    cenProbHist->SetTitle("Centrality acceptance probability");

    // invert centrality distribution bin by bin
    for (int bin = 1; bin <= cenHist->GetNbinsX(); bin++) {
      if (cenHist->GetBinContent(bin) == 0) {
        std::cout << "Bin " << bin
                  << " is empty. There has to be something wrong..."
                  << std::endl;
        continue;
      }
      cenProbHist->SetBinContent(bin, 1. / cenHist->GetBinContent(bin));
    }

    // normalize distribution to the largest value to interpret them as
    // probabilities
    norm = cenProbHist->GetMaximum();
    for (int bin = 1; bin <= cenProbHist->GetNbinsX(); bin++) {
      cenProbHist->SetBinContent(bin, cenProbHist->GetBinContent(bin) / norm);
    }
    cenProbHist->Write();
  }

  probabilitiesFile->Close();
  dataFile->Close();

  return 0;
}
