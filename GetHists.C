/**
 * File              : GetHists.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 15.09.2021
 * Last Modified Date: 16.09.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include <boost/algorithm/string.hpp>

void *IterateList(TList *list, std::string searchString, std::string prefix) {

  TObject *hist;
  std::string s;
  for (auto key : *list) {
    if (key->IsFolder()) {
      IterateList(dynamic_cast<TList *>(key), searchString, prefix);
    } else {
      s = std::string(key->GetName());
      if (boost::contains(s, searchString)) {
        s = prefix + s;
        std::cout << "Found:" << s << std::endl;
        hist = key->Clone(s.c_str());
        hist->Write();
      }
    }
  }
  return nullptr;
}

Int_t GetHists(const char *DataFile, const char *OutputFileName,
               const char *Search) {

  TFile *dataFile = new TFile(DataFile, "READ");
  // open output directory
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(
      dataFile->Get(std::getenv("OUTPUT_TDIRECTORY_FILE")));

  TFile *outputFile = new TFile(OutputFileName, "UPDATE");
  TList *list;
  std::string searchString(Search);
  std::string prefix;
  for (auto KeyTask : *(tdirFile->GetListOfKeys())) {
    list = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));
    prefix = std::string(KeyTask->GetName());
    prefix += "_";
    IterateList(list, searchString, prefix);
  }

  outputFile->Close();
  dataFile->Close();
  return 0;
}
