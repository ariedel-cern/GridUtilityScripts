/**
 * File              : SystematicChecks.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 27.10.2021
 * Last Modified Date: 21.03.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"
#include <boost/algorithm/string.hpp>
#include <boost/algorithm/string/predicate.hpp>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <nlohmann/json.hpp>
#include <string>
#include <utility>
#include <vector>

Int_t SystematicChecks(const char *FileNameMean, const char *ListOfFiles) {

  // load config file
  std::fstream ConfigFile("config.json");
  nlohmann::json Jconfig = nlohmann::json::parse(ConfigFile);

  std::vector<std::string> skipSysCheck =
      Jconfig["task"]["SkipSysCheck"].get<std::vector<std::string>>();

  // open all files
  std::vector<TFile *> Files;
  std::fstream FileList(ListOfFiles);
  std::string Line;
  while (std::getline(FileList, Line)) {
    Files.push_back(TFile::Open(Line.c_str(), "READ"));
  }
  TFile *Mean = new TFile(FileNameMean, "READ");

  // get list of all tasks
  std::vector<std::string> defaultTasks;
  std::vector<std::string> tmp;
  std::vector<std::vector<std::string>> syscheckTasks;

  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(Mean->Get(
      Jconfig["task"]["OutputTDirectory"].get<std::string>().c_str()));
  std::vector<Double_t> CentralityBinEdges =
      Jconfig["task"]["CentralityBinEdges"].get<std::vector<Double_t>>();
  Double_t numberOfChecks =
      tdirFile->GetListOfKeys()->GetEntries() / (CentralityBinEdges.size() - 1);

  for (std::size_t i = 0; i < CentralityBinEdges.size() - 1; i++) {
    defaultTasks.push_back(std::string(
        tdirFile->GetListOfKeys()->At(i * numberOfChecks)->GetName()));
    tmp.clear();
    for (int j = i * numberOfChecks + 1; j < (i + 1) * numberOfChecks; j++) {
      tmp.push_back(std::string(tdirFile->GetListOfKeys()->At(j)->GetName()));
    }
    syscheckTasks.push_back(tmp);
  }

  // get list of all observables
  std::vector<std::string> Observables;
  TList *FinalResultsList = dynamic_cast<TList *>(
      dynamic_cast<TList *>(
          tdirFile->Get(tdirFile->GetListOfKeys()->First()->GetName()))
          ->FindObject("FinalResults"));

  for (auto cor : *dynamic_cast<TList *>(
           FinalResultsList->FindObject("FinalResultCorrelator"))) {
    for (auto dep : *dynamic_cast<TList *>(cor)) {
      Observables.push_back(std::string(dep->GetName()));
    }
  }
  for (auto sc : *dynamic_cast<TList *>(
           FinalResultsList->FindObject("FinalResultSymmetricCumulant"))) {
    for (auto dep : *dynamic_cast<TList *>(sc)) {
      Observables.push_back(std::string(dep->GetName()));
    }
  }

  TFile *Output = new TFile("Bootstrap.root", "RECREATE");
  TGraphErrors *gstat = nullptr;
  TGraphErrors *gsys = nullptr;
  TH1 *hist, *tmpHist;
  std::vector<TH1 *> hists;
  std::vector<Double_t> x = {};
  std::vector<Double_t> ex = {};
  std::vector<Double_t> y = {};
  std::vector<Double_t> ey = {};
  Double_t sigma = 0.;

  for (std::size_t i = 0; i < defaultTasks.size(); i++) {
    for (auto Observable : Observables) {
      std::cout << "Working on " << Observable << " in task "
                << defaultTasks.at(i) << std::endl;

      // compute statistical error

      x.clear();
      ex.clear();
      y.clear();
      ey.clear();
      hists.clear();

      // load histogram holding all sample mean
      hist = dynamic_cast<TH1 *>(
          GetObjectFromOutputFile(Mean, defaultTasks.at(i), Observable));

      // load histograms holding subsample means
      for (auto file : Files) {
        hists.push_back(dynamic_cast<TH1 *>(
            GetObjectFromOutputFile(file, defaultTasks.at(i), Observable)));
      }

      // loop over all bins
      for (Int_t bin = 1; bin <= hist->GetNbinsX(); bin++) {

        x.push_back(hist->GetBinCenter(bin));
        ex.push_back(hist->GetBinWidth(bin) / 2.);
        if (!std::isnan(hist->GetBinContent(bin))) {
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

      gstat =
          new TGraphErrors(x.size(), x.data(), y.data(), ex.data(), ey.data());
      gstat->Write((std::string("STAT_") + defaultTasks.at(i) +
                    std::string("_") + Observable)
                       .c_str());
      delete gstat;

      // compute systematical error

      x.clear();
      ex.clear();
      y.clear();
      ey.clear();
      hists.clear();

      // mean already loaded
      // load histograms holding systemaical variations
      for (std::size_t j = 0; j < syscheckTasks.at(i).size(); j++) {

        Bool_t flag = kTRUE;

        for (auto skip : skipSysCheck) {
          if (boost::contains(syscheckTasks.at(i).at(j), skip)) {
            flag = kFALSE;
            std::cout << "Skipping " << syscheckTasks.at(i).at(j) << std::endl;
          }
        }
        if (flag) {
          hists.push_back(dynamic_cast<TH1 *>(GetObjectFromOutputFile(
              Mean, syscheckTasks.at(i).at(j), Observable)));
        }
      }

      // loop over all bins
      for (Int_t bin = 1; bin <= hist->GetNbinsX(); bin++) {

        x.push_back(hist->GetBinCenter(bin));
        ex.push_back(hist->GetBinWidth(bin) / 2.);
        if (!std::isnan(hist->GetBinContent(bin))) {
          y.push_back(hist->GetBinContent(bin));
          sigma = 0.;

          for (auto h : hists) {
            sigma += (hist->GetBinContent(bin) - h->GetBinContent(bin)) *
                     ((hist->GetBinContent(bin) - h->GetBinContent(bin)));
          }
          sigma = TMath::Sqrt(sigma);

          ey.push_back(sigma);

        } else {
          std::cout << "NaN encountered. Keep going..." << std::endl;
          y.push_back(0.);
          ey.push_back(0.);
        }
      }

      gsys =
          new TGraphErrors(x.size(), x.data(), y.data(), ex.data(), ey.data());
      gsys->Write((std::string("SYS_") + defaultTasks.at(i) + std::string("_") +
                   Observable)
                      .c_str());
      delete gsys;
    }
  }
  Output->Close();

  return 0;
}
