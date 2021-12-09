/**
 * File              : Bootstrap.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 27.10.2021
 * Last Modified Date: 03.11.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"

Int_t Bootstrap(const char *FileSubSamplesName, const char *observable) {

  // open file holding path to files, grouped into subsamples
  //   the subsamples are divided by a new line
  std::ifstream FileSubSamples(FileSubSamplesName);
  std::string FileName;

  // fill the path to the files into a vector of vector of strings
  std::vector<std::vector<std::string>> SubSampleFileNames;
  std::vector<std::string> FileNames;
  std::vector<Double_t> centrality;
  Double_t Lcen, Ucen;

  while (getline(FileSubSamples, FileName)) {

    if (FileName.empty()) {
      SubSampleFileNames.push_back(FileNames);
      FileNames.clear();
    } else {
      FileNames.push_back(FileName);
    }
  }
  // catch last subsample, there is no new line at the end of the file
  // SubSampleFileNames.push_back(FileNames);

  // open the first one to figure out how many tasks there are
  // we need to perform bootstrap on a task by task, read centrality class
  TFile *dataFile = new TFile(SubSampleFileNames.at(0).at(0).c_str(), "READ");
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(
      dataFile->Get(std::getenv("OUTPUT_TDIRECTORY_FILE")));

  // book one TProfile for each task
  // the first bin holds the overall average, the other bins the averages of the
  // subsamples
  TList *profileList = new TList();
  for (auto KeyTask : *(tdirFile->GetListOfKeys())) {
    TList *list = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));
    profileList->Add(new TProfile(
        Form("Bootstrap_%s_%s", KeyTask->GetName(), observable), observable,
        SubSampleFileNames.size() + 1, 0, SubSampleFileNames.size() + 1));
  }

  // start looping over all files/task and compute the averages
  Int_t index = 0;
  for (std::size_t i = 0; i < SubSampleFileNames.size(); i++) {

    for (std::size_t j = 0; j < SubSampleFileNames.at(i).size(); j++) {

      dataFile = new TFile(SubSampleFileNames.at(i).at(j).c_str(), "READ");
      TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(
          dataFile->Get(std::getenv("OUTPUT_TDIRECTORY_FILE")));

      index = 0;
      for (auto KeyTask : *(tdirFile->GetListOfKeys())) {
        TList *list = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));
        TH1 *hist =
            dynamic_cast<TH1 *>(IterateList(list, std::string(observable)));
        dynamic_cast<TProfile *>(profileList->At(index))
            ->Fill(0.5, hist->GetBinContent(1));
        dynamic_cast<TProfile *>(profileList->At(index))
            ->Fill(i + 1.5, hist->GetBinContent(1));

        index++;

        // keep here till we fix analysis task
        // if (i == 0 && j == 0) {
        //   Lcen = dynamic_cast<TH1 *>(
        //              IterateList(list, std::string("EventCutValues")))
        //              ->GetBinContent(11);
        //   Ucen = dynamic_cast<TH1 *>(
        //              IterateList(list, std::string("EventCutValues")))
        //              ->GetBinContent(12);
        //   std::cout << Lcen << " - " << Ucen << std::endl;
        //   centrality.push_back((Ucen - Lcen) / 50.);
        // }
      }
      dataFile->Close();
    }
  }

  Double_t var = 0;
  TGraphErrors *g = new TGraphErrors();
  g->SetName(observable);
  g->SetTitle(observable);
  g->GetXaxis()->SetTitle("centrality percentile");

  // keep here till we fix analysis task
  centrality = {2.5, 7.5, 15, 25, 35, 45, 55, 65, 75};
  index = 0;
  for (auto *p : *profileList) {

    TH1 *t = dynamic_cast<TH1 *>(p);

    var = 0;
    for (int i = 2; i < t->GetNbinsX(); i++) {
      var += std::pow(t->GetBinContent(i) - t->GetBinContent(1), 2);
    }
    var = std::sqrt(var / ((t->GetNbinsX() - 1) * (t->GetNbinsX() - 2)));

    g->SetPoint(index, centrality.at(index), t->GetBinContent(1));
    g->SetPointError(index, 0, var);

    index++;
  }

  TFile *out = new TFile(std::getenv("LOCAL_OUTPUT_BOOTSTRAP_FILE"), "UPDATE");
  // profileList->Write();
  g->Write();
  out->Close();

  return 0;
}
