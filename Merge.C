/**
 * File              : Merge.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 19.03.2021
 * Last Modified Date: 18.06.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include <TDataType.h>
#include <TFileMerger.h>
#include <fstream>
#include <string>
#include <vector>

Int_t Merge(const char *filename, const char *output) {

  /* create filemerger object */
  TFileMerger *tfm = new TFileMerger();

  /* set name of merged file */
  tfm->OutputFile(output);

  /* open file containing paths to all files to be merged */
  std::fstream filesToMerge;
  filesToMerge.open(filename, std::ios::in);

  /* pointer for holding opened files */
  TFile *file;

  /* needed for running over all filenames */
  std::string line;
  std::vector<std::string> batch;

  /* merge in cycles such that we do not open too many files simultaneously */
  Int_t nCycles = 10;
  Int_t n = 0;

  /* loop over all file names */
  while (getline(filesToMerge, line)) {
    /* store filenames inside a vector until we have enough files for one merge
     * cycle */
    batch.push_back(line);
    n++;

    /* start merge cycle */
    if (n >= nCycles) {
      /* loop over all filenames inside the vector */
      for (auto f : batch) {
        tfm->AddFile(f.c_str());
      }
      /* merge files */
      tfm->Merge();
      /* reset vector */
      batch.clear();
      /* add merged file so we merge it again during the next cycle */
      batch.push_back(output);
      /* reset counter +1 for previously merged files */
      n = 1;
    }
  }

  /* if the number of files is not an integer multiple of the number of cycles
   * catch all remaining not merged files */
  /* 1 because we push back merged file after every cycle */
  if (batch.size() != 1) {
    for (auto f : batch) {
      tfm->AddFile(f.c_str());
    }
    tfm->Merge();
  }

  /* close file */
  filesToMerge.close();

  return 0;
}
