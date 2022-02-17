/**
 * File              : GridHelperMacros.H
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 14.10.2021
 * Last Modified Date: 17.02.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include <boost/algorithm/string.hpp>
#include <iostream>
#include <nlohmann/json.hpp>

TObject *IterateList(TList *list, std::string searchString) {

  if (!list) {
    std::cout << "Passed nullptr to IterateList" << std::endl;
    return nullptr;
  }

  TObject *obj = nullptr;
  for (auto key : *list) {

    obj = key;

    if (boost::contains(std::string(key->GetName()), searchString)) {
      break;
    }

    if (obj->IsFolder()) {
      obj = IterateList(dynamic_cast<TList *>(obj), searchString);
    }

    if (boost::contains(std::string(obj->GetName()), searchString)) {
      break;
    }
  }
  return obj;
}

TObject *GetObjectFromOutputFile(TFile *file, std::string TopLevelListName,
                                 std::string ObjectName) {

  if (!file) {
    std::cout << "File pointer is NULL" << std::endl;
    return nullptr;
  }

  std::fstream ConfigFile("config.json");
  nlohmann::json Jconfig = nlohmann::json::parse(ConfigFile);

  // get list of all tasks
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(file->Get(
      Jconfig["task"]["OutputTDirectory"].get<std::string>().c_str()));
  TList *TopLevelList =
      dynamic_cast<TList *>(tdirFile->Get(TopLevelListName.c_str()));

  TObject *result = IterateList(TopLevelList, ObjectName)->Clone();

  delete TopLevelList;

  return result;
}

// TH1 *GetHistFromOutputFile(std::string observable, std::string FileName,
//                            std::string TaskName) {
//
//   std::fstream ConfigFile("config.json");
//   nlohmann::json Jconfig = nlohmann::json::parse(ConfigFile);
//
//   // open file
//   TFile *file = TFile::Open(FileName.c_str(), "READ");
//
//   // open output directory
//   TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(file->Get(
//       Jconfig["task"]["OutputTDirectory"].get<std::string>().c_str()));
//
//   TList *TaskList = dynamic_cast<TList *>(tdirFile->Get(TaskName.c_str()));
//
//   TH1 *result = dynamic_cast<TH1 *>(IterateList(TaskList, observable));
//
//   // close the file
//   file->Close();
//
//   return result;
// }

Double_t BootstrapSigma(TProfile *p) {
  // compute statistical uncertainty sigma from tprofile
  // the first n-1 bins contain the subsample means and the nth bin contains
  // the whole mean
  Double_t sigma = 0.0;
  Int_t N = p->GetNbinsX();

  for (Int_t i = 1; i < N; i++) {
    sigma += TMath::Power(2, p->GetBinContent(i) - p->GetBinContent(N));
  }

  return TMath::Sqrt(sigma / (N * (N - 1.)));
}

void *SetWeights(Int_t RunNumber, Float_t CenMin, Float_t CenMax,
                 AliAnalysisTaskAR *task, const char *id) {

  TFile *file = new TFile(Form("%s/weights/%i_KinematicWeights.root",
                               std::getenv("GRID_UTILITY_SCRIPTS"), RunNumber),
                          "READ");

  TList *list = dynamic_cast<TList *>(
      file->Get(Form("KinematicWeights_%.1f-%.1f%s", CenMin, CenMax, id)));

  if (!list) {
    std::cout << "List not found" << std::endl
              << Form("KinematicWeights_%.1f-%.1f%s", CenMin, CenMax, id)
              << std::endl;
  }

  task->SetWeightHistogram(kPT,
                           dynamic_cast<TH1D *>(list->FindObject("PtWeights")));
  task->SetWeightHistogram(
      kETA, dynamic_cast<TH1D *>(list->FindObject("EtaWeights")));
  task->SetWeightHistogram(
      kPHI, dynamic_cast<TH1D *>(list->FindObject("PhiWeights")));
  return nullptr;
}
