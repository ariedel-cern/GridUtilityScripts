/**
 * File              : CentralityDependence.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 20.02.2022
 * Last Modified Date: 21.03.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"
#include <TGraphErrors.h>
#include <boost/algorithm/string/predicate.hpp>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <nlohmann/json.hpp>
#include <string>
#include <utility>
#include <vector>

Int_t CentralityDependence(const char *FileName) {

  // load config file
  std::fstream ConfigFile("config.json");
  nlohmann::json Jconfig = nlohmann::json::parse(ConfigFile);

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
  TFile *Mean = new TFile("Bootstrap/Mean_ReTerminated.root", "READ");
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(Mean->Get(
      Jconfig["task"]["OutputTDirectory"].get<std::string>().c_str()));
  TList *FinalResultsList = dynamic_cast<TList *>(
      dynamic_cast<TList *>(
          tdirFile->Get(tdirFile->GetListOfKeys()->First()->GetName()))
          ->FindObject("FinalResults"));

  for (auto cor : *dynamic_cast<TList *>(
           FinalResultsList->FindObject("FinalResultCorrelator"))) {
    for (auto dep : *dynamic_cast<TList *>(cor)) {
      if (boost::contains(std::string(dep->GetName()),
                          std::string("kINTEGRATED"))) {
        Observables.push_back(std::string(dep->GetName()));
      }
    }
  }
  for (auto sc : *dynamic_cast<TList *>(
           FinalResultsList->FindObject("FinalResultSymmetricCumulant"))) {
    for (auto dep : *dynamic_cast<TList *>(sc)) {
      if (boost::contains(std::string(dep->GetName()),
                          std::string("kINTEGRATED"))) {
        Observables.push_back(std::string(dep->GetName()));
      }
    }
  }

  // setup for final loop
  TFile *bootstrap = new TFile(FileName, "READ");
  TFile *out = new TFile("CentralityDependence.root", "RECREATE");
  out->cd();
  TGraphErrors *gstat, *gsys, *hstat, *hsys;
  std::vector<Double_t> x, ex, y, estat, esys;
  Int_t i;

  // create a plot for each observable
  for (auto observable : Observables) {

    std::cout << "Working on observable " << observable << std::endl;

    x.clear();
    ex.clear();
    y.clear();
    estat.clear();
    esys.clear();

    i = 0;
    for (auto task : Tasks) {

      std::cout << "in task " << task << std::endl;

      hstat = dynamic_cast<TGraphErrors *>(bootstrap->Get(
          (std::string("STAT_") + task + std::string("_") + observable)
              .c_str()));
      hsys = dynamic_cast<TGraphErrors *>(bootstrap->Get(
          (std::string("SYS_") + task + std::string("_") + observable)
              .c_str()));

      x.push_back((CentralityBinEdges[i + 1] + CentralityBinEdges[i]) / 2.);
      ex.push_back((CentralityBinEdges[i + 1] - CentralityBinEdges[i]) / 2.);
      i++;
      y.push_back(hstat->GetPointY(0));
      estat.push_back(hstat->GetErrorY(0));
      esys.push_back(hsys->GetErrorY(0));
    }

    gstat =
        new TGraphErrors(x.size(), x.data(), y.data(), ex.data(), estat.data());
    gstat->Write((std::string("STAT_") + observable).c_str());
    delete gstat;

    gsys =
        new TGraphErrors(x.size(), x.data(), y.data(), ex.data(), esys.data());
    gsys->Write((std::string("SYS_") + observable).c_str());
    delete gsys;
  }

  bootstrap->Close();
  out->Close();

  return 0;
}
