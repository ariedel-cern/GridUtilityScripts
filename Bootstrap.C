/**
 * File              : Bootstrap.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 27.10.2021
 * Last Modified Date: 02.11.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

R__ADD_INCLUDE_PATH($ALICE_ROOT)
R__ADD_INCLUDE_PATH($ALICE_PHYSICS)
#include "GridHelperMacros.H"

Int_t Bootstrap(const char *FileSubSamplesName, const char *observable) {

  std::ifstream FileSubSamples(FileSubSamplesName);
  std::string FileName;

  std::vector<std::vector<std::string>> SubSampleFileNames;
  std::vector<std::string> FileNames;

  while (getline(FileSubSamples, FileName)) {

    if (FileName.empty()) {
      SubSampleFileNames.push_back(FileNames);
      FileNames.clear();
    } else {
      FileNames.push_back(FileName);
    }
  }
  SubSampleFileNames.push_back(FileNames);

  // TProfile *profile =
  //     new TProfile("profile", "profile", SubSampleFileNames.size() + 1, 0,
  //                  SubSampleFileNames.size() + 1);

  Int_t test = 0;

  TFile *dataFile = new TFile(SubSampleFileNames.at(0).at(0).c_str(), "READ");
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(
      dataFile->Get(std::getenv("OUTPUT_TDIRECTORY_FILE")));
  Int_t NumberOfTasks = tdirFile->GetListOfKeys()->GetSize();

  TList *profileList = new TList();

  for (auto KeyTask : *(tdirFile->GetListOfKeys())) {
    TList *list = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));
    profileList->Add(new TProfile(
        Form("Bootstrap_%s_%s", KeyTask->GetName(), observable), observable,
        SubSampleFileNames.size() + 1, 0, SubSampleFileNames.size() + 1));
  }
  // dataFile->Close();

  Int_t index;

  for (std::size_t i = 0; i < SubSampleFileNames.size(); i++) {

    for (std::size_t j = 0; j < SubSampleFileNames.at(i).size(); j++) {

      dataFile = new TFile(SubSampleFileNames.at(i).at(j).c_str(), "READ");

      // open output directory
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
      }
      dataFile->Close();
    }
  }

  TFile *out = new TFile("out.root", "RECREATE");
  profileList->Write("bootstrap.root");
  out->Close();

  return 0;
}
