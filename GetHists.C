/**
 * File              : GetHists.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 15.09.2021
 * Last Modified Date: 14.10.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "InterateList.H"

Int_t GetHists(const char *DataFile, const char *OutputFileName,
               const char *Search) {

  TFile *dataFile = new TFile(DataFile, "READ");

  // open output directory
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(
      dataFile->Get(std::getenv("OUTPUT_TDIRECTORY_FILE")));

  TFile *outputFile = new TFile(OutputFileName, "UPDATE");
  TList *searchList;
  TList *resultList = new TList();
  resultList->SetOwner(kTRUE);
  std::string searchString(Search);
  std::string prefix;

  for (auto KeyTask : *(tdirFile->GetListOfKeys())) {

    searchList = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));
    prefix = std::string(KeyTask->GetName());
    prefix += "_";
    IterateList(searchList, resultList, searchString, prefix);

    for (auto obj : *resultList) {
      obj->Write();
    }
    resultList->Clear();
  }

  outputFile->Close();
  dataFile->Close();
  return 0;
}
