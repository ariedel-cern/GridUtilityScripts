/**
 * File              : Trending.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 12.08.2021
 * Last Modified Date: 14.10.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"
#include <boost/algorithm/string.hpp>

Int_t Trending(const char *DataFiles, Int_t NumberOfRuns, const char *Output,
               const char *Trend) {

  // file holding list of all merged files
  std::ifstream Filenames(DataFiles);

  // variables used in loop over all file names
  std::string Filename;
  TFile *File;
  TDirectoryFile *ResultDir;
  TList *Task;
  Int_t Run = 1;
  std::string runname;
  Int_t start, end;
  TH1 *tmp;
  TH1D *hist = new TH1D(Trend, "Trending", NumberOfRuns, 0, NumberOfRuns);
  hist->SetMinimum(1e-6);

  // loop over filename
  for (std::string line; getline(Filenames, Filename);) {

    // get run number from path
    // path will have the form
    // $OUTPUT_DIR_REL/RUNNUMBER/MERGED.root
    // extract the string within /.../
    // std::cout << Filename << std::endl;

    start = Filename.find("/");
    end = Filename.find("/", start + 1);
    runname = Filename.substr(start + 1, end - start - 1);
    // std::cout << runname << std::endl;

    File = TFile::Open(Filename.c_str(), "READ");
    ResultDir = dynamic_cast<TDirectoryFile *>(
        File->Get(std::getenv("OUTPUT_TDIRECTORY_FILE")));

    // hack to get the first task
    // only support for one task so far
    for (auto T : *(ResultDir->GetListOfKeys())) {
      Task = dynamic_cast<TList *>(ResultDir->Get(T->GetName()));
      tmp = dynamic_cast<TH1 *>(Iterate(Task, std::string(Trend)));
      break;
    }

    hist->SetBinContent(Run, tmp->GetBinContent(1));
    hist->SetBinError(Run, tmp->GetBinError(1));
    hist->GetXaxis()->SetBinLabel(Run, runname.c_str());

    File->Close();
    std::cout << Run << "/" << NumberOfRuns << std::endl;
    Run++;
  }

  TFile *out = new TFile(Output, "UPDATE");
  hist->Write();
  out->Close();

  return 0;
}
