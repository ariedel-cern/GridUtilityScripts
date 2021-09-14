/**
 * File              : Trending.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 12.08.2021
 * Last Modified Date: 14.09.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include <TDataType.h>
#include <TFile.h>
#include <TH1D.h>
#include <TProfile.h>
#include <boost/algorithm/string.hpp>
#include <fstream>
#include <iostream>

Int_t Trending(const char *DataFiles, Int_t NumberOfRuns, const char *Output) {

  // file holding list of all merge files
  std::ifstream Filenames(DataFiles);

  // variables used in loop over all file names
  std::string Filename;
  TFile *File;
  TDirectoryFile *ResultDir;
  TList *Task;
  TProfile *Profile;
  Int_t Run = 0;
  Int_t listindex = 0;
  std::vector<TH1D> hists;
  std::string histname;
  std::string runname;

  // loop over filename
  for (std::string line; getline(Filenames, Filename);) {
    // std::cout << Filename << std::endl;
    runname = Filename.substr(14, 6);
    std::cout << runname << std::endl;
    File = TFile::Open(Filename.c_str(), "READ");
    ResultDir = dynamic_cast<TDirectoryFile *>(
        File->Get(std::getenv("GRID_OUTPUT_ROOT_FILE")));
    // loop over tasks inside one file and the the final result profile
    listindex = 0;
    for (auto T : *(ResultDir->GetListOfKeys())) {
      Task = dynamic_cast<TList *>(ResultDir->Get(T->GetName()));
      Profile = dynamic_cast<TProfile *>(
          dynamic_cast<TList *>(Task->FindObject("FinalResults"))
              ->FindObject("fFinalResultProfiles[kHARDATA]"));
      // loop over bins in the final result profile
      for (int bin = 0; bin < Profile->GetNbinsX(); ++bin) {

        // provision histograms
        if (Run == 0 && bin == 0 && listindex == 0) {
          // std::cout << "here" << std::endl;
          // number of correlators
          // std::cout << Profile->GetNbinsX() << " "
          //           << ResultDir->GetListOfKeys()->GetSize() << std::endl;
          for (int k = 0; k < ResultDir->GetListOfKeys()->GetSize(); ++k) {
            for (int l = 0; l < Profile->GetNbinsX(); ++l) {
              // std::cout << ResultDir->GetListOfKeys()->At(k)->GetName()
              //           << std::endl;
              // std::cout << Profile->GetXaxis()->GetBinLabel(l + 1) <<
              // std::endl;
              histname =
                  std::string(ResultDir->GetListOfKeys()->At(k)->GetName());
              histname.erase(0, 9);
              histname = std::string(Profile->GetXaxis()->GetBinLabel(l + 1)) +
                         std::string(" in Centrality Percentile ") + histname;
              boost::erase_last(histname, ",");
              // std::cout << histname << std::endl;
              hists.push_back(TH1D(histname.c_str(), histname.c_str(),
                                   NumberOfRuns, 0, NumberOfRuns));
            }
          }
        }
        // std::cout << "after here" << std::endl;
        hists.at(listindex + bin * ResultDir->GetListOfKeys()->GetSize())
            .SetBinContent(Run + 1, Profile->GetBinContent(bin + 1));
        hists.at(listindex + bin * ResultDir->GetListOfKeys()->GetSize())
            .SetBinError(Run + 1, Profile->GetBinError(bin + 1));
        hists.at(listindex + bin * ResultDir->GetListOfKeys()->GetSize())
            .GetXaxis()
            ->SetBinLabel(Run + 1, runname.c_str());
      }
      listindex++;
    }
    Run++;
    File->Close();
  }

  TFile *out = new TFile(Output, "RECREATE");
  for (auto h : hists) {
    h.Write();
  }
  out->Close();

  return 0;
}
