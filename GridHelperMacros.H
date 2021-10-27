/**
 * File              : GridHelperMacros.H
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 14.10.2021
 * Last Modified Date: 27.10.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

#include <boost/algorithm/string.hpp>

// void IterateList(TList *searchList, TList *resultList, std::string
// searchString,
//                  std::string prefix) {
//   std::string s;
//   for (auto key : *searchList) {
//     if (key->IsFolder()) {
//       IterateList(dynamic_cast<TList *>(key), resultList, searchString,
//       prefix);
//     } else {
//       s = std::string(key->GetName());
//       if (boost::contains(s, searchString)) {
//         s = prefix + s;
//         resultList->Add(key->Clone(s.c_str()));
//       }
//     }
//   }
// }

TObject *IterateList(TList *list, std::string searchString) {

  TObject *obj = nullptr;
  for (auto key : *list) {
    if (key->IsFolder()) {
      obj = IterateList(dynamic_cast<TList *>(key), searchString);
    } else {
      obj = key;
    }
    if (boost::contains(std::string(obj->GetName()), searchString)) {
      break;
    }
  }
  return obj;
}
