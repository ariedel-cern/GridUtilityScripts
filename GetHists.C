/**
 * File              : GetHists.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 15.09.2021
 * Last Modified Date: 14.10.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"
#include <algorithm>

Int_t GetHists(const char *DataFile, const char *OutputFileName,
               const char *Search) {

  TFile *dataFile = new TFile(DataFile, "READ");

  // open output directory
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(
      dataFile->Get(std::getenv("OUTPUT_TDIRECTORY_FILE")));

  TFile *outputFile = new TFile(OutputFileName, "UPDATE");
  TList *searchList;
  TObject *obj;
  TH1D *hist;
  std::string searchString(Search);
  std::string name;

  for (auto KeyTask : *(tdirFile->GetListOfKeys())) {

    std::cout << "Working on Task: " << KeyTask->GetName() << std::endl;
    searchList = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));
    name = std::string(KeyTask->GetName());
    name += "_";

    obj = Iterate(searchList, searchString);
    name += obj->GetName();

    hist = dynamic_cast<TH1D *>(obj->Clone(name.c_str()));

    hist->Write();
  }

  outputFile->Close();
  dataFile->Close();
  return 0;
}
