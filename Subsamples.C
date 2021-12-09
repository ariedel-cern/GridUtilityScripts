/**
 * File              : Subsamples.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 03.11.2021
 * Last Modified Date: 03.11.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include "GridHelperMacros.H"
#include <cmath>
#include <iterator>
#include <vector>

Int_t Subsamples(const char *listOfFiles, const char *outputFileName) {

  // file holding list of all reterminated files
  std::ifstream Filenames(listOfFiles);

  // variables used in loop over all file names
  std::string Filename;
  TFile *File;
  TDirectoryFile *ResultDir;
  TList *Task;
  TH1 *tmp;

  std::vector<std::string> files;
  std::vector<Double_t> events;

  // loop over filename
  for (std::string line; getline(Filenames, Filename);) {

    File = TFile::Open(Filename.c_str(), "READ");
    ResultDir = dynamic_cast<TDirectoryFile *>(
        File->Get(std::getenv("OUTPUT_TDIRECTORY_FILE")));

    // hack to get the first task
    // only support for one task so far
    for (auto T : *(ResultDir->GetListOfKeys())) {
      Task = dynamic_cast<TList *>(ResultDir->Get(T->GetName()));
      tmp = dynamic_cast<TH1 *>(
          IterateList(Task, std::string("[kNUMBEROFEVENTS]")));
      break;
    }

    files.push_back(Filename);
    events.push_back(tmp->GetBinContent(1));
    File->Close();
  }

  Double_t N = 5;
  Double_t Target = std::accumulate(events.begin(), events.end(), 0.) / N;
  Double_t alpha = 0.4;

  Double_t sampleSize = 0;
  std::vector<std::string> sample;

  Int_t index = 0;
  Int_t counter = 0;

  std::ofstream outFile(outputFileName);

  // sort(events.begin(), events.end(), greater<Double_t>());

  while (!files.empty()) {

    std::cout << "Remaining files: " << files.size() << std::endl
              << "sample size " << sampleSize << std::endl
              << "number of files " << sample.size() << std::endl;

    if (sampleSize + events.at(index) < Target * (1 - alpha)) {
      sampleSize += events.at(index);
      events.erase(events.begin() + index);
      sample.push_back(files.at(index));
      files.erase(files.begin() + index);
    } else if (sampleSize + events.at(index) > Target * (1 + alpha)) {
      index++;
    } else {

      std::cout << "Found sample" << std::endl;
      for (auto f : sample) {
        outFile << f << std::endl;
      }
      outFile << std::endl;

      sample.clear();
      sampleSize = 0;
      index = 0;
      counter++;
    }

    if (counter == N) {
      break;
    }
  }

  std::cout << "dump rest" << std::endl;
  for (auto f : files) {
    outFile << f << std::endl;
  }
  outFile << std::endl;

  return 0;
}
