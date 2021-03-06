/**
 * File              : ReTerminate.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 14.05.2021
 * Last Modified Date: 27.01.2022
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include <boost/algorithm/string.hpp>
#include <nlohmann/json.hpp>

Int_t ReTerminate(const char *mergedFileName) {

  std::fstream ConfigFile("config.json");
  nlohmann::json Jconfig = nlohmann::json::parse(ConfigFile);

  // open merged file
  TFile *mergedFile = new TFile(mergedFileName, "READ");

  // mergedFile->ls();

  // create new file so we do not overwrite the original
  std::string reterminatedFileName(mergedFileName);
  boost::replace_all(reterminatedFileName, "Merged", "ReTerminated");
  TFile *updatedFile = new TFile(reterminatedFileName.c_str(), "RECREATE");

  // initalize task
  AliAnalysisTaskAR *Task = new AliAnalysisTaskAR("ReTerminate");

  // get TDirectoryFile holding all outputs
  TDirectoryFile *tdirFile = dynamic_cast<TDirectoryFile *>(mergedFile->Get(
      Jconfig["task"]["OutputTDirectory"].get<std::string>().c_str()));

  /* create new TDirectoryFile to hold the updated outputs, give it the same
   * name and title as the old one, cloning not working? */
  TDirectoryFile *newTdirFile =
      new TDirectoryFile(tdirFile->GetName(), tdirFile->GetTitle());

  // change directory to new TDirectoryFile so we write the updated lists to it
  newTdirFile->cd();

  // loop over all output lists
  TList *TaskList;
  for (auto KeyTask : *(tdirFile->GetListOfKeys())) {
    // get the output list of a task
    TaskList = dynamic_cast<TList *>(tdirFile->Get(KeyTask->GetName()));
    std::cout << "Working on Task: " << KeyTask->GetName() << " ... ";
    // TaskList->ls();
    // initialize the task with the list
    Task->GetPointers(TaskList);
    // RETERMINATE
    Task->Terminate(nullptr);
    // write the reterminated list back to the new TDirectoryFile
    TaskList->Write(TaskList->GetName(),
                    TObject::kSingleKey + TObject::kOverwrite);
    std::cout << "Done" << std::endl;
  }

  // write all reterminated objects back to file
  updatedFile->cd();
  newTdirFile->Write(newTdirFile->GetName());

  // close files
  updatedFile->Close();
  mergedFile->Close();

  return 0;
}
