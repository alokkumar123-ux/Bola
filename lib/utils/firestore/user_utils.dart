import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/model/on_boarding_model.dart';
import 'package:poolmate/model/tax_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';

/// User profile and data management utilities
class UserUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  /// Get user profile by UUID
  static Future<UserModel?> getUserProfile(String uuid) async {
    UserModel? userModel;
    await fireStore
        .collection(CollectionName.users)
        .doc(uuid)
        .get()
        .then((value) {
      if (value.exists) {
        userModel = UserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      print("Failed to get user profile: $error");
      userModel = null;
    });
    return userModel;
  }

  /// Update user profile
  static Future<bool> updateUser(UserModel userModel) async {
    bool isUpdate = false;
    try {
      await fireStore
          .collection(CollectionName.users)
          .doc(userModel.id)
          .set(userModel.toJson(), SetOptions(merge: true));
      isUpdate = true;
      print("✅ User profile updated successfully for ${userModel.id}");
    } catch (error) {
      print("❌ Failed to update user: $error");
      isUpdate = false;
    }
    return isUpdate;
  }

  /// Update user verification status for specific document type
  static Future<bool> updateUserVerificationStatus({
    required String userId,
    required String documentType,
    required bool isVerified,
  }) async {
    bool isUpdate = false;
    try {
      UserModel? currentUser = await getUserProfile(userId);
      if (currentUser == null) return false;

      bool isAadhaarDoc = documentType.toLowerCase().contains('aadhaar') ||
          documentType.toLowerCase().contains('aadhar');
      Map<String, dynamic> updateData = {};

      if (isAadhaarDoc) {
        currentUser.aadharVerified = isVerified;
        updateData['aadharVerified'] = isVerified;
        print("Updating aadharVerified to $isVerified");
      }

      bool overallVerified = (currentUser.aadharVerified == true) &&
          (currentUser.panVerified == true);
      currentUser.isVerify = overallVerified;
      updateData['isVerify'] = overallVerified;

      await fireStore
          .collection(CollectionName.users)
          .doc(userId)
          .update(updateData)
          .then((_) {
        isUpdate = true;
        print("Successfully updated verification status for user $userId");
      }).catchError((error) {
        print("Failed to update verification status: $error");
        isUpdate = false;
      });
    } catch (error) {
      print("Error in updateUserVerificationStatus: $error");
      isUpdate = false;
    }
    return isUpdate;
  }

  /// Get onboarding list
  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    List<OnBoardingModel> onBoardingModel = [];
    await fireStore.collection(CollectionName.onBoarding).get().then((value) {
      for (var element in value.docs) {
        onBoardingModel.add(OnBoardingModel.fromJson(element.data()));
      }
    }).catchError((error) {
      print(error.toString());
    });
    return onBoardingModel;
  }

  /// Get tax list
  static Future<List<TaxModel>?> getTaxList() async {
    List<TaxModel> taxList = [];
    await fireStore
        .collection(CollectionName.tax)
        .where('country', isEqualTo: AuthUtils.getCurrentUid())
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        taxList.add(TaxModel.fromJson(element.data()));
      }
    }).catchError((error) {
      print(error.toString());
    });
    return taxList;
  }
}
