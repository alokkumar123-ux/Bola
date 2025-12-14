import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/model/recent_search_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';

class SearchUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
   static Future<bool?> setSearchHistory(
      RecentSearchModel recentSearchModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.userSearchHistory)
        .doc(recentSearchModel.id)
        .set(recentSearchModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      print("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<RecentSearchModel>?> getSearchHistory() async {
    List<RecentSearchModel> list = [];

    await fireStore
        .collection(CollectionName.userSearchHistory)
        .where("userId", isEqualTo: AuthUtils.getCurrentUid())
        .orderBy('createdAt', descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        RecentSearchModel searchModel =
            RecentSearchModel.fromJson(element.data());
        list.add(searchModel);
      }
    }).catchError((error) {
      print(error.toString());
    });
    return list;
  }
}
