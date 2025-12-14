import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/document_model.dart';
import 'package:poolmate/model/user_verification_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';

class DocumentUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static Future<List<DocumentModel>> getDocumentList() async {
    List<DocumentModel> documentList = [];
    await fireStore
        .collection(CollectionName.documents)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        DocumentModel documentModel = DocumentModel.fromJson(element.data());
        documentList.add(documentModel);
      }
    }).catchError((error) {
      print(error.toString());
    });
    return documentList;
  }

  static Future<UserVerificationModel?> getDocumentOfDriver() async {
    UserVerificationModel? driverDocumentModel;
    await fireStore
        .collection(CollectionName.userVerification)
        .doc(AuthUtils.getCurrentUid())
        .get()
        .then((value) async {
      if (value.exists) {
        driverDocumentModel = UserVerificationModel.fromJson(value.data()!);
      }
    });
    return driverDocumentModel;
  }

  static Future<bool> uploadDriverDocument(Documents documents) async {
    bool isAdded = false;
    UserVerificationModel driverDocumentModel = UserVerificationModel();
    List<Documents> documentsList = [];
    await fireStore
        .collection(CollectionName.userVerification)
        .doc(AuthUtils.getCurrentUid())
        .get()
        .then((value) async {
      if (value.exists) {
        UserVerificationModel newDriverDocumentModel =
            UserVerificationModel.fromJson(value.data()!);
        documentsList = newDriverDocumentModel.documents!;
        var contain = newDriverDocumentModel.documents!
            .where((element) => element.documentId == documents.documentId);
        if (contain.isEmpty) {
          documentsList.add(documents);

          driverDocumentModel.id = AuthUtils.getCurrentUid();
          driverDocumentModel.documents = documentsList;
        } else {
          var index = newDriverDocumentModel.documents!.indexWhere(
              (element) => element.documentId == documents.documentId);

          driverDocumentModel.id = AuthUtils.getCurrentUid();
          documentsList.removeAt(index);
          documentsList.insert(index, documents);
          driverDocumentModel.documents = documentsList;
          isAdded = false;
          ShowToastDialog.showToast("Document is under verification");
        }
      } else {
        documentsList.add(documents);
        driverDocumentModel.id = AuthUtils.getCurrentUid();
        driverDocumentModel.documents = documentsList;
      }
    });

    await fireStore
        .collection(CollectionName.userVerification)
        .doc(AuthUtils.getCurrentUid())
        .set(driverDocumentModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
      print(error.toString());
    });

    return isAdded;
  }

  // Function to handle document approval and update verification status
  static Future<bool> approveUserDocument({
    required String userId,
    required String documentId,
    required String documentTitle,
  }) async {
    bool isSuccess = false;

    try {
      // Get the user verification data for the specific user
      UserVerificationModel? userVerification;
      await fireStore
          .collection(CollectionName.userVerification)
          .doc(userId)
          .get()
          .then((value) {
        if (value.exists) {
          userVerification = UserVerificationModel.fromJson(value.data()!);
        }
      });

      if (userVerification != null && userVerification!.documents != null) {
        List<Documents> documents = userVerification!.documents!;

        // Find and update the specific document
        var docIndex =
            documents.indexWhere((doc) => doc.documentId == documentId);

        if (docIndex >= 0) {
          documents[docIndex].verified = true;
          documents[docIndex].status = "approved";

          // Create updated verification model
          UserVerificationModel updatedVerification = UserVerificationModel(
            documents: documents,
            id: userVerification!.id,
          );

          // Update the user verification document
          await fireStore
              .collection(CollectionName.userVerification)
              .doc(userId)
              .set(updatedVerification.toJson());

          // Update user verification status based on document type
          await UserUtils.updateUserVerificationStatus(
            userId: userId,
            documentType: documentTitle,
            isVerified: true,
          );

          isSuccess = true;
          print(
              "Document approved and verification status updated for user $userId");
        }
      }
    } catch (error) {
      print("Error in approveUserDocument: $error");
      isSuccess = false;
    }

    return isSuccess;
  }

  // Function to handle KYC verification (Aadhaar via webview)
  static Future<bool> updateKYCVerificationStatus(String userId) async {
    try {
      // Update user verification status for Aadhaar (passenger verification)
      await UserUtils.updateUserVerificationStatus(
        userId: userId,
        documentType: "aadhaar", // This will trigger passenger verification
        isVerified: true,
      );

      print("KYC verification status updated for user $userId");
      return true;
    } catch (error) {
      print("Error updating KYC verification status: $error");
      return false;
    }
  }
}
