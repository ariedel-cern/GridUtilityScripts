/**
 * File              : Bootstrap.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 27.10.2021
 * Last Modified Date: 15.02.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"
#include <fstream>
#include <nlohmann/json.hpp>
#include <vector>

Int_t Bootstrap(const char *FileSubSamplesName) {

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

  // create vector of names all tasks
  std::vector<std::string> Tasks;
  TFile *DummyFile = new TFile(SubSampleFileNames.at(0).at(0).c_str(), "READ");
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(DummyFile->Get(
      Jconfig["task"]["OutputTDirectory"].get<std::string>().c_str()));

  TList *TaskList = tdirFile->GetListOfKeys();
  for (auto key : *TaskList) {
    Tasks.push_back(std::string(key->GetName()));
  }

  // create a vector of all names of observabels
  std::vector<std::string> SCs;
  AliAnalysisTaskAR *Task = new AliAnalysisTaskAR("Dummy");

  Task->GetPointers(dynamic_cast<TList *>(
      tdirFile->Get(tdirFile->GetListOfKeys()->First()->GetName())));

  TList *SCList =
      dynamic_cast<TList *>(Task->GetFinalResultSymmetricCumulantsList());

  for (auto key : *SCList) {
    SCs.push_back(std::string(key->GetName()));
  }

  // close dummy file and start boostrapping
  DummyFile->Close();

  for (auto Task : Tasks) {
    for (auto SC : SCs) {
      std::cout << SC << " in " << Task << std::endl;
    }
  }

  // // book one TProfile for each task
  // // the first bin holds the overall average, the other bins the averages of
  // the
  // // subsamples
  // TList *profileList = new TList();
  // for (auto KeyTask : *(tdirFile->GetListOfKeys())) {
  //   TList *list = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));
  //   profileList->Add(new TProfile(
  //       Form("Bootstrap_%s_%s", KeyTask->GetName(), observable), observable,
  //       SubSampleFileNames.size() + 1, 0, SubSampleFileNames.size() + 1));
  // }
  //
  // // start looping over all files/task and compute the averages
  // Int_t index = 0;
  // for (std::size_t i = 0; i < SubSampleFileNames.size(); i++) {
  //
  //   for (std::size_t j = 0; j < SubSampleFileNames.at(i).size(); j++) {
  //
  //     dataFile = new TFile(SubSampleFileNames.at(i).at(j).c_str(), "READ");
  //     TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(
  //         dataFile->Get(std::getenv("OUTPUT_TDIRECTORY_FILE")));
  //
  //     index = 0;
  //     for (auto KeyTask : *(tdirFile->GetListOfKeys())) {
  //       TList *list = dynamic_cast<TList
  //       *>(tdirFile->Get(KeyTask->GetName())); TH1 *hist =
  //           dynamic_cast<TH1 *>(IterateList(list, std::string(observable)));
  //       dynamic_cast<TProfile *>(profileList->At(index))
  //           ->Fill(0.5, hist->GetBinContent(1));
  //       dynamic_cast<TProfile *>(profileList->At(index))
  //           ->Fill(i + 1.5, hist->GetBinContent(1));
  //
  //       index++;
  //
  //       // keep here till we fix analysis task
  //       // if (i == 0 && j == 0) {
  //       //   Lcen = dynamic_cast<TH1 *>(
  //       //              IterateList(list, std::string("EventCutValues")))
  //       //              ->GetBinContent(11);
  //       //   Ucen = dynamic_cast<TH1 *>(
  //       //              IterateList(list, std::string("EventCutValues")))
  //       //              ->GetBinContent(12);
  //       //   std::cout << Lcen << " - " << Ucen << std::endl;
  //       //   centrality.push_back((Ucen - Lcen) / 50.);
  //       // }
  //     }
  //     dataFile->Close();
  //   }
  // }
  //
  // Double_t var = 0;
  // TGraphErrors *g = new TGraphErrors();
  // g->SetName(observable);
  // g->SetTitle(observable);
  // g->GetXaxis()->SetTitle("centrality percentile");
  //
  // // keep here till we fix analysis task
  // centrality = {2.5, 7.5, 15, 25, 35, 45, 55, 65, 75};
  // index = 0;
  // for (auto *p : *profileList) {
  //
  //   TH1 *t = dynamic_cast<TH1 *>(p);
  //
  //   var = 0;
  //   for (int i = 2; i < t->GetNbinsX(); i++) {
  //     var += std::pow(t->GetBinContent(i) - t->GetBinContent(1), 2);
  //   }
  //   var = std::sqrt(var / ((t->GetNbinsX() - 1) * (t->GetNbinsX() - 2)));
  //
  //   g->SetPoint(index, centrality.at(index), t->GetBinContent(1));
  //   g->SetPointError(index, 0, var);
  //
  //   index++;
  // }
  //
  // TFile *out = new TFile(std::getenv("LOCAL_OUTPUT_BOOTSTRAP_FILE"),
  // "UPDATE");
  // // profileList->Write();
  // g->Write();
  // out->Close();

  return 0;
}
