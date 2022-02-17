/**
 * File              : Bootstrap.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 27.10.2021
 * Last Modified Date: 17.02.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"
#include <boost/algorithm/string.hpp>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <nlohmann/json.hpp>
#include <string>
#include <utility>
#include <vector>

Int_t Bootstrap(const char *FileNameMean, const char *ListOfFiles) {

  // load config file
  std::fstream ConfigFile("config.json");
  nlohmann::json Jconfig = nlohmann::json::parse(ConfigFile);

  // open all files
  std::vector<TFile *> Files;
  std::fstream FileList(ListOfFiles);
  std::string Line;
  while (std::getline(FileList, Line)) {
    Files.push_back(TFile::Open(Line.c_str(), "READ"));
  }
  TFile *Mean = new TFile(FileNameMean, "READ");

  // get list of all tasks
  std::vector<std::string> Tasks;
  std::vector<Double_t> CentralityBinEdges =
      Jconfig["task"]["CentralityBinEdges"].get<std::vector<Double_t>>();
  for (std::size_t i = 0; i < CentralityBinEdges.size() - 1; i++) {
    Float_t lowCentralityBinEdge = CentralityBinEdges.at(i);
    Float_t highCentralityBinEdge = CentralityBinEdges.at(i + 1);
    Tasks.push_back(std::string(Form(
        "%s_%.1f-%.1f", Jconfig["task"]["BaseName"].get<std::string>().c_str(),
        lowCentralityBinEdge, highCentralityBinEdge)));
  }

  // get list of all observables
  std::vector<std::string> Observables;
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(Mean->Get(
      Jconfig["task"]["OutputTDirectory"].get<std::string>().c_str()));
  TList *SCList = dynamic_cast<TList *>(
      dynamic_cast<TList *>(
          dynamic_cast<TList *>(
              tdirFile->Get(tdirFile->GetListOfKeys()->First()->GetName()))
              ->FindObject("FinalResults"))
          ->FindObject("FinalResultSymmetricCumulant"));

  for (auto sc : *SCList) {
    for (auto dep : *dynamic_cast<TList *>(sc)) {
      Observables.push_back(std::string(dep->GetName()));
    }
  }

  TFile *Output = new TFile("Bootstrap.root", "RECREATE");
  TGraphErrors *ge = nullptr;
  TH1 *hist;
  std::vector<TH1 *> hists;
  std::vector<Double_t> x = {};
  std::vector<Double_t> y = {};
  std::vector<Double_t> ey = {};
  Double_t sigma = 0.;

  for (auto Task : Tasks) {
    for (auto Observable : Observables) {
      std::cout << "Working on " << Observable << " in task " << Task
                << std::endl;

      x.clear();
      y.clear();
      ey.clear();
      hists.clear();

      // load histogram holding all sample mean
      hist =
          dynamic_cast<TH1 *>(GetObjectFromOutputFile(Mean, Task, Observable));

      // load histograms holding subsample means
      for (auto file : Files) {
        hists.push_back(dynamic_cast<TH1 *>(
            GetObjectFromOutputFile(file, Task, Observable)));
      }

      // loop over all bins
      for (Int_t bin = 1; bin <= hist->GetNbinsX(); bin++) {

        x.push_back(hist->GetBinCenter(bin));
        if (!std::isnan(hist->GetBinContent(bin)){
          y.push_back(hist->GetBinContent(bin));
          sigma = 0.;

          for (auto h : hists) {
            sigma += (hist->GetBinContent(bin) - h->GetBinContent(bin)) *
                     ((hist->GetBinContent(bin) - h->GetBinContent(bin)));
          }
          sigma = TMath::Sqrt(sigma / (Files.size() * (Files.size() - 1.)));

          ey.push_back(sigma);

        } else {
          std::cout << "NaN encountered. Keep going..." << std::endl;
          y.push_back(0.);
          ey.push_back(0.);
        }
      }

      // clear memory
      // for (auto h : hists) {
      //   delete h;
      // }

      ge = new TGraphErrors(x.size(), x.data(), y.data(), 0, ey.data());
      ge->Write((Task + std::string("_") + Observable).c_str());
      delete ge;
    }
  }
  Output->Close();

  return 0;
}
