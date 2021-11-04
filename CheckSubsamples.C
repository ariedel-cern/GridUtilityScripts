/**
 * File              : CheckSubsamples.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 04.11.2021
 * Last Modified Date: 04.11.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"

Int_t CheckSubsamples(const char *FileSubSamplesName) {

  // open file holding path to files, grouped into subsamples
  //   the subsamples are divided by a new line
  std::ifstream FileSubSamples(FileSubSamplesName);
  std::string FileName;

  // fill the path to the files into a vector of vector of strings
  TH1D *hist = new TH1D("SubSamples", "SubSamples", 15, 0, 15);
  TFile *file;
  TList *task;

  Int_t Bin = 1;
  Double_t Content = 0;
  while (getline(FileSubSamples, FileName)) {

    if (FileName.empty()) {
      hist->SetBinContent(Bin, Content);
      Bin++;
      Content = 0;
    } else {
      file = new TFile(FileName.c_str(), "READ");

      TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(
          file->Get(std::getenv("OUTPUT_TDIRECTORY_FILE")));

      // select different task depending on the offset
      Int_t offset = 0;
      for (auto T : *(tdirFile->GetListOfKeys())) {
        task = dynamic_cast<TList *>(tdirFile->Get(T->GetName()));
        Content += dynamic_cast<TH1 *>(IterateList(task, "kNUMBEROFEVENTS"))
                       ->GetBinContent(1);
        if (offset == 0) {
          break;
        }
        offset++;
      }

      file->Close();
    }
  }

  TFile *out = new TFile("SubSamples.root", "RECREATE");
  hist->Write();
  out->Close();

  return 0;
}
