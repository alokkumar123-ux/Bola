import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/model/report_model.dart';

class ReportUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
   static Future<bool?> setReport(ReportModel recentSearchModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.report)
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
}
