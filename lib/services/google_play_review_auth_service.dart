// ============================================================
// GOOGLE PLAY REVIEW LOGIN — Auth Service
// ============================================================
// Handles creating / fetching the reviewer's Firestore profile
// and establishing a local session — completely bypassing
// WhatsApp OTP.  Remove this file after app approval.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/services/google_play_review_config.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/services/fcm_token_manager.dart';

class GooglePlayReviewAuthService {
  static final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  // ----------------------------------------------------------
  // GOOGLE PLAY REVIEW LOGIN: Authenticate the reviewer.
  //
  // Steps:
  //   1. Check Firestore for the stable reviewer profile.
  //   2. If it exists, reuse it; otherwise create a minimal profile.
  //   3. Save the UID to local storage (same as normal login).
  //   4. Optionally refresh the FCM token.
  //
  // Returns the [UserModel] on success, null on any error.
  // ----------------------------------------------------------
  static Future<UserModel?> authenticateReviewer() async {
    debugPrint(
      '🚀 [GOOGLE PLAY REVIEW LOGIN] Starting reviewer authentication...',
    );

    try {
      final String uid = GooglePlayReviewConfig.reviewUserId;
      final docRef =
          _fireStore.collection(CollectionName.users).doc(uid);

      // Step 1: Fetch existing profile
      final docSnapshot = await docRef.get();

      UserModel reviewerModel;

      if (docSnapshot.exists) {
        // Reuse existing reviewer profile
        reviewerModel = UserModel.fromJson(docSnapshot.data()!);
        debugPrint(
          '♻️  [GOOGLE PLAY REVIEW LOGIN] Reusing existing reviewer profile: $uid',
        );
      } else {
        // Create a new minimal reviewer profile
        debugPrint(
          '🆕 [GOOGLE PLAY REVIEW LOGIN] Creating reviewer profile in Firestore...',
        );
        reviewerModel = _buildReviewerProfile(uid);
        await docRef.set(reviewerModel.toJson(), SetOptions(merge: true));
        debugPrint(
          '✅ [GOOGLE PLAY REVIEW LOGIN] Reviewer profile created: $uid',
        );
      }

      // Step 2: Establish local session (same mechanism as normal login)
      await AuthUtils.setCurrentUid(uid);
      debugPrint(
        '🔐 [GOOGLE PLAY REVIEW LOGIN] Local session established for UID: $uid',
      );

      // Step 3: Refresh FCM token (best-effort, non-blocking)
      try {
        await FcmTokenManager.saveCurrentToken();
        debugPrint(
          '📲 [GOOGLE PLAY REVIEW LOGIN] FCM token refreshed for reviewer.',
        );
      } catch (e) {
        debugPrint(
          '⚠️  [GOOGLE PLAY REVIEW LOGIN] FCM token refresh skipped: $e',
        );
      }

      debugPrint(
        '🎉 [GOOGLE PLAY REVIEW LOGIN] Reviewer fully authenticated. '
        'Navigating to dashboard.',
      );
      return reviewerModel;
    } catch (e, stackTrace) {
      debugPrint(
        '❌ [GOOGLE PLAY REVIEW LOGIN] Authentication failed: $e\n$stackTrace',
      );
      return null;
    }
  }

  // ----------------------------------------------------------
  // GOOGLE PLAY REVIEW LOGIN: Build the minimal reviewer UserModel.
  // All fields are pre-filled so the reviewer can access every
  // feature without completing onboarding.
  // ----------------------------------------------------------
  static UserModel _buildReviewerProfile(String uid) {
    return UserModel(
      id: uid,
      firstName: 'Google Play',
      lastName: 'Reviewer',
      email: 'reviewer@googleplay.com',
      countryCode: GooglePlayReviewConfig.reviewCountryCode,
      phoneNumber: GooglePlayReviewConfig.reviewPhoneNumber,
      loginType: Constant.phoneLoginType,
      profilePic: '',
      walletAmount: '0.0',
      isActive: true,
      // isVerify is not a constructor param — set via toJson/Firestore merge below
      aadharVerified: false,
      panVerified: false,
      gender: 'Male',
      bio: 'Google Play Review Account',
      referralCode: 'GPREVIEW',
      referralStage: 0,
      reviewCount: '0.0',
      reviewSum: '0.0',
      createdAt: Timestamp.now(),
    );
  }
}
