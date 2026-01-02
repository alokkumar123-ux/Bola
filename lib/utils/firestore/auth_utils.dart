import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/preferences.dart';

/// Authentication and user existence utilities
class AuthUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  /// Get current user ID from local storage or Firebase Auth
  static String getCurrentUid() {
    String localUid = Preferences.getString(Preferences.currentUserIdKey);
    if (localUid.isNotEmpty) {
      return localUid;
    }
    if (FirebaseAuth.instance.currentUser != null) {
      return FirebaseAuth.instance.currentUser!.uid;
    }
    return '';
  }

  /// Save current user ID to local storage
  static Future<void> setCurrentUid(String uid) async {
    await Preferences.setString(Preferences.currentUserIdKey, uid);
  }

  /// Clear current user ID from local storage (for logout)
  static Future<void> clearCurrentUid() async {
    await Preferences.clearKeyData(Preferences.currentUserIdKey);
  }

  /// Check if user is logged in
  static Future<bool> isLogin() async {
    String currentUid = getCurrentUid();
    if (currentUid.isNotEmpty) {
      return await userExistOrNot(currentUid);
    }
    return false;
  }

  /// Check if user exists in Firestore
  static Future<bool> userExistOrNot(String uid) async {
    bool isExist = false;
    await fireStore.collection(CollectionName.users).doc(uid).get().then(
      (value) {
        isExist = value.exists;
      },
    ).catchError((error) {
      print("Failed to check user exist: $error");
      isExist = false;
    });
    return isExist;
  }

  /// Check if user exists by phone number
  static Future<bool> userExistByPhoneNumber(
      String countryCode, String phoneNumber) async {
    bool isExist = false;
    try {
      final querySnapshot = await fireStore
          .collection(CollectionName.users)
          .where('countryCode', isEqualTo: countryCode)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      isExist = querySnapshot.docs.isNotEmpty;
    } catch (error) {
      print("Failed to check user exist by phone: $error");
      isExist = false;
    }
    return isExist;
  }

  /// Get user profile by phone number
  static Future<UserModel?> getUserByPhoneNumber(
      String countryCode, String phoneNumber) async {
    UserModel? userModel;
    try {
      final querySnapshot = await fireStore
          .collection(CollectionName.users)
          .where('countryCode', isEqualTo: countryCode)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        userModel = UserModel.fromJson(querySnapshot.docs.first.data());
      }
    } catch (error) {
      print("Failed to get user by phone: $error");
    }
    return userModel;
  }

  /// Delete user and their Firebase Auth account
  static Future<bool?> deleteUser() async {
    try {
      await fireStore
          .collection(CollectionName.users)
          .doc(getCurrentUid())
          .delete();
      await FirebaseAuth.instance.currentUser!.delete();
      return true;
    } catch (e) {
      print('Failed to delete user: $e');
      return false;
    }
  }
}
