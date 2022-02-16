/**
 * File              : Bootstrap.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 27.10.2021
 * Last Modified Date: 16.02.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"
#include <boost/algorithm/string.hpp>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <nlohmann/json.hpp>
#include <string>
#include <utility>
#include <vector>

Int_t Bootstrap(const char *FileSubSamplesName, const char *TaskInput) {

  // task to work on
  std::string Task(TaskInput);

  // fix memory leak?
  // TH1::AddDirectory(kFALSE);

  // load config file
  std::fstream ConfigFile("config.json");
  nlohmann::json Jconfig = nlohmann::json::parse(ConfigFile);

  // load file containig the subsamples
  std::fstream FileSubSamples(FileSubSamplesName);
  nlohmann::json JSubSamples = nlohmann::json::parse(FileSubSamples);

  // fill the path to the files into a vector of vector of strings
  std::vector<std::vector<std::string>> SubSampleFileNames;
  for (nlohmann::json::iterator it = JSubSamples.begin();
       it != JSubSamples.end(); ++it) {
    SubSampleFileNames.push_back(
        JSubSamples[it.key()].get<std::vector<std::string>>());
  }

  // get name of all observables
  TFile *DummyFile = new TFile(SubSampleFileNames.at(0).at(0).c_str(), "READ");
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(DummyFile->Get(
      Jconfig["task"]["OutputTDirectory"].get<std::string>().c_str()));

  std::vector<std::pair<std::string, std::vector<Double_t>>> SCs;
  AliAnalysisTaskAR *AliTask = new AliAnalysisTaskAR("Dummy");
  AliTask->GetPointers(dynamic_cast<TList *>(tdirFile->Get(Task.c_str())));
  TList *SCList =
      dynamic_cast<TList *>(AliTask->GetFinalResultSymmetricCumulantsList());
  TList *l;
  TH1 *h;
  std::vector<Double_t> BinCenter = {};
  for (auto *list : *SCList) {
    l = dynamic_cast<TList *>(list);
    for (auto hist : *l) {
      h = dynamic_cast<TH1 *>(hist);
      for (Int_t bin = 1; bin <= h->GetNbinsX(); bin++) {
        BinCenter.push_back(h->GetBinCenter(bin));
      }
      SCs.push_back(std::pair(h->GetName(), BinCenter));
      BinCenter.clear();
    }
  }
  // close dummy file and start boostrapping
  DummyFile->Close();

  TProfile *bootstrapProfile =
      new TProfile("bootstrap", "bootstrap", SubSampleFileNames.size() + 1, 0,
                   SubSampleFileNames.size() + 1);
  TGraphErrors *ge = nullptr;
  TFile *currentFile = nullptr;
  TDirectoryFile *currentTDirFile = nullptr;
  TList *currentList = nullptr;
  TH1 *currentHist = nullptr;
  Double_t sigma = 0;
  std::vector<Double_t> y = {};
  std::vector<Double_t> ey = {};

  // loop over all histograms of symmetric cumulants
  for (auto SC : SCs) {
    // loop over each bin
    y.clear();
    ey.clear();
    bootstrapProfile->Reset();
    for (Int_t i = 1; i <= SC.second.size(); i++) {
      std::cout << "Working in Task " << Task << " on " << SC.first
                << " in bin " << i << std::endl;
      // loop over all subsamples
      for (auto Files : SubSampleFileNames) {
        // loop over all files in the subsample
        for (auto File : Files) {
          currentFile = TFile::Open(File.c_str(), "READ");
          currentTDirFile = dynamic_cast<TDirectoryFile *>(currentFile->Get(
              Jconfig["task"]["OutputTDirectory"].get<std::string>().c_str()));
          currentList =
              dynamic_cast<TList *>(currentTDirFile->Get(Task.c_str()));

          currentHist = dynamic_cast<TH1 *>(IterateList(currentList, SC.first));
          bootstrapProfile->Fill(i - 0.5, currentHist->GetBinContent(i));
          bootstrapProfile->Fill(SubSampleFileNames.size() + 0.5,
                                 currentHist->GetBinContent(i));
          currentFile->Close();
          delete currentList;
        }
      }
      y.push_back(bootstrapProfile->GetBinContent(SubSampleFileNames.size()));
      ey.push_back(BootstrapSigma(bootstrapProfile));
    }
    ge = new TGraphErrors(SC.second.size(), SC.second.data(), y.data(), 0,
                          ey.data());
    TFile *out =
        new TFile((Task + std::string("_Bootstrap.root")).c_str(), "UPDATE");
    ge->Write((Task + SC.first).c_str());
    out->Close();
    delete ge;

    // std::cout << "GOT IT" << std::endl;
    // std::exit(4);
  }
  return 0;
}
