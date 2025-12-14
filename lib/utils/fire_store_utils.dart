// import 'dart:async';
// import 'dart:developer';
// import 'dart:math' as math;
// import 'dart:ui';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:rxdart/rxdart.dart';
// import 'package:poolmate/constant/collection_name.dart';
// import 'package:poolmate/constant/constant.dart';
// import 'package:poolmate/constant/show_toast_dialog.dart';
// import 'package:poolmate/model/admin_commission.dart';
// import 'package:poolmate/model/booking_model.dart';
// import 'package:poolmate/model/conversation_admin_model.dart';
// import 'package:poolmate/model/currency_model.dart';
// import 'package:poolmate/model/document_model.dart';
// import 'package:poolmate/model/inbox_admin_model.dart';
// import 'package:poolmate/model/language_model.dart';
// import 'package:poolmate/model/notification_model.dart';
// import 'package:poolmate/model/on_boarding_model.dart';
// import 'package:poolmate/model/payment_method_model.dart';
// import 'package:poolmate/model/recent_search_model.dart';
// import 'package:poolmate/model/referral_model.dart';
// import 'package:poolmate/model/report_model.dart';
// import 'package:poolmate/model/review_model.dart';
// import 'package:poolmate/model/ride_alert_model.dart';
// import 'package:poolmate/model/map/geometry.dart';
// import 'package:poolmate/model/sos_model.dart';
// import 'package:poolmate/model/referral_edge_model.dart';
// import 'package:poolmate/model/referral_earning_model.dart';
// import 'package:poolmate/model/tax_model.dart';
// import 'package:poolmate/model/user_model.dart';
// import 'package:poolmate/model/user_verification_model.dart';
// import 'package:poolmate/model/vehicle_brand_model.dart';
// import 'package:poolmate/model/vehicle_information_model.dart';
// import 'package:poolmate/model/vehicle_model.dart';
// import 'package:poolmate/model/vehicle_type_model.dart';
// import 'package:poolmate/model/wallet_transaction_model.dart';
// import 'package:poolmate/model/withdraw_method_model.dart';
// import 'package:poolmate/model/withdraw_model.dart';
// import 'package:poolmate/themes/app_them_data.dart';
// import 'package:poolmate/utils/preferences.dart';

// class FireStoreUtils {
//   static FirebaseFirestore fireStore = FirebaseFirestore.instance;

//   /// Get current user ID from local storage
//   static String getCurrentUid() {
//     // First try to get from local storage (for WhatsApp auth users)
//     String localUid = Preferences.getString(Preferences.currentUserIdKey);
//     if (localUid.isNotEmpty) {
//       return localUid;
//     }
//     // Fallback to Firebase Auth (for Google/Apple sign-in users)
//     if (FirebaseAuth.instance.currentUser != null) {
//       return FirebaseAuth.instance.currentUser!.uid;
//     }
//     return '';
//   }

//   /// Save current user ID to local storage
//   static Future<void> setCurrentUid(String uid) async {
//     await Preferences.setString(Preferences.currentUserIdKey, uid);
//   }

//   /// Clear current user ID from local storage (for logout)
//   static Future<void> clearCurrentUid() async {
//     await Preferences.clearKeyData(Preferences.currentUserIdKey);
//   }

//   static Future<bool> isLogin() async {
//     bool isLogin = false;
//     String currentUid = getCurrentUid();
//     if (currentUid.isNotEmpty) {
//       isLogin = await userExistOrNot(currentUid);
//     } else {
//       isLogin = false;
//     }
//     return isLogin;
//   }

//   static Future<bool> userExistOrNot(String uid) async {
//     bool isExist = false;

//     await fireStore.collection(CollectionName.users).doc(uid).get().then(
//       (value) {
//         if (value.exists) {
//           isExist = true;
//         } else {
//           isExist = false;
//         }
//       },
//     ).catchError((error) {
//       log("Failed to check user exist: $error");
//       isExist = false;
//     });
//     return isExist;
//   }

//   /// Check if a user exists by phone number
//   static Future<bool> userExistByPhoneNumber(
//       String countryCode, String phoneNumber) async {
//     bool isExist = false;
//     try {
//       final querySnapshot = await fireStore
//           .collection(CollectionName.users)
//           .where('countryCode', isEqualTo: countryCode)
//           .where('phoneNumber', isEqualTo: phoneNumber)
//           .limit(1)
//           .get();

//       isExist = querySnapshot.docs.isNotEmpty;
//     } catch (error) {
//       log("Failed to check user exist by phone: $error");
//       isExist = false;
//     }
//     return isExist;
//   }

//   /// Get user profile by phone number
//   static Future<UserModel?> getUserByPhoneNumber(
//       String countryCode, String phoneNumber) async {
//     UserModel? userModel;
//     try {
//       final querySnapshot = await fireStore
//           .collection(CollectionName.users)
//           .where('countryCode', isEqualTo: countryCode)
//           .where('phoneNumber', isEqualTo: phoneNumber)
//           .limit(1)
//           .get();

//       if (querySnapshot.docs.isNotEmpty) {
//         userModel = UserModel.fromJson(querySnapshot.docs.first.data());
//       }
//     } catch (error) {
//       log("Failed to get user by phone: $error");
//       userModel = null;
//     }
//     return userModel;
//   }

//   static Future<List<OnBoardingModel>> getOnBoardingList() async {
//     List<OnBoardingModel> onBoardingModel = [];
//     await fireStore.collection(CollectionName.onBoarding).get().then((value) {
//       for (var element in value.docs) {
//         OnBoardingModel documentModel =
//             OnBoardingModel.fromJson(element.data());
//         onBoardingModel.add(documentModel);
//       }
//     }).catchError((error) {
//       log(error.toString());
//     });
//     return onBoardingModel;
//   }

//   Future<List<TaxModel>?> getTaxList() async {
//     List<TaxModel> taxList = [];

//     await fireStore
//         .collection(CollectionName.tax)
//         .where('country', isEqualTo: Constant.country)
//         .where('enable', isEqualTo: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         TaxModel taxModel = TaxModel.fromJson(element.data());
//         taxList.add(taxModel);
//       }
//     }).catchError((error) {
//       log(error.toString());
//     });
//     return taxList;
//   }

//   static Future<bool?> checkReferralCodeValidOrNot(String referralCode) async {
//     bool? isExit;
//     try {
//       await fireStore
//           .collection(CollectionName.referral)
//           .where("referralCode", isEqualTo: referralCode)
//           .get()
//           .then((value) {
//         if (value.size > 0) {
//           isExit = true;
//         } else {
//           isExit = false;
//         }
//       });
//     } catch (e, s) {
//       log('FireStoreUtils.firebaseCreateNewUser $e $s');
//       return false;
//     }
//     return isExit;
//   }

//   static Future<ReferralModel?> getReferralUserByCode(
//       String referralCode) async {
//     ReferralModel? referralModel;
//     try {
//       await fireStore
//           .collection(CollectionName.referral)
//           .where("referralCode", isEqualTo: referralCode)
//           .get()
//           .then((value) {
//         referralModel = ReferralModel.fromJson(value.docs.first.data());
//       });
//     } catch (e, s) {
//       log('FireStoreUtils.firebaseCreateNewUser $e $s');
//       return null;
//     }
//     return referralModel;
//   }

//   static Future<String?> referralAdd(ReferralModel ratingModel) async {
//     try {
//       await fireStore
//           .collection(CollectionName.referral)
//           .doc(ratingModel.id)
//           .set(ratingModel.toJson());
//     } catch (e, s) {
//       log('FireStoreUtils.firebaseCreateNewUser $e $s');
//       return null;
//     }
//     return null;
//   }

//   /// Build a readable referral code from the user's name and ensure uniqueness.
//   static Future<String> generateReferralCodeFromName(
//       {String? firstName, String? lastName}) async {
//     String base = "PM";
//     final combined = "${firstName ?? ''}${lastName ?? ''}".replaceAll(' ', '');
//     if (combined.isNotEmpty) {
//       base = combined.toUpperCase();
//       if (base.length > 5) {
//         base = base.substring(0, 5);
//       }
//     }
//     // Append random digits until unique
//     String attempt = base;
//     bool unique = false;
//     int guard = 0;
//     while (!unique && guard < 8) {
//       final suffix = (math.Random().nextInt(9000) + 1000).toString();
//       attempt = "$base$suffix";
//       unique = await _isReferralCodeUnique(attempt);
//       guard++;
//     }
//     return attempt;
//   }

//   static Future<bool> _isReferralCodeUnique(String code) async {
//     final userSnap = await fireStore
//         .collection(CollectionName.users)
//         .where('referralCode', isEqualTo: code)
//         .limit(1)
//         .get();
//     if (userSnap.docs.isNotEmpty) return false;
//     final edgeSnap = await fireStore
//         .collection(CollectionName.referral)
//         .where('referralCode', isEqualTo: code)
//         .limit(1)
//         .get();
//     return edgeSnap.docs.isEmpty;
//   }

//   /// Ensure the user has a referral code set; returns the current or newly generated code.
//   static Future<String> ensureUserReferralCode(UserModel userModel) async {
//     if (userModel.referralCode != null && userModel.referralCode!.isNotEmpty) {
//       return userModel.referralCode!;
//     }
//     final generated = await generateReferralCodeFromName(
//         firstName: userModel.firstName, lastName: userModel.lastName);
//     userModel.referralCode = generated;
//     await updateUser(userModel);
//     return generated;
//   }

//   /// Apply a referral code during signup/onboarding.
//   /// Creates an edge (referrer -> referred user) and sets `referredBy` on the new user.
//   static Future<bool> applyReferralCodeToUser({
//     required String referralCode,
//     required UserModel newUser,
//   }) async {
//     if (referralCode.isEmpty || newUser.id == null) return false;

//     // Find referrer by referralCode on users collection
//     final referrerSnap = await fireStore
//         .collection(CollectionName.users)
//         .where('referralCode', isEqualTo: referralCode)
//         .limit(1)
//         .get();

//     if (referrerSnap.docs.isEmpty) {
//       return false;
//     }

//     final referrer = UserModel.fromJson(referrerSnap.docs.first.data());
//     if (referrer.id == newUser.id) {
//       // Prevent self-referral
//       return false;
//     }

//     newUser.referredBy = referrer.id;
//     await updateUser(newUser);

//     await createOrUpdateReferralEdge(
//       referrerId: referrer.id!,
//       referredUserId: newUser.id!,
//       referralCode: referralCode,
//     );

//     // Immediately add to appropriate task list upon signup
//     await _assignToTaskList(
//       referrer: referrer,
//       referredUserId: newUser.id!,
//     );

//     return true;
//   }

//   static Future<ReferralEdgeModel?> getReferralEdgeByReferred(
//       String referredUserId) async {
//     try {
//       final doc = await fireStore
//           .collection(CollectionName.referral)
//           .doc(referredUserId)
//           .get();
//       if (!doc.exists) return null;
//       return ReferralEdgeModel.fromJson(doc.data()!);
//     } catch (e) {
//       log('getReferralEdgeByReferred error: $e');
//       return null;
//     }
//   }

//   static Future<ReferralEdgeModel> createOrUpdateReferralEdge({
//     required String referrerId,
//     required String referredUserId,
//     required String referralCode,
//   }) async {
//     final edge = ReferralEdgeModel(
//       id: referredUserId,
//       referrerId: referrerId,
//       referredUserId: referredUserId,
//       referralCodeUsed: referralCode,
//       createdAt: Timestamp.now(),
//       rideCount: 0,
//       firstRideRewardGiven: false,
//       totalEarnedFromUser: '0',
//     );
//     await fireStore
//         .collection(CollectionName.referral)
//         .doc(referredUserId)
//         .set(edge.toJson(), SetOptions(merge: true));
//     return edge;
//   }

//   static Future<ReferralEarningModel?> getReferralEarningById(String id) async {
//     final doc = await fireStore
//         .collection(CollectionName.referralEarnings)
//         .doc(id)
//         .get();
//     if (!doc.exists) return null;
//     return ReferralEarningModel.fromJson(doc.data()!);
//   }

//   static Future<void> processReferralOnRideCompleted({
//     required BookingModel bookingModel,
//     required List<BookedUserModel> bookedUsers,
//   }) async {
//     for (final rider in bookedUsers) {
//       final riderId = rider.id;
//       if (riderId == null) continue;

//       ReferralEdgeModel? edge = await getReferralEdgeByReferred(riderId);

//       if (edge == null) {
//         // Try to infer from rider profile
//         final riderProfile = await getUserProfile(riderId);
//         final referrerId = riderProfile?.referredBy;
//         if (referrerId == null || referrerId.isEmpty) continue;
//         final referralCode = riderProfile?.referralCode ?? '';
//         edge = await createOrUpdateReferralEdge(
//           referrerId: referrerId,
//           referredUserId: riderId,
//           referralCode: referralCode,
//         );
//       }

//       if (edge.referrerId == null) continue;
//       final referrer = await getUserProfile(edge.referrerId!);
//       if (referrer == null) continue;

//       // Increment ride count for this referred user
//       final rideCount = (edge.rideCount ?? 0) + 1;
//       edge.rideCount = rideCount;
//       edge.lastBookingId = bookingModel.id;
//       edge.firstRideRewardGiven = edge.firstRideRewardGiven ?? false;

//       double rideAmount = double.tryParse(rider.subTotal ?? '0') ?? 0;
//       double rateToApply = 0;
//       bool shouldCredit = false;
//       String earningNote = '';

//       // Stage-based commission logic
//       final currentStage = referrer.referralStage ?? 1;
//       referrer.task1Refs ??= [];

//       if (currentStage >= 3) {
//         // Stage 3: 3% on all rides
//         rateToApply = 0.03;
//         shouldCredit = rideAmount > 0;
//         earningNote = 'Referral 3% commission';
//       } else if (rideCount == 1 &&
//           referrer.task1Refs!.isNotEmpty &&
//           referrer.task1Refs!.first == riderId) {
//         // Task 1 only: 1% on first ride of the FIRST referred user only
//         rateToApply = 0.01;
//         shouldCredit = rideAmount > 0;
//         edge.firstRideRewardGiven = true;
//         earningNote = 'Referral 1% first ride';
//       }

//       double earningAmount = 0;
//       if (shouldCredit && rateToApply > 0) {
//         earningAmount = rideAmount * rateToApply;
//         final earningId = "${bookingModel.id}_${riderId}_$rideCount";
//         final existing = await fireStore
//             .collection(CollectionName.referralEarnings)
//             .doc(earningId)
//             .get();
//         if (!existing.exists) {
//           ReferralEarningModel earning = ReferralEarningModel(
//             id: earningId,
//             referrerId: edge.referrerId,
//             referredUserId: riderId,
//             bookingId: bookingModel.id,
//             amount: earningAmount.toStringAsFixed(2),
//             rate: rateToApply,
//             rideNumberForUser: rideCount,
//             status: 'credited',
//             note: earningNote,
//             createdAt: Timestamp.now(),
//           );
//           await fireStore
//               .collection(CollectionName.referralEarnings)
//               .doc(earningId)
//               .set(earning.toJson());

//           WalletTransactionModel transactionModel = WalletTransactionModel(
//               id: Constant.getUuid(),
//               amount: earningAmount.toStringAsFixed(2),
//               createdDate: Timestamp.now(),
//               paymentType: "Referral",
//               transactionId: bookingModel.id,
//               isCredit: true,
//               type: 'customer',
//               userId: referrer.id,
//               note: earningNote);

//           await setWalletTransaction(transactionModel);

//           // Update wallet balance
//           final walletUpdated = await updateOtherUserWallet(
//               amount: earningAmount.toStringAsFixed(2), id: referrer.id!);
//           log('Referral commission wallet update: $walletUpdated for amount: ${earningAmount.toStringAsFixed(2)}');

//           edge.totalEarnedFromUser =
//               ((double.tryParse(edge.totalEarnedFromUser ?? '0') ?? 0) +
//                       earningAmount)
//                   .toStringAsFixed(2);

//           double totalEarned =
//               double.tryParse(referrer.referralEarningsTotal ?? '0') ?? 0;
//           referrer.referralEarningsTotal =
//               (totalEarned + earningAmount).toStringAsFixed(2);

//           // Save referrer updates including new total earnings to Firebase
//           await updateUser(referrer);
//         }
//       }

//       await _updateReferralProgress(
//         referrer: referrer,
//         referredUserId: riderId,
//         isFirstRideCompleted: rideCount == 1,
//       );

//       await fireStore
//           .collection(CollectionName.referral)
//           .doc(riderId)
//           .set(edge.toJson(), SetOptions(merge: true));
//     }
//   }

//   static Future<void> _updateReferralProgress({
//     required UserModel referrer,
//     required String referredUserId,
//     required bool isFirstRideCompleted,
//   }) async {
//     referrer.referralStage ??= 1;
//     referrer.commissionRate ??= '0.01';
//     referrer.task1Refs ??= [];
//     referrer.task2Refs ??= [];
//     referrer.task3Refs ??= [];

//     bool shouldSetStage3 = false;

//     if (isFirstRideCompleted) {
//       // Mark Task 1 as completed only when the first referred user's first ride completes
//       if (referrer.task1Refs!.isNotEmpty &&
//           referrer.task1Refs!.first == referredUserId) {
//         referrer.referralStage = 2; // advance stage after first ride completion
//       }
//       // Only give Task 2 bonus when all 5 users have completed their first ride
//       if (referrer.task2Refs!.length == 4 && referrer.task2BonusGiven != true) {
//         // Count how many of the 5 Task 2 users have completed at least 1 ride
//         int completedRides = 0;
//         for (String userId in referrer.task2Refs!) {
//           final edge = await getReferralEdgeByReferred(userId);
//           if (edge != null && (edge.rideCount ?? 0) >= 1) {
//             completedRides++;
//           }
//         }

//         // Give bonus only when all 5 have completed their first ride
//         if (completedRides == 5) {
//           await _creditReferralBonus(
//             referrerId: referrer.id!,
//             amount: 100,
//             note: 'Referral Task 2 bonus',
//           );
//           referrer.task2BonusGiven = true;
//         }
//       }

//       if (referrer.task2Refs!.length >= 5 && referrer.task3Refs!.length >= 8) {
//         shouldSetStage3 = true;
//       }
//     }

//     if (shouldSetStage3) {
//       referrer.referralStage = 3;
//       referrer.commissionRate = '0.03';
//     }

//     await updateUser(referrer);
//   }

//   /// Assign a new referred user to the appropriate task list immediately upon signup
//   static Future<void> _assignToTaskList({
//     required UserModel referrer,
//     required String referredUserId,
//   }) async {
//     referrer.referralStage ??= 1;
//     referrer.task1Refs ??= [];
//     referrer.task2Refs ??= [];
//     referrer.task3Refs ??= [];

//     // Task 1: ONLY the first referred user
//     if (referrer.task1Refs!.isEmpty &&
//         !referrer.task1Refs!.contains(referredUserId)) {
//       referrer.task1Refs!.add(referredUserId);
//     }
//     // Task 2: NEXT 5 referred users (not including task 1 user)
//     else if (referrer.task1Refs!.isNotEmpty &&
//         referrer.task2Refs!.length < 5 &&
//         !referrer.task1Refs!.contains(referredUserId) &&
//         !referrer.task2Refs!.contains(referredUserId)) {
//       referrer.task2Refs!.add(referredUserId);
//     }
//     // Task 3: additional 8 users AFTER task 1 and task 2
//     else if (referrer.task2Refs!.length >= 5 &&
//         referrer.task3Refs!.length < 8 &&
//         !referrer.task1Refs!.contains(referredUserId) &&
//         !referrer.task2Refs!.contains(referredUserId) &&
//         !referrer.task3Refs!.contains(referredUserId)) {
//       referrer.task3Refs!.add(referredUserId);
//     }

//     await updateUser(referrer);
//   }

//   static Future<void> _creditReferralBonus({
//     required String referrerId,
//     required double amount,
//     required String note,
//   }) async {
//     log('🎉 _creditReferralBonus called: referrerId=$referrerId, amount=$amount, note=$note');

//     final amountStr = amount.toStringAsFixed(2);

//     WalletTransactionModel transactionModel = WalletTransactionModel(
//         id: Constant.getUuid(),
//         amount: amountStr,
//         createdDate: Timestamp.now(),
//         paymentType: "Referral",
//         transactionId: "referral_task_bonus",
//         isCredit: true,
//         type: 'customer',
//         userId: referrerId,
//         note: note);

//     log('💳 Creating wallet transaction: ${transactionModel.id}, amount: $amountStr');
//     await setWalletTransaction(transactionModel);
//     log('✅ Wallet transaction created successfully');

//     log('💰 Updating wallet balance for user: $referrerId with amount: $amountStr');
//     await updateOtherUserWallet(amount: amountStr, id: referrerId);
//     log('✅ Wallet balance updated successfully');

//     final referrer = await getUserProfile(referrerId);
//     if (referrer != null) {
//       log('👤 Fetched referrer profile: ${referrer.firstName} ${referrer.lastName}');
//       double totalEarned =
//           double.tryParse(referrer.referralEarningsTotal ?? '0') ?? 0;
//       log('📊 Previous total earned: $totalEarned, New total earned: ${totalEarned + amount}');
//       referrer.referralEarningsTotal =
//           (totalEarned + amount).toStringAsFixed(2);
//       log('📝 Updating referrer total earned to: ${referrer.referralEarningsTotal}');
//       await updateUser(referrer);
//       log('✅ Referrer profile updated successfully');
//     } else {
//       log('❌ ERROR: Could not fetch referrer profile for $referrerId');
//     }

//     log('🎊 Task 2 Bonus (₹$amountStr) credited successfully to $referrerId');
//   }

//   static Future<bool> updateUser(UserModel userModel) async {
//     bool isUpdate = false;
//     await fireStore
//         .collection(CollectionName.users)
//         .doc(userModel.id)
//         .set(userModel.toJson(), SetOptions(merge: true))
//         .whenComplete(() {
//       isUpdate = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isUpdate = false;
//     });
//     return isUpdate;
//   }

//   // New function to update specific verification status
//   static Future<bool> updateUserVerificationStatus({
//     required String userId,
//     required String documentType,
//     required bool isVerified,
//   }) async {
//     bool isUpdate = false;

//     try {
//       // First get the current user data
//       UserModel? currentUser = await getUserProfile(userId);
//       if (currentUser == null) return false;

//       // Determine which verification field to update based on document type
//       bool isAadhaarDoc = documentType.toLowerCase().contains('aadhaar') ||
//           documentType.toLowerCase().contains('aadhar');
//       Map<String, dynamic> updateData = {};

//       if (isAadhaarDoc) {
//         // Update passenger verification for Aadhaar
//         currentUser.aadharVerified = isVerified;
//         updateData['aadharVerified'] = isVerified;
//         log("Updating aadharVerified to $isVerified for document: $documentType");
//       }
//       // else if (isRCDoc) {
//       //   // Update driver verification for RC
//       //   currentUser.verifiedAsDriver = isVerified;
//       //   updateData['verifiedAsDriver'] = isVerified;
//       //   log("Updating verifiedAsDriver to $isVerified for document: $documentType");
//       // }

//       // Update overall verification status (keep existing logic for backward compatibility)
//       bool overallVerified = (currentUser.aadharVerified == true) &&
//           (currentUser.panVerified == true);
//       currentUser.isVerify = overallVerified;
//       updateData['isVerify'] = overallVerified;

//       // Update the user document in Firebase
//       await fireStore
//           .collection(CollectionName.users)
//           .doc(userId)
//           .update(updateData)
//           .then((_) {
//         isUpdate = true;
//         log("Successfully updated verification status for user $userId");
//       }).catchError((error) {
//         log("Failed to update verification status: $error");
//         isUpdate = false;
//       });
//     } catch (error) {
//       log("Error in updateUserVerificationStatus: $error");
//       isUpdate = false;
//     }

//     return isUpdate;
//   }

//   static Future<UserModel?> getUserProfile(String uuid) async {
//     print(uuid);
//     UserModel? userModel;
//     await fireStore
//         .collection(CollectionName.users)
//         .doc(uuid)
//         .get()
//         .then((value) {
//       if (value.exists) {
//         userModel = UserModel.fromJson(value.data()!);
//       }
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       userModel = null;
//     });
//     return userModel;
//   }

//   Future<CurrencyModel?> getCurrency() async {
//     CurrencyModel? currencyModel;
//     await fireStore
//         .collection(CollectionName.currency)
//         .where("enable", isEqualTo: true)
//         .get()
//         .then((value) {
//       if (value.docs.isNotEmpty) {
//         currencyModel = CurrencyModel.fromJson(value.docs.first.data());
//       }
//     });
//     return currencyModel;
//   }

//   static Future<List<LanguageModel>?> getLanguage() async {
//     List<LanguageModel> languageList = [];

//     await fireStore
//         .collection(CollectionName.languages)
//         .where("enable", isEqualTo: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         LanguageModel taxModel = LanguageModel.fromJson(element.data());
//         languageList.add(taxModel);
//       }
//     }).catchError((error) {
//       log(error.toString());
//     });
//     return languageList;
//   }

//   static Future<List<ReviewModel>?> getRating(String reviewReceivedId) async {
//     List<ReviewModel> taxList = [];

//     await fireStore
//         .collection(CollectionName.review)
//         .where('receiver_id', isEqualTo: reviewReceivedId)
//         .orderBy("date", descending: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         ReviewModel taxModel = ReviewModel.fromJson(element.data());
//         taxList.add(taxModel);
//       }
//     }).catchError((error) {
//       log(error.toString());
//     });
//     return taxList;
//   }

//   static Future<bool?> deleteUser() async {
//     bool? isDelete;
//     try {
//       await fireStore
//           .collection(CollectionName.users)
//           .doc(FireStoreUtils.getCurrentUid())
//           .delete();

//       // delete user  from firebase auth
//       await FirebaseAuth.instance.currentUser!.delete().then((value) {
//         isDelete = true;
//       });
//     } catch (e, s) {
//       log('FireStoreUtils.firebaseCreateNewUser $e $s');
//       return false;
//     }
//     return isDelete;
//   }

//   getSettings() async {
//     await fireStore
//         .collection(CollectionName.settings)
//         .doc("global")
//         .get()
//         .then((value) {
//       if (value.exists) {
//         Constant.termsAndConditions = value.data()!["termsAndConditions"];
//         Constant.privacyPolicy = value.data()!["privacyPolicy"];
//         Constant.appBannerImageDark = value.data()!["appBannerImageDark"];
//         Constant.appBannerImageLight = value.data()!["appBannerImageLight"];
//         Constant.globalUrl = value.data()!["globalUrl"];
//         AppThemeData.primary300 = Color(
//             int.parse(value.data()!["appColor"].replaceFirst("#", "0xff")));
//       }
//     });

//     await fireStore
//         .collection(CollectionName.settings)
//         .doc("adminCommission")
//         .get()
//         .then((value) {
//       if (value.data() != null) {
//         Constant.adminCommission = AdminCommission.fromJson(value.data()!);
//       }
//     });

//     fireStore
//         .collection(CollectionName.settings)
//         .doc("globalKey")
//         .snapshots()
//         .listen((event) {
//       if (event.exists) {
//         Constant.mapAPIKey = event.data()!["googleMapKey"];
//         Constant.distanceType = event.data()!["distanceType"];
//       }
//     });

//     fireStore
//         .collection(CollectionName.settings)
//         .doc("globalValue")
//         .snapshots()
//         .listen((event) {
//       if (event.exists) {
//         Constant.priceVariation = event.data()!["priceVariation"];
//         Constant.radius = event.data()!["radius"];
//         Constant.intervalHoursForPublishNewRide =
//             event.data()!['intervalHoursForPublishNewRide'];
//         Constant.minimumAmountToDeposit =
//             event.data()!["minimumAmountToDeposit"];
//         Constant.minimumAmountToWithdrawal =
//             event.data()!["minimumAmountToWithdrawal"];
//         Constant.verifyBooking = event.data()!["verifyBooking"];
//         Constant.verifyPublish = event.data()!["verifyPublish"];
//       }
//     });

//     fireStore
//         .collection(CollectionName.settings)
//         .doc("notification_settings")
//         .get()
//         .then((value) {
//       if (value.exists) {
//         Constant.senderId = value.data()!["senderId"];
//         Constant.jsonNotificationFileURL = value.data()!["serviceJson"];
//       }
//     });

//     await fireStore
//         .collection(CollectionName.settings)
//         .doc("referral")
//         .get()
//         .then((value) {
//       if (value.exists) {
//         Constant.referralAmount = value.data()!["referralAmount"];
//       }
//     });

//     await fireStore
//         .collection(CollectionName.settings)
//         .doc("contact_us")
//         .get()
//         .then((value) {
//       if (value.exists) {
//         Constant.supportURL = value.data()!["supportURL"];
//       }
//     });
//   }

//   Future<PaymentModel?> getPayment() async {
//     PaymentModel? paymentModel;
//     await fireStore
//         .collection(CollectionName.settings)
//         .doc("payment")
//         .get()
//         .then((value) {
//       paymentModel = PaymentModel.fromJson(value.data()!);
//     });
//     return paymentModel;
//   }

//   static Future<bool?> updateUserWallet({required String amount}) async {
//     bool isAdded = false;
//     await getUserProfile(FireStoreUtils.getCurrentUid()).then((value) async {
//       if (value != null) {
//         UserModel userModel = value;
//         userModel.walletAmount =
//             (double.parse(userModel.walletAmount.toString()) +
//                     double.parse(amount))
//                 .toString();
//         await FireStoreUtils.updateUser(userModel).then((value) {
//           isAdded = value;
//         });
//       }
//     });
//     return isAdded;
//   }

//   // Method to safely deduct money from user's wallet with balance validation
//   static Future<Map<String, dynamic>> deductFromUserWallet({
//     required String amount,
//     required String userId,
//     required String description,
//   }) async {
//     try {
//       double deductAmount = double.parse(amount);

//       // Get current user data
//       UserModel? userModel = await getUserProfile(userId);
//       if (userModel == null) {
//         return {
//           'success': false,
//           'message': 'User not found',
//           'code': 'USER_NOT_FOUND'
//         };
//       }

//       // Check current wallet balance
//       double currentBalance = double.parse(userModel.walletAmount ?? '0');

//       if (currentBalance < deductAmount) {
//         return {
//           'success': false,
//           'message':
//               'Insufficient wallet balance. Available: ${currentBalance.toStringAsFixed(2)}',
//           'code': 'INSUFFICIENT_BALANCE',
//           'availableBalance': currentBalance
//         };
//       }

//       // Calculate new balance
//       double newBalance = currentBalance - deductAmount;
//       userModel.walletAmount = newBalance.toString();

//       // Update user wallet
//       bool isUpdated = await updateUser(userModel);

//       if (isUpdated) {
//         // Create debit transaction record
//         WalletTransactionModel transactionModel = WalletTransactionModel(
//             id: Constant.getUuid(),
//             amount: amount,
//             createdDate: Timestamp.now(),
//             paymentType: 'Wallet',
//             transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
//             userId: userId,
//             isCredit: false, // Debit transaction
//             note: description,
//             type: 'customer');

//         await setWalletTransaction(transactionModel);

//         return {
//           'success': true,
//           'message': 'Payment processed successfully',
//           'code': 'PAYMENT_SUCCESS',
//           'newBalance': newBalance,
//           'transactionId': transactionModel.transactionId
//         };
//       } else {
//         return {
//           'success': false,
//           'message': 'Failed to update wallet balance',
//           'code': 'UPDATE_FAILED'
//         };
//       }
//     } catch (e) {
//       return {
//         'success': false,
//         'message': 'Payment processing error: $e',
//         'code': 'PROCESSING_ERROR'
//       };
//     }
//   }

//   // Method to add money to driver's wallet after commission calculation
//   static Future<Map<String, dynamic>> addToDriverWallet({
//     required String amount,
//     required String driverId,
//     required String bookingId,
//     required String description,
//   }) async {
//     try {
//       double addAmount = double.parse(amount);

//       // Get current driver data
//       UserModel? driverModel = await getUserProfile(driverId);
//       if (driverModel == null) {
//         return {
//           'success': false,
//           'message': 'Driver not found',
//           'code': 'DRIVER_NOT_FOUND'
//         };
//       }

//       // Calculate new balance
//       double currentBalance = double.parse(driverModel.walletAmount ?? '0');
//       double newBalance = currentBalance + addAmount;
//       driverModel.walletAmount = newBalance.toString();

//       // Update driver wallet
//       bool isUpdated = await updateUser(driverModel);

//       if (isUpdated) {
//         // Create credit transaction record for driver
//         WalletTransactionModel transactionModel = WalletTransactionModel(
//             id: Constant.getUuid(),
//             amount: amount,
//             createdDate: Timestamp.now(),
//             paymentType: 'Ride Payment',
//             transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
//             userId: driverId,
//             isCredit: true, // Credit transaction
//             note: description,
//             type: 'customer');

//         await setWalletTransaction(transactionModel);

//         return {
//           'success': true,
//           'message': 'Payment transferred to driver successfully',
//           'code': 'TRANSFER_SUCCESS',
//           'newBalance': newBalance,
//           'transactionId': transactionModel.transactionId
//         };
//       } else {
//         return {
//           'success': false,
//           'message': 'Failed to update driver wallet balance',
//           'code': 'UPDATE_FAILED'
//         };
//       }
//     } catch (e) {
//       return {
//         'success': false,
//         'message': 'Driver payment transfer error: $e',
//         'code': 'TRANSFER_ERROR'
//       };
//     }
//   }

//   // Method to record admin commission earnings
//   static Future<Map<String, dynamic>> recordAdminCommission({
//     required String amount,
//     required String bookingId,
//     required String description,
//     required String passengerId,
//     required String driverId,
//   }) async {
//     try {
//       // Create admin earnings record
//       Map<String, dynamic> adminEarningsData = {
//         'id': Constant.getUuid(),
//         'amount': amount,
//         'bookingId': bookingId,
//         'description': description,
//         'passengerId': passengerId,
//         'driverId': driverId,
//         'createdAt': Timestamp.now(),
//         'type': 'commission',
//         'status': 'earned',
//       };

//       await fireStore
//           .collection('admin_earnings')
//           .doc(adminEarningsData['id'])
//           .set(adminEarningsData);

//       return {
//         'success': true,
//         'message': 'Admin commission recorded successfully',
//         'code': 'COMMISSION_RECORDED'
//       };
//     } catch (e) {
//       return {
//         'success': false,
//         'message': 'Failed to record admin commission: $e',
//         'code': 'COMMISSION_ERROR'
//       };
//     }
//   }

//   static Future<bool?> updateOtherUserWallet(
//       {required String amount, required String id}) async {
//     bool isAdded = false;
//     try {
//       await getUserProfile(id).then((value) async {
//         if (value != null) {
//           UserModel userModel = value;
//           double currentWallet =
//               double.tryParse(userModel.walletAmount?.toString() ?? '0') ?? 0;
//           double amountToAdd = double.tryParse(amount) ?? 0;
//           userModel.walletAmount =
//               (currentWallet + amountToAdd).toStringAsFixed(2);

//           log('Updating wallet for user $id: $currentWallet + $amountToAdd = ${userModel.walletAmount}');

//           await FireStoreUtils.updateUser(userModel).then((value) {
//             isAdded = value;
//             log('Wallet update result: $value');
//           });
//         } else {
//           log('User profile not found for id: $id');
//         }
//       });
//     } catch (e) {
//       log('Error updating wallet: $e');
//       isAdded = false;
//     }
//     return isAdded;
//   }

//   static Future<bool?> setSearchHistory(
//       RecentSearchModel recentSearchModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.userSearchHistory)
//         .doc(recentSearchModel.id)
//         .set(recentSearchModel.toJson())
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   static Future<List<RecentSearchModel>?> getSearchHistory() async {
//     List<RecentSearchModel> list = [];

//     await fireStore
//         .collection(CollectionName.userSearchHistory)
//         .where("userId", isEqualTo: getCurrentUid())
//         .orderBy('createdAt', descending: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         RecentSearchModel searchModel =
//             RecentSearchModel.fromJson(element.data());
//         list.add(searchModel);
//       }
//     }).catchError((error) {
//       log(error.toString());
//     });
//     return list;
//   }

//   static Future<List<VehicleBrandModel>?> getVehicleBrand() async {
//     List<VehicleBrandModel> list = [];

//     await fireStore
//         .collection(CollectionName.vehicleBrand)
//         .where("enable", isEqualTo: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         VehicleBrandModel searchModel =
//             VehicleBrandModel.fromJson(element.data());
//         list.add(searchModel);
//       }
//     }).catchError((error) {
//       log(error.toString());
//     });
//     return list;
//   }

//   static Future<List<VehicleModel>?> getVehicleModel(String brandId) async {
//     List<VehicleModel> list = [];

//     await fireStore
//         .collection(CollectionName.vehicleModel)
//         .where("brandId", isEqualTo: brandId)
//         .where("enable", isEqualTo: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         VehicleModel searchModel = VehicleModel.fromJson(element.data());
//         list.add(searchModel);
//       }
//     }).catchError((error) {
//       log(error.toString());
//     });
//     return list;
//   }

//   static Future<List<VehicleTypeModel>?> getVehicleType() async {
//     List<VehicleTypeModel> list = [];

//     await fireStore
//         .collection(CollectionName.vehicleType)
//         .where("enable", isEqualTo: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         VehicleTypeModel searchModel =
//             VehicleTypeModel.fromJson(element.data());
//         list.add(searchModel);
//       }
//     }).catchError((error) {
//       log(error.toString());
//     });
//     return list;
//   }

//   static Future<bool?> setUserVehicleInformation(
//       VehicleInformationModel informationModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.userVehicleInformation)
//         .doc(informationModel.id)
//         .set(informationModel.toJson())
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   static Future<bool?> deleteVehicleInformation(
//       VehicleInformationModel informationModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.userVehicleInformation)
//         .doc(informationModel.id)
//         .delete()
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   static Future<List<VehicleInformationModel>?>
//       getUserVehicleInformation() async {
//     List<VehicleInformationModel> list = [];

//     await fireStore
//         .collection(CollectionName.userVehicleInformation)
//         .where("userId", isEqualTo: getCurrentUid())
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         VehicleInformationModel searchModel =
//             VehicleInformationModel.fromJson(element.data());
//         list.add(searchModel);
//       }
//     }).catchError((error) {
//       log(error.toString());
//     });
//     return list;
//   }

//   static Future<bool?> setBooking(BookingModel bookingModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.booking)
//         .doc(bookingModel.id)
//         .set(bookingModel.toJson())
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   static Future<bool?> deleteBooking(BookingModel bookingModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.booking)
//         .doc(bookingModel.id)
//         .delete()
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   static Future<List<BookingModel>?> getPublishes() async {
//     List<BookingModel>? bookingList = [];
//     await fireStore
//         .collection(CollectionName.booking)
//         .where("createdBy", isEqualTo: FireStoreUtils.getCurrentUid())
//         .orderBy("createdAt", descending: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         BookingModel documentModel = BookingModel.fromJson(element.data());
//         bookingList.add(documentModel);
//       }
//     }).catchError((error) {
//       log("Failed to update user: $error");
//     });
//     return bookingList;
//   }

//   static Future<List<BookingModel>?> checkAtivePublishes() async {
//     List<BookingModel>? bookingList = [];

//     await fireStore
//         .collection(CollectionName.booking)
//         .where("createdBy", isEqualTo: FireStoreUtils.getCurrentUid())
//         .where("status", isNotEqualTo: Constant.completed)
//         .where('publish', isEqualTo: true)
//         .orderBy("createdAt", descending: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         log("BookingList :: ${element.id}");
//         BookingModel documentModel = BookingModel.fromJson(element.data());
//         bookingList.add(documentModel);
//       }
//     }).catchError((error) {
//       log("Failed to update user: $error");
//     });
//     return bookingList;
//   }

//   static Future<List<BookingModel>?> getMyBooking() async {
//     List<BookingModel>? bookingList = [];
//     await fireStore
//         .collection(CollectionName.booking)
//         .where("bookedUserId", arrayContains: FireStoreUtils.getCurrentUid())
//         .orderBy("createdAt", descending: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         BookingModel documentModel = BookingModel.fromJson(element.data());
//         bookingList.add(documentModel);
//       }
//     }).catchError((error) {
//       log("Failed to update user: $error");
//     });
//     return bookingList;
//   }

//   static Future<BookingModel?> getMyBookingNyUserId(String id) async {
//     BookingModel? bookingList;
//     await fireStore
//         .collection(CollectionName.booking)
//         .doc(id)
//         .get()
//         .then((value) {
//       if (value.exists) {
//         bookingList = BookingModel.fromJson(value.data()!);
//       }
//     }).catchError((error) {
//       log("Failed to update user: $error");
//     });
//     return bookingList;
//   }

//   static Future<BookedUserModel?> getMyBookingUser(
//       BookingModel bookingModel) async {
//     BookedUserModel? bookingUserModel;
//     String currentUserId = getCurrentUid();

//     try {
//       // First, try to get from bookedUser subcollection
//       await fireStore
//           .collection(CollectionName.booking)
//           .doc(bookingModel.id)
//           .collection("bookedUser")
//           .doc(currentUserId)
//           .get()
//           .then((value) {
//         if (value.exists) {
//           bookingUserModel = BookedUserModel.fromJson(value.data()!);
//           print(
//               "Found user in bookedUser subcollection for booking: ${bookingModel.id}");
//         }
//       }).catchError((error) {
//         print("Error checking bookedUser: $error");
//       });

//       // If not found in bookedUser, check cancelledUser subcollection
//       if (bookingUserModel == null) {
//         await fireStore
//             .collection(CollectionName.booking)
//             .doc(bookingModel.id)
//             .collection("cancelledUser")
//             .doc(currentUserId)
//             .get()
//             .then((value) {
//           if (value.exists) {
//             bookingUserModel = BookedUserModel.fromJson(value.data()!);
//             print(
//                 "Found user in cancelledUser subcollection for booking: ${bookingModel.id}");
//           }
//         }).catchError((error) {
//           print("Error checking cancelledUser: $error");
//         });
//       }

//       if (bookingUserModel == null) {
//         print(
//             "BookedUserModel not found for booking: ${bookingModel.id}, status: ${bookingModel.status}");
//       }
//     } catch (error) {
//       print("Error in getMyBookingUser: $error");
//     }

//     return bookingUserModel;
//   }

//   static Future<List<BookedUserModel>?> getMyBookingUserList(
//       BookingModel bookingModel) async {
//     List<BookedUserModel>? bookingList = [];
//     await fireStore
//         .collection(CollectionName.booking)
//         .doc(bookingModel.id)
//         .collection("bookedUser")
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         BookedUserModel documentModel =
//             BookedUserModel.fromJson(element.data());
//         bookingList.add(documentModel);
//       }
//     }).catchError((error) {
//       log("Failed to update user: $error");
//     });
//     return bookingList;
//   }

//   static Future<bool?> setUserBooking(
//       BookingModel bookingModel, BookedUserModel bookingUserModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.booking)
//         .doc(bookingModel.id)
//         .collection("bookedUser")
//         .doc(bookingUserModel.id)
//         .set(bookingUserModel.toJson())
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   static Future<bool?> removeUserBooking(
//       BookingModel bookingModel, BookedUserModel bookingUserModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.booking)
//         .doc(bookingModel.id)
//         .collection("bookedUser")
//         .doc(bookingUserModel.id)
//         .delete()
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   static Future<bool?> setCancelledUserBooking(
//       BookingModel bookingModel, BookedUserModel bookingUserModel) async {
//     bool isSuccess = false;

//     try {
//       await fireStore.runTransaction((transaction) async {
//         // Get references
//         final bookingRef =
//             fireStore.collection(CollectionName.booking).doc(bookingModel.id);
//         final cancelledUserRef =
//             bookingRef.collection("cancelledUser").doc(bookingUserModel.id);
//         final bookedUserRef =
//             bookingRef.collection("bookedUser").doc(bookingUserModel.id);

//         // Add to cancelled users
//         transaction.set(cancelledUserRef, bookingUserModel.toJson());

//         // Update main booking document
//         transaction.update(bookingRef, {
//           'bookedSeat': bookingModel.bookedSeat!
//               .replaceAll(bookingUserModel.bookedSeat.toString(), ""),
//           'selectedSeats': bookingModel.selectedSeats,
//           'bookedUserId': bookingModel.bookedUserId,
//           'cancelledUserId': bookingModel.cancelledUserId,
//           'seatBookings':
//               bookingModel.seatBookings?.map((e) => e.toJson()).toList()
//         });

//         // Remove from booked users
//         transaction.delete(bookedUserRef);
//       });

//       isSuccess = true;
//     } catch (error) {
//       print('Error in setCancelledUserBooking: $error');
//       isSuccess = false;
//     }

//     return isSuccess;
//   }

//   static Future<List<DocumentModel>> getDocumentList() async {
//     List<DocumentModel> documentList = [];
//     await fireStore
//         .collection(CollectionName.documents)
//         .where('enable', isEqualTo: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         DocumentModel documentModel = DocumentModel.fromJson(element.data());
//         documentList.add(documentModel);
//       }
//     }).catchError((error) {
//       log(error.toString());
//     });
//     return documentList;
//   }

//   static Future<UserVerificationModel?> getDocumentOfDriver() async {
//     UserVerificationModel? driverDocumentModel;
//     await fireStore
//         .collection(CollectionName.userVerification)
//         .doc(getCurrentUid())
//         .get()
//         .then((value) async {
//       if (value.exists) {
//         driverDocumentModel = UserVerificationModel.fromJson(value.data()!);
//       }
//     });
//     return driverDocumentModel;
//   }

//   static Future<bool> uploadDriverDocument(Documents documents) async {
//     bool isAdded = false;
//     UserVerificationModel driverDocumentModel = UserVerificationModel();
//     List<Documents> documentsList = [];
//     await fireStore
//         .collection(CollectionName.userVerification)
//         .doc(getCurrentUid())
//         .get()
//         .then((value) async {
//       if (value.exists) {
//         UserVerificationModel newDriverDocumentModel =
//             UserVerificationModel.fromJson(value.data()!);
//         documentsList = newDriverDocumentModel.documents!;
//         var contain = newDriverDocumentModel.documents!
//             .where((element) => element.documentId == documents.documentId);
//         if (contain.isEmpty) {
//           documentsList.add(documents);

//           driverDocumentModel.id = getCurrentUid();
//           driverDocumentModel.documents = documentsList;
//         } else {
//           var index = newDriverDocumentModel.documents!.indexWhere(
//               (element) => element.documentId == documents.documentId);

//           driverDocumentModel.id = getCurrentUid();
//           documentsList.removeAt(index);
//           documentsList.insert(index, documents);
//           driverDocumentModel.documents = documentsList;
//           isAdded = false;
//           ShowToastDialog.showToast("Document is under verification");
//         }
//       } else {
//         documentsList.add(documents);
//         driverDocumentModel.id = getCurrentUid();
//         driverDocumentModel.documents = documentsList;
//       }
//     });

//     await fireStore
//         .collection(CollectionName.userVerification)
//         .doc(getCurrentUid())
//         .set(driverDocumentModel.toJson())
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       isAdded = false;
//       log(error.toString());
//     });

//     return isAdded;
//   }

//   // Function to handle document approval and update verification status
//   static Future<bool> approveUserDocument({
//     required String userId,
//     required String documentId,
//     required String documentTitle,
//   }) async {
//     bool isSuccess = false;

//     try {
//       // Get the user verification data for the specific user
//       UserVerificationModel? userVerification;
//       await fireStore
//           .collection(CollectionName.userVerification)
//           .doc(userId)
//           .get()
//           .then((value) {
//         if (value.exists) {
//           userVerification = UserVerificationModel.fromJson(value.data()!);
//         }
//       });

//       if (userVerification != null && userVerification!.documents != null) {
//         List<Documents> documents = userVerification!.documents!;

//         // Find and update the specific document
//         var docIndex =
//             documents.indexWhere((doc) => doc.documentId == documentId);

//         if (docIndex >= 0) {
//           documents[docIndex].verified = true;
//           documents[docIndex].status = "approved";

//           // Create updated verification model
//           UserVerificationModel updatedVerification = UserVerificationModel(
//             documents: documents,
//             id: userVerification!.id,
//           );

//           // Update the user verification document
//           await fireStore
//               .collection(CollectionName.userVerification)
//               .doc(userId)
//               .set(updatedVerification.toJson());

//           // Update user verification status based on document type
//           await updateUserVerificationStatus(
//             userId: userId,
//             documentType: documentTitle,
//             isVerified: true,
//           );

//           isSuccess = true;
//           log("Document approved and verification status updated for user $userId");
//         }
//       }
//     } catch (error) {
//       log("Error in approveUserDocument: $error");
//       isSuccess = false;
//     }

//     return isSuccess;
//   }

//   // Function to handle KYC verification (Aadhaar via webview)
//   static Future<bool> updateKYCVerificationStatus(String userId) async {
//     try {
//       // Update user verification status for Aadhaar (passenger verification)
//       await updateUserVerificationStatus(
//         userId: userId,
//         documentType: "aadhaar", // This will trigger passenger verification
//         isVerified: true,
//       );

//       log("KYC verification status updated for user $userId");
//       return true;
//     } catch (error) {
//       log("Error updating KYC verification status: $error");
//       return false;
//     }
//   }

//   static Future<bool?> setWalletTransaction(
//       WalletTransactionModel walletTransactionModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.walletTransaction)
//         .doc(walletTransactionModel.id)
//         .set(walletTransactionModel.toJson())
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
//     List<WalletTransactionModel> walletTransactionModel = [];

//     await fireStore
//         .collection(CollectionName.walletTransaction)
//         .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
//         .orderBy('createdDate', descending: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         WalletTransactionModel taxModel =
//             WalletTransactionModel.fromJson(element.data());
//         walletTransactionModel.add(taxModel);
//       }
//     }).catchError((error) {
//       log(error.toString());
//     });
//     return walletTransactionModel;
//   }

//   static Future<bool?> setReport(ReportModel recentSearchModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.report)
//         .doc(recentSearchModel.id)
//         .set(recentSearchModel.toJson())
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   static Future<NotificationModel?> getNotificationContent(String type) async {
//     NotificationModel? notificationModel;
//     await fireStore
//         .collection(CollectionName.dynamicNotification)
//         .where('type', isEqualTo: type)
//         .get()
//         .then((value) {
//       print("------>");
//       if (value.docs.isNotEmpty) {
//         print(value.docs.first.data());
//         notificationModel = NotificationModel.fromJson(value.docs.first.data());
//       } else {
//         notificationModel = NotificationModel(
//             id: "",
//             message: "Notification setup is pending",
//             subject: "setup notification",
//             type: "");
//       }
//     });
//     return notificationModel;
//   }

//   static Future<ReviewModel?> getReview(
//       {required String bookingId, required String senderId}) async {
//     ReviewModel? reviewModel;
//     await fireStore
//         .collection(CollectionName.review)
//         .where('booking_id', isEqualTo: bookingId)
//         .where(
//           'sender_id',
//           isEqualTo: senderId,
//         )
//         .get()
//         .then((value) {
//       if (value.docs.isNotEmpty) {
//         reviewModel = ReviewModel.fromJson(value.docs.first.data());
//       }
//     });
//     return reviewModel;
//   }

//   static Future<ReviewModel?> getReviewByReceiverId(
//       {required String bookingId, required String receiverId}) async {
//     ReviewModel? reviewModel;
//     await fireStore
//         .collection(CollectionName.review)
//         .where('booking_id', isEqualTo: bookingId)
//         .where(
//           'receiver_id',
//           isEqualTo: receiverId,
//         )
//         .get()
//         .then((value) {
//       if (value.docs.isNotEmpty) {
//         reviewModel = ReviewModel.fromJson(value.docs.first.data());
//       }
//     });
//     return reviewModel;
//   }

//   static Future<bool?> setReview(ReviewModel reviewModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.review)
//         .doc(reviewModel.id)
//         .set(reviewModel.toJson())
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   static Future<WithdrawMethodModel?> getWithdrawMethod() async {
//     WithdrawMethodModel? withdrawMethodModel;
//     await fireStore
//         .collection(CollectionName.withdrawMethod)
//         .where("userId", isEqualTo: getCurrentUid())
//         .get()
//         .then((value) async {
//       if (value.docs.isNotEmpty) {
//         withdrawMethodModel =
//             WithdrawMethodModel.fromJson(value.docs.first.data());
//       }
//     });
//     return withdrawMethodModel;
//   }

//   static Future<WithdrawMethodModel?> setWithdrawMethod(
//       WithdrawMethodModel withdrawMethodModel) async {
//     if (withdrawMethodModel.id == null) {
//       withdrawMethodModel.id = Constant.getUuid();
//       withdrawMethodModel.userId = getCurrentUid();
//     }
//     await fireStore
//         .collection(CollectionName.withdrawMethod)
//         .doc(withdrawMethodModel.id)
//         .set(withdrawMethodModel.toJson())
//         .then((value) async {});
//     return withdrawMethodModel;
//   }

//   static Future<bool?> setWithdrawRequest(WithdrawModel withdrawModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.withdrawalHistory)
//         .doc(withdrawModel.id)
//         .set(withdrawModel.toJson())
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   static Future<List<WithdrawModel>?> getWithDrawRequest() async {
//     List<WithdrawModel> withdrawalList = [];
//     await fireStore
//         .collection(CollectionName.withdrawalHistory)
//         .where('userId', isEqualTo: getCurrentUid())
//         .orderBy('createdDate', descending: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         WithdrawModel documentModel = WithdrawModel.fromJson(element.data());
//         withdrawalList.add(documentModel);
//       }
//     }).catchError((error) {
//       log(error.toString());
//     });
//     return withdrawalList;
//   }

//   static Future<List<String>> getAdvertiseBannersData() async {
//     try {
//       final snapshot = await fireStore
//           .collection(CollectionName.settings)
//           .doc("AdvertiseBanners")
//           .get();
//       if (snapshot.exists) {
//         final banners = snapshot.data()?['banners'] as List<dynamic>?;
//         if (banners != null) {
//           final advertiseBannerModel =
//               banners.map((e) => e.toString()).toList();
//           return advertiseBannerModel;
//         }
//       }
//     } catch (error, stackTrace) {
//       log('Error fetching advertise banners: $error', stackTrace: stackTrace);
//     }
//     return [];
//   }

//   static late StreamSubscription<QuerySnapshot> adminChatSeenSubscription;
//   static void setSeen() {
//     final currentUserId = FireStoreUtils.getCurrentUid();

//     adminChatSeenSubscription = FirebaseFirestore.instance
//         .collection(CollectionName.adminChat)
//         .doc(currentUserId)
//         .collection("thread")
//         .where('senderId', isEqualTo: Constant.adminType)
//         .where('seen', isEqualTo: false)
//         .snapshots()
//         .listen((querySnapshot) async {
//       for (final doc in querySnapshot.docs) {
//         try {
//           await doc.reference.update({'seen': true});
//         } catch (e) {
//           log(e.toString());
//         }
//       }
//     }, onError: (error) {
//       log(error.toString());
//     });
//   }

//   static void stopSeenListener() {
//     adminChatSeenSubscription.cancel();
//   }

//   static Future addInAdminBox(InboxAdminModel inboxModel) async {
//     return await fireStore
//         .collection(CollectionName.adminChat)
//         .doc(FireStoreUtils.getCurrentUid())
//         .set(inboxModel.toJson())
//         .then((document) {
//       return inboxModel;
//     });
//   }

//   static Future addAdminChat(ConversationAdminModel conversationModel) async {
//     return await fireStore
//         .collection(CollectionName.adminChat)
//         .doc(conversationModel.senderId)
//         .collection("thread")
//         .doc(conversationModel.id)
//         .set(conversationModel.toJson())
//         .then((document) {
//       return conversationModel;
//     });
//   }

//   static Future<SosModel?> getSOS(
//       {required String bookingId,
//       required String driverId,
//       required String customerId}) async {
//     SosModel? sosModel;
//     try {
//       await fireStore
//           .collection(CollectionName.sos)
//           .where("bookingId", isEqualTo: bookingId)
//           .where("customerId", isEqualTo: customerId)
//           .where("driverId", isEqualTo: driverId)
//           .get()
//           .then((value) {
//         sosModel = SosModel.fromJson(value.docs.first.data());
//       });
//     } catch (e, s) {
//       log('FireStoreUtils.firebaseCreateNewUser $e $s');
//       return null;
//     }
//     return sosModel;
//   }

//   static Future<bool?> setSOS(SosModel sosModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.sos)
//         .doc(sosModel.id)
//         .set(sosModel.toJson())
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to update user: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   static Future<List<BookingModel>?> getCancelledBookings() async {
//     List<BookingModel>? bookingList = [];
//     await fireStore
//         .collection(CollectionName.booking)
//         .where("createdBy", isEqualTo: FireStoreUtils.getCurrentUid())
//         .where("status", isEqualTo: Constant.canceled)
//         .orderBy("createdAt", descending: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         BookingModel documentModel = BookingModel.fromJson(element.data());
//         bookingList.add(documentModel);
//       }
//     }).catchError((error) {
//       log("Failed to get cancelled bookings: $error");
//     });
//     return bookingList;
//   }

//   static Future<List<BookingModel>?> getCompletedBookings() async {
//     List<BookingModel>? bookingList = [];
//     await fireStore
//         .collection(CollectionName.booking)
//         .where("createdBy", isEqualTo: FireStoreUtils.getCurrentUid())
//         .where("status", isEqualTo: Constant.completed)
//         .orderBy("createdAt", descending: true)
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         BookingModel documentModel = BookingModel.fromJson(element.data());
//         bookingList.add(documentModel);
//       }
//     }).catchError((error) {
//       log("Failed to get completed bookings: $error");
//     });
//     return bookingList;
//   }

//   // Real-time stream methods for live data updates

//   static Stream<List<BookingModel>> getMyBookingStream() {
//     String currentUid = getCurrentUid();
//     return fireStore
//         .collection(CollectionName.booking)
//         .where("bookedUserId", arrayContains: currentUid)
//         .orderBy("createdAt", descending: true)
//         .snapshots()
//         .map((snapshot) {
//       List<BookingModel> bookingList = [];
//       for (var doc in snapshot.docs) {
//         BookingModel documentModel = BookingModel.fromJson(doc.data());
//         documentModel.id = doc.id;
//         bookingList.add(documentModel);
//       }
//       return bookingList;
//     });
//   }

//   static Stream<List<BookingModel>> getPublishesStream() {
//     String currentUid = getCurrentUid();
//     return fireStore
//         .collection(CollectionName.booking)
//         .where("createdBy", isEqualTo: currentUid)
//         .where("status", whereNotIn: [Constant.completed, Constant.canceled])
//         .orderBy("createdAt", descending: true)
//         .snapshots()
//         .map((snapshot) {
//           List<BookingModel> bookingList = [];
//           for (var doc in snapshot.docs) {
//             BookingModel documentModel = BookingModel.fromJson(doc.data());
//             documentModel.id = doc.id;
//             bookingList.add(documentModel);
//           }
//           return bookingList;
//         });
//   }

//   static Stream<List<BookingModel>> getCancelledBookingsStream() {
//     String currentUid = getCurrentUid();

//     // Driver cancelled bookings
//     Stream<List<BookingModel>> driverStream = fireStore
//         .collection(CollectionName.booking)
//         .where("createdBy", isEqualTo: currentUid)
//         .where("status", isEqualTo: Constant.canceled)
//         .orderBy("createdAt", descending: true)
//         .snapshots()
//         .map((snapshot) {
//       List<BookingModel> bookingList = [];
//       for (var doc in snapshot.docs) {
//         BookingModel documentModel = BookingModel.fromJson(doc.data());
//         documentModel.id = doc.id;
//         bookingList.add(documentModel);
//       }
//       return bookingList;
//     });

//     // Passenger cancelled bookings
//     Stream<List<BookingModel>> passengerStream = fireStore
//         .collection(CollectionName.booking)
//         .where("bookedUserId", arrayContains: currentUid)
//         .where("status", isEqualTo: Constant.canceled)
//         .orderBy("createdAt", descending: true)
//         .snapshots()
//         .map((snapshot) {
//       List<BookingModel> bookingList = [];
//       for (var doc in snapshot.docs) {
//         BookingModel documentModel = BookingModel.fromJson(doc.data());
//         documentModel.id = doc.id;
//         bookingList.add(documentModel);
//       }
//       return bookingList;
//     });

//     // Combine and deduplicate the streams
//     return Rx.combineLatest2(driverStream, passengerStream,
//         (List<BookingModel> driverBookings,
//             List<BookingModel> passengerBookings) {
//       Set<String> addedIds = {};
//       List<BookingModel> allBookings = [];

//       // Add driver bookings
//       for (var booking in driverBookings) {
//         if (!addedIds.contains(booking.id)) {
//           allBookings.add(booking);
//           addedIds.add(booking.id!);
//         }
//       }

//       // Add passenger bookings (avoid duplicates)
//       for (var booking in passengerBookings) {
//         if (!addedIds.contains(booking.id)) {
//           allBookings.add(booking);
//           addedIds.add(booking.id!);
//         }
//       }

//       // Sort by creation date
//       allBookings.sort((a, b) {
//         if (a.createdAt == null || b.createdAt == null) return 0;
//         return b.createdAt!.compareTo(a.createdAt!);
//       });

//       return allBookings;
//     });
//   }

//   static Stream<List<BookingModel>> getCompletedBookingsStream() {
//     String currentUid = getCurrentUid();

//     // Combine both driver and passenger completed bookings
//     Stream<List<BookingModel>> driverStream = fireStore
//         .collection(CollectionName.booking)
//         .where("createdBy", isEqualTo: currentUid)
//         .where("status", isEqualTo: Constant.completed)
//         .orderBy("createdAt", descending: true)
//         .snapshots()
//         .map((snapshot) {
//       List<BookingModel> bookingList = [];
//       for (var doc in snapshot.docs) {
//         BookingModel documentModel = BookingModel.fromJson(doc.data());
//         documentModel.id = doc.id;
//         bookingList.add(documentModel);
//       }
//       return bookingList;
//     });

//     Stream<List<BookingModel>> passengerStream = fireStore
//         .collection(CollectionName.booking)
//         .where("bookedUserId", arrayContains: currentUid)
//         .where("status", isEqualTo: Constant.completed)
//         .orderBy("createdAt", descending: true)
//         .snapshots()
//         .map((snapshot) {
//       List<BookingModel> bookingList = [];
//       for (var doc in snapshot.docs) {
//         BookingModel documentModel = BookingModel.fromJson(doc.data());
//         documentModel.id = doc.id;
//         bookingList.add(documentModel);
//       }
//       return bookingList;
//     });

//     // Combine and deduplicate the streams
//     return Rx.combineLatest2(driverStream, passengerStream,
//         (List<BookingModel> driverBookings,
//             List<BookingModel> passengerBookings) {
//       Set<String> addedIds = {};
//       List<BookingModel> allBookings = [];

//       // Add driver bookings
//       for (var booking in driverBookings) {
//         if (!addedIds.contains(booking.id)) {
//           allBookings.add(booking);
//           addedIds.add(booking.id!);
//         }
//       }

//       // Add passenger bookings (avoid duplicates)
//       for (var booking in passengerBookings) {
//         if (!addedIds.contains(booking.id)) {
//           allBookings.add(booking);
//           addedIds.add(booking.id!);
//         }
//       }

//       // Sort by creation date
//       allBookings.sort((a, b) {
//         if (a.createdAt == null || b.createdAt == null) return 0;
//         return b.createdAt!.compareTo(a.createdAt!);
//       });

//       return allBookings;
//     });
//   }

//   // Real-time stream for BookedUserModel - checks both bookedUser and cancelledUser
//   static Stream<BookedUserModel?> getMyBookingUserStream(
//       BookingModel bookingModel) {
//     String currentUserId = getCurrentUid();

//     // Check bookedUser collection first
//     Stream<BookedUserModel?> bookedUserStream = fireStore
//         .collection(CollectionName.booking)
//         .doc(bookingModel.id)
//         .collection("bookedUser")
//         .doc(currentUserId)
//         .snapshots()
//         .map((snapshot) {
//       if (snapshot.exists) {
//         return BookedUserModel.fromJson(snapshot.data()!);
//       }
//       return null;
//     });

//     // Check cancelledUser collection
//     Stream<BookedUserModel?> cancelledUserStream = fireStore
//         .collection(CollectionName.booking)
//         .doc(bookingModel.id)
//         .collection("cancelledUser")
//         .doc(currentUserId)
//         .snapshots()
//         .map((snapshot) {
//       if (snapshot.exists) {
//         return BookedUserModel.fromJson(snapshot.data()!);
//       }
//       return null;
//     });

//     // Combine both streams - return bookedUser if exists, otherwise cancelledUser
//     return Rx.combineLatest2(bookedUserStream, cancelledUserStream,
//         (BookedUserModel? bookedUser, BookedUserModel? cancelledUser) {
//       return bookedUser ?? cancelledUser;
//     });
//   }

//   // ==================== Ride Alert Methods ====================

//   /// Create or update a ride alert
//   static Future<bool> setRideAlert(RideAlertModel rideAlertModel) async {
//     bool isAdded = false;
//     await fireStore
//         .collection(CollectionName.rideAlerts)
//         .doc(rideAlertModel.id)
//         .set(rideAlertModel.toJson())
//         .then((value) {
//       isAdded = true;
//     }).catchError((error) {
//       log("Failed to create ride alert: $error");
//       isAdded = false;
//     });
//     return isAdded;
//   }

//   /// Get active ride alerts for a user
//   static Future<List<RideAlertModel>?> getUserActiveRideAlerts(
//       String userId) async {
//     List<RideAlertModel> list = [];

//     await fireStore
//         .collection(CollectionName.rideAlerts)
//         .where("userId", isEqualTo: userId)
//         .where("isActive", isEqualTo: true)
//         .where("expiryDate", isGreaterThanOrEqualTo: Timestamp.now())
//         .get()
//         .then((value) {
//       for (var element in value.docs) {
//         RideAlertModel alertModel = RideAlertModel.fromJson(element.data());
//         list.add(alertModel);
//       }
//     }).catchError((error) {
//       log("Error fetching active ride alerts: $error");
//     });

//     return list;
//   }

//   /// Deactivate a ride alert
//   static Future<bool> deactivateRideAlert(String alertId) async {
//     bool success = false;
//     await fireStore
//         .collection(CollectionName.rideAlerts)
//         .doc(alertId)
//         .update({'isActive': false}).then((value) {
//       success = true;
//     }).catchError((error) {
//       log("Failed to deactivate ride alert: $error");
//       success = false;
//     });
//     return success;
//   }

//   /// Clean up expired ride alerts (can be called periodically)
//   static Future<void> cleanupExpiredRideAlerts() async {
//     try {
//       final expiredAlerts = await fireStore
//           .collection(CollectionName.rideAlerts)
//           .where("expiryDate", isLessThan: Timestamp.now())
//           .where("isActive", isEqualTo: true)
//           .get();

//       for (var doc in expiredAlerts.docs) {
//         await doc.reference.update({'isActive': false});
//       }
//       log("Cleaned up ${expiredAlerts.docs.length} expired ride alerts");
//     } catch (error) {
//       log("Error cleaning up expired ride alerts: $error");
//     }
//   }

//   /// Check if a booking matches a ride alert criteria
//   static Future<List<RideAlertModel>> getMatchingRideAlerts(
//       BookingModel booking) async {
//     List<RideAlertModel> matchingAlerts = [];

//     try {
//       // Get all active alerts that expire on or after the booking's departure date
//       final alertsSnapshot = await fireStore
//           .collection(CollectionName.rideAlerts)
//           .where("isActive", isEqualTo: true)
//           .where("expiryDate",
//               isGreaterThanOrEqualTo: booking.departureDateTime)
//           .where("expiryDate",
//               isLessThanOrEqualTo: Timestamp.fromDate(booking.departureDateTime!
//                   .toDate()
//                   .add(const Duration(days: 1))))
//           .get();

//       for (var doc in alertsSnapshot.docs) {
//         RideAlertModel alert = RideAlertModel.fromJson(doc.data());

//         // Don't alert the person who published the ride
//         if (alert.userId == booking.createdBy) {
//           continue;
//         }

//         // Check if alert has expired
//         if (alert.expiryDate != null &&
//             alert.expiryDate!.toDate().isBefore(DateTime.now())) {
//           continue;
//         }

//         // Check if the alert matches this booking's route using location matching
//         if (_doesAlertMatchBookingRoute(alert, booking)) {
//           matchingAlerts.add(alert);
//         }
//       }
//     } catch (error) {
//       // Error finding matching ride alerts
//     }

//     return matchingAlerts;
//   }

//   /// Helper method to check if a ride alert matches a booking's route
//   /// Uses the same matching logic as pickupIsSame() from home_controller
//   static bool _doesAlertMatchBookingRoute(
//       RideAlertModel alert, BookingModel booking) {
//     // Check if booking has stopOverList
//     if (booking.stopOverList == null || booking.stopOverList!.isEmpty) {
//       return false;
//     }

//     // Check if alert has valid pickup and drop locations
//     if (alert.pickUpLocation == null || alert.dropLocation == null) {
//       return false;
//     }

//     bool isPickUpMatched = false;
//     bool isDropOffMatched = false;

//     // Iterate through all stopOvers in the booking to find matching pickup and drop
//     for (var stopOver in booking.stopOverList!) {
//       // Skip if stopOver doesn't have valid location data
//       if (stopOver.startLocation == null || stopOver.endLocation == null) {
//         continue;
//       }

//       // Calculate distance between alert pickup and stopOver start location
//       double distancePickup = Constant.calculateDistance(
//           Location(
//               lat: stopOver.startLocation!.lat,
//               lng: stopOver.startLocation!.lng),
//           Location(
//               lat: alert.pickUpLocation!.lat, lng: alert.pickUpLocation!.lng));

//       // Calculate distance between alert drop and stopOver end location
//       double distanceDrop = Constant.calculateDistance(
//           Location(
//               lat: stopOver.endLocation!.lat, lng: stopOver.endLocation!.lng),
//           Location(lat: alert.dropLocation!.lat, lng: alert.dropLocation!.lng));

//       // Check if pickup is within radius
//       if (distancePickup <= double.parse(Constant.radius)) {
//         isPickUpMatched = true;
//       }

//       // Check if drop is within radius
//       if (distanceDrop <= double.parse(Constant.radius)) {
//         isDropOffMatched = true;
//       }

//       // If both pickup and drop are matched in this stopOver, alert matches this booking
//       if (isPickUpMatched && isDropOffMatched) {
//         return true;
//       }

//       // Reset for next iteration
//       isPickUpMatched = false;
//       isDropOffMatched = false;
//     }

//     return false;
//   }
// }
