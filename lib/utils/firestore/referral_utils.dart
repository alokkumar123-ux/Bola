import 'dart:developer';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/model/referral_model.dart';
import 'package:poolmate/model/referral_edge_model.dart';
import 'package:poolmate/model/referral_earning_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/model/wallet_transaction_model.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/wallet_utils.dart';

/// Referral program management utilities
class ReferralUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  /// Check if referral code is valid
  static Future<bool?> checkReferralCodeValidOrNot(String referralCode) async {
    bool? isExit;
    try {
      await fireStore
          .collection(CollectionName.referral)
          .where("referralCode", isEqualTo: referralCode)
          .get()
          .then((value) {
        isExit = value.size > 0;
      });
    } catch (e) {
      print('Error checking referral code: $e');
      return false;
    }
    return isExit;
  }

  /// Get referral user by code
  static Future<ReferralModel?> getReferralUserByCode(
      String referralCode) async {
    ReferralModel? referralModel;
    try {
      await fireStore
          .collection(CollectionName.referral)
          .where("referralCode", isEqualTo: referralCode)
          .get()
          .then((value) {
        if (value.docs.isNotEmpty) {
          referralModel = ReferralModel.fromJson(value.docs.first.data());
        }
      });
    } catch (e) {
      print('Error getting referral user: $e');
      return null;
    }
    return referralModel;
  }

  /// Add referral
  static Future<String?> referralAdd(ReferralModel referralModel) async {
    try {
      await fireStore
          .collection(CollectionName.referral)
          .doc(referralModel.id)
          .set(referralModel.toJson());
    } catch (e) {
      print('Error adding referral: $e');
      return null;
    }
    return null;
  }

  /// Generate unique referral code from user name
  static Future<String> generateReferralCodeFromName(
      {String? firstName, String? lastName}) async {
    String base = "PM";
    final combined = "${firstName ?? ''}${lastName ?? ''}".replaceAll(' ', '');
    if (combined.isNotEmpty) {
      base = combined.toUpperCase();
      if (base.length > 5) {
        base = base.substring(0, 5);
      }
    }

    String attempt = base;
    bool unique = false;
    int guard = 0;
    while (!unique && guard < 8) {
      final suffix = (math.Random().nextInt(9000) + 1000).toString();
      attempt = "$base$suffix";
      unique = await _isReferralCodeUnique(attempt);
      guard++;
    }
    return attempt;
  }

  /// Check if referral code is unique
  static Future<bool> _isReferralCodeUnique(String code) async {
    final userSnap = await fireStore
        .collection(CollectionName.users)
        .where('referralCode', isEqualTo: code)
        .limit(1)
        .get();
    if (userSnap.docs.isNotEmpty) return false;

    final edgeSnap = await fireStore
        .collection(CollectionName.referral)
        .where('referralCode', isEqualTo: code)
        .limit(1)
        .get();
    return edgeSnap.docs.isEmpty;
  }

  /// Ensure user has referral code
  static Future<String> ensureUserReferralCode(UserModel userModel) async {
    if (userModel.referralCode != null && userModel.referralCode!.isNotEmpty) {
      return userModel.referralCode!;
    }
    final generated = await generateReferralCodeFromName(
        firstName: userModel.firstName, lastName: userModel.lastName);
    userModel.referralCode = generated;
    await UserUtils.updateUser(userModel);
    return generated;
  }

  /// Check if user should see the referral popup (first time & no referral code)
  static Future<bool> shouldShowReferralPopup(UserModel user) async {
    // If user already dismissed the popup, don't show again
    if (user.referralPromptDismissed ?? false) {
      return false;
    }
    // If user already has a referral code from signup, don't show popup
    if (user.referredBy != null && user.referredBy!.isNotEmpty) {
      return false;
    }
    return true;
  }

  /// Mark referral popup as dismissed in Firebase
  static Future<void> dismissReferralPopup(String userId) async {
    try {
      await fireStore.collection(CollectionName.users).doc(userId).update({
        'referralPromptDismissed': true,
      });
    } catch (e) {
      print('Error dismissing referral popup: $e');
    }
  }

  /// Apply referral code after signup (from popup)
  static Future<bool> applyReferralCodeAfterSignup({
    required String referralCode,
    required UserModel currentUser,
  }) async {
    if (referralCode.isEmpty || currentUser.id == null) return false;

    // Find referrer by referral code
    final referrerSnap = await fireStore
        .collection(CollectionName.users)
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    if (referrerSnap.docs.isEmpty) {
      return false;
    }

    final referrer = UserModel.fromJson(referrerSnap.docs.first.data());

    // Prevent self-referral
    if (referrer.id == currentUser.id) {
      return false;
    }

    // Check if referrer has reached maximum referral limit
    referrer.task1Refs ??= [];
    referrer.task2Refs ??= [];
    referrer.task3Refs ??= [];
    int totalReferrals = referrer.task1Refs!.length +
        referrer.task2Refs!.length +
        referrer.task3Refs!.length;
    if (totalReferrals >= 14) {
      return false;
    }

    try {
      // Update current user with referrer info
      currentUser.referredBy = referrer.id;
      await UserUtils.updateUser(currentUser);

      // Create or update referral edge
      await createOrUpdateReferralEdge(
        referrerId: referrer.id!,
        referredUserId: currentUser.id!,
        referralCode: referralCode,
      );

      // Assign to appropriate task list
      await _assignToTaskList(
        referrer: referrer,
        referredUserId: currentUser.id!,
      );

      return true;
    } catch (e) {
      print('Error applying referral code after signup: $e');
      return false;
    }
  }

  /// Apply referral code during signup
  static Future<bool> applyReferralCodeToUser({
    required String referralCode,
    required UserModel newUser,
  }) async {
    if (referralCode.isEmpty || newUser.id == null) return false;

    final referrerSnap = await fireStore
        .collection(CollectionName.users)
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    if (referrerSnap.docs.isEmpty) {
      return false;
    }

    final referrer = UserModel.fromJson(referrerSnap.docs.first.data());
    if (referrer.id == newUser.id) {
      return false;
    }

    // Check if referrer has reached maximum referral limit (1 + 5 + 8 = 14 total)
    referrer.task1Refs ??= [];
    referrer.task2Refs ??= [];
    referrer.task3Refs ??= [];
    int totalReferrals = referrer.task1Refs!.length +
        referrer.task2Refs!.length +
        referrer.task3Refs!.length;
    if (totalReferrals >= 14) {
      print('Referrer ${referrer.id} has reached maximum referral limit (14)');
      return false;
    }

    newUser.referredBy = referrer.id;
    await UserUtils.updateUser(newUser);

    await createOrUpdateReferralEdge(
      referrerId: referrer.id!,
      referredUserId: newUser.id!,
      referralCode: referralCode,
    );

    await _assignToTaskList(
      referrer: referrer,
      referredUserId: newUser.id!,
    );

    return true;
  }

  /// Get referral edge by referred user ID
  static Future<ReferralEdgeModel?> getReferralEdgeByReferred(
      String referredUserId) async {
    try {
      final doc = await fireStore
          .collection(CollectionName.referral)
          .doc(referredUserId)
          .get();
      if (!doc.exists) return null;
      return ReferralEdgeModel.fromJson(doc.data()!);
    } catch (e) {
      print('Error getting referral edge: $e');
      return null;
    }
  }

  /// Create or update referral edge
  static Future<ReferralEdgeModel> createOrUpdateReferralEdge({
    required String referrerId,
    required String referredUserId,
    required String referralCode,
  }) async {
    final edge = ReferralEdgeModel(
      id: referredUserId,
      referrerId: referrerId,
      referredUserId: referredUserId,
      referralCodeUsed: referralCode,
      createdAt: Timestamp.now(),
      rideCount: 0,
      firstRideRewardGiven: false,
      totalEarnedFromUser: '0',
    );
    await fireStore
        .collection(CollectionName.referral)
        .doc(referredUserId)
        .set(edge.toJson(), SetOptions(merge: true));
    return edge;
  }

  /// Get referral earning by ID
  static Future<ReferralEarningModel?> getReferralEarningById(String id) async {
    final doc = await fireStore
        .collection(CollectionName.referralEarnings)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return ReferralEarningModel.fromJson(doc.data()!);
  }

  /// Process referral when ride is completed
  static Future<void> processReferralOnRideCompleted({
    required BookingModel bookingModel,
    required List<BookedUserModel> bookedUsers,
  }) async {
    print(
        'START processReferralOnRideCompleted - Booking: ${bookingModel.id}, Users: ${bookedUsers.length}');
    for (final rider in bookedUsers) {
      final riderId = rider.id;
      print('Processing rider: $riderId');
      if (riderId == null) {
        print('WARNING: Skipping rider with null ID');
        continue;
      }

      print('Fetching referral edge for rider: $riderId');
      ReferralEdgeModel? edge = await getReferralEdgeByReferred(riderId);

      if (edge == null) {
        print(
            'No referral edge found for rider: $riderId, checking user profile');
        final riderProfile = await UserUtils.getUserProfile(riderId);
        final referrerId = riderProfile?.referredBy;
        if (referrerId == null || referrerId.isEmpty) {
          print('Rider $riderId has no referrer, skipping');
          continue;
        }
        print('Found referrer: $referrerId, creating edge');
        final referralCode = riderProfile?.referralCode ?? '';
        edge = await createOrUpdateReferralEdge(
          referrerId: referrerId,
          referredUserId: riderId,
          referralCode: referralCode,
        );
      }

      if (edge.referrerId == null) {
        print('WARNING: Edge has no referrerId, skipping');
        continue;
      }
      print('Fetching referrer profile: ${edge.referrerId}');
      final referrer = await UserUtils.getUserProfile(edge.referrerId!);
      if (referrer == null) {
        print('ERROR: Referrer profile not found: ${edge.referrerId}');
        continue;
      }

      final rideCount = (edge.rideCount ?? 0) + 1;
      print(
          'Ride count for rider $riderId: $rideCount (was: ${edge.rideCount ?? 0})');

      edge.rideCount = rideCount;
      edge.lastBookingId = bookingModel.id;
      edge.firstRideRewardGiven = edge.firstRideRewardGiven ?? false;

      double rideAmount = double.tryParse(rider.subTotal ?? '0') ?? 0;
      double rateToApply = 0;
      bool shouldCredit = false;
      String earningNote = '';

      final currentStage = referrer.referralStage ?? 1;
      referrer.task1Refs ??= [];

      if (currentStage >= 3) {
        rateToApply = 0.03;
        shouldCredit = rideAmount > 0;
        earningNote = 'Referral 3% commission';
      } else if (rideCount == 1 &&
          referrer.task1Refs!.isNotEmpty &&
          referrer.task1Refs!.first == riderId) {
        rateToApply = 0.01;
        shouldCredit = rideAmount > 0;
        edge.firstRideRewardGiven = true;
        earningNote = 'Referral 1% first ride';
      }

      double earningAmount = 0;
      if (shouldCredit && rateToApply > 0) {
        earningAmount = rideAmount * rateToApply;
        final earningId = "${bookingModel.id}_${riderId}_$rideCount";
        final existing = await fireStore
            .collection(CollectionName.referralEarnings)
            .doc(earningId)
            .get();
        if (!existing.exists) {
          ReferralEarningModel earning = ReferralEarningModel(
            id: earningId,
            referrerId: edge.referrerId,
            referredUserId: riderId,
            bookingId: bookingModel.id,
            amount: earningAmount.toStringAsFixed(2),
            rate: rateToApply,
            rideNumberForUser: rideCount,
            status: 'credited',
            note: earningNote,
            createdAt: Timestamp.now(),
          );
          await fireStore
              .collection(CollectionName.referralEarnings)
              .doc(earningId)
              .set(earning.toJson());

          WalletTransactionModel transactionModel = WalletTransactionModel(
              id: Constant.getUuid(),
              amount: earningAmount.toStringAsFixed(2),
              createdDate: Timestamp.now(),
              paymentType: "Referral",
              transactionId: bookingModel.id,
              isCredit: true,
              type: 'customer',
              userId: referrer.id,
              note: earningNote);

          await fireStore
              .collection(CollectionName.walletTransaction)
              .doc(transactionModel.id)
              .set(transactionModel.toJson());

          print('Wallet transaction recorded for referral commission');
          final walletUpdated = await WalletUtils.updateOtherUserWallet(
              amount: earningAmount.toStringAsFixed(2), id: referrer.id!);
          if (walletUpdated == true) {
            print(
                '✅ Referral commission credited: ${earningAmount.toStringAsFixed(2)} to wallet of ${referrer.id}');
            // Refresh referrer's wallet balance from Firebase
            final updatedReferrer =
                await UserUtils.getUserProfile(referrer.id!);
            if (updatedReferrer != null) {
              referrer.walletAmount = updatedReferrer.walletAmount;
              print('🔄 Wallet balance refreshed: ${referrer.walletAmount}');
            }
          } else {
            print(
                '❌ FAILED to credit commission: ${earningAmount.toStringAsFixed(2)} to wallet of ${referrer.id}');
          }

          edge.totalEarnedFromUser =
              ((double.tryParse(edge.totalEarnedFromUser ?? '0') ?? 0) +
                      earningAmount)
                  .toStringAsFixed(2);

          double totalEarned =
              double.tryParse(referrer.referralEarningsTotal ?? '0') ?? 0;
          referrer.referralEarningsTotal =
              (totalEarned + earningAmount).toStringAsFixed(2);

          await UserUtils.updateUser(referrer);
        }
      }

      print(
          'Calling _updateReferralProgress for rider $riderId, isFirstRide: ${rideCount == 1}');
      await _updateReferralProgress(
        referrer: referrer,
        referredUserId: riderId,
        isFirstRideCompleted: rideCount == 1,
      );

      print('Saving referral edge for rider: $riderId');
      await fireStore
          .collection(CollectionName.referral)
          .doc(riderId)
          .set(edge.toJson(), SetOptions(merge: true));
    }
  }

  /// Update referral progress and stage
  static Future<void> _updateReferralProgress({
    required UserModel referrer,
    required String referredUserId,
    required bool isFirstRideCompleted,
  }) async {
    print(
        '_updateReferralProgress called - Referrer: ${referrer.id}, ReferredUser: $referredUserId, IsFirstRide: $isFirstRideCompleted');

    referrer.referralStage ??= 1;
    referrer.commissionRate ??= '0.01';
    referrer.task1Refs ??= [];
    referrer.task2Refs ??= [];
    referrer.task3Refs ??= [];

    print(
        'Current referrer state - Stage: ${referrer.referralStage}, Task1: ${referrer.task1Refs!.length}, Task2: ${referrer.task2Refs!.length}, Task3: ${referrer.task3Refs!.length}, Task2Bonus: ${referrer.task2BonusGiven}');

    bool shouldSetStage3 = false;

    if (isFirstRideCompleted) {
      print('First ride completed for user: $referredUserId');

      if (referrer.task1Refs!.isNotEmpty &&
          referrer.task1Refs!.first == referredUserId) {
        print('Upgrading referrer to Stage 2');
        referrer.referralStage = 2;
      }

      print(
          'Checking Task 2 progress - task2Refs length: ${referrer.task2Refs!.length}, bonusGiven: ${referrer.task2BonusGiven}');
      if (referrer.task2Refs!.isNotEmpty && referrer.task2BonusGiven != true) {
        print('Task 2 check condition met, counting completed rides...');
        int completedRides = 0;
        for (String userId in referrer.task2Refs!) {
          final edge = await getReferralEdgeByReferred(userId);
          final rideCount = edge?.rideCount ?? 0;
          print(
              '  - User $userId: rideCount=$rideCount, completed=${rideCount >= 1}');
          if (edge != null && (edge.rideCount ?? 0) >= 1) {
            completedRides++;
          }
        }

        print(
            'TASK 2 PROGRESS: $completedRides out of 5 users completed their first ride (Referrer: ${referrer.id})');

        if (completedRides == 4) {
          print(
              'ALL 5 TASK 2 USERS COMPLETED! Crediting Rs.100 bonus and unlocking Stage 3');
          await _creditReferralBonus(
            referrerId: referrer.id!,
            amount: 100,
            note: 'Referral Task 2 bonus',
          );
          referrer.task2BonusGiven = true;
          shouldSetStage3 = true;
        }
      } else {
        print('Skipping Task 2 check - not enough refs or bonus already given');
      }
    } else {
      print('Not first ride, skipping progress checks');
    }

    if (shouldSetStage3) {
      referrer.referralStage = 3;
      referrer.commissionRate = '0.03';
    }

    await UserUtils.updateUser(referrer);
  }

  /// Assign referred user to task list
  static Future<void> _assignToTaskList({
    required UserModel referrer,
    required String referredUserId,
  }) async {
    referrer.referralStage ??= 1;
    referrer.task1Refs ??= [];
    referrer.task2Refs ??= [];
    referrer.task3Refs ??= [];

    if (referrer.task1Refs!.isEmpty &&
        !referrer.task1Refs!.contains(referredUserId)) {
      referrer.task1Refs!.add(referredUserId);
    } else if (referrer.task1Refs!.isNotEmpty &&
        referrer.task2Refs!.length < 5 &&
        !referrer.task1Refs!.contains(referredUserId) &&
        !referrer.task2Refs!.contains(referredUserId)) {
      referrer.task2Refs!.add(referredUserId);
    } else if (referrer.task2Refs!.length >= 5 &&
        referrer.task3Refs!.length < 8 &&
        !referrer.task1Refs!.contains(referredUserId) &&
        !referrer.task2Refs!.contains(referredUserId) &&
        !referrer.task3Refs!.contains(referredUserId)) {
      referrer.task3Refs!.add(referredUserId);
    }
    // Maximum 14 referrals allowed: 1 (Task 1) + 5 (Task 2) + 8 (Task 3)

    await UserUtils.updateUser(referrer);
  }

  /// Credit referral bonus
  static Future<void> _creditReferralBonus({
    required String referrerId,
    required double amount,
    required String note,
  }) async {
    print('🎉 Crediting referral bonus: $amount to $referrerId');

    final amountStr = amount.toStringAsFixed(2);

    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: amountStr,
        createdDate: Timestamp.now(),
        paymentType: "Referral",
        transactionId: "referral_task_bonus",
        isCredit: true,
        type: 'customer',
        userId: referrerId,
        note: note);

    await fireStore
        .collection(CollectionName.walletTransaction)
        .doc(transactionModel.id)
        .set(transactionModel.toJson());

    print('Task 2 wallet transaction recorded for referral bonus');
    final walletUpdated = await WalletUtils.updateOtherUserWallet(
        amount: amountStr, id: referrerId);
    if (walletUpdated == true) {
      print('✅ Referral bonus credited: $amountStr to wallet of $referrerId');
      // Refresh referrer's wallet balance from Firebase (mirror first block)
      final updatedReferrer = await UserUtils.getUserProfile(referrerId);
      if (updatedReferrer != null) {
        print('🔄 Wallet balance refreshed: ${updatedReferrer.walletAmount}');
      }
    } else {
      print('❌ FAILED to credit referral bonus to wallet of $referrerId');
    }
    // Fetch fresh referrer profile with updated wallet balance
    final referrer = await UserUtils.getUserProfile(referrerId);
    if (referrer != null) {
      print('🔄 Wallet balance refreshed: ${referrer.walletAmount}');
      // Update total referral earnings (wallet already updated above)
      double totalEarned =
          double.tryParse(referrer.referralEarningsTotal ?? '0') ?? 0;
      referrer.referralEarningsTotal =
          (totalEarned + amount).toStringAsFixed(2);
      await UserUtils.updateUser(referrer);
      print(
          '✅ Bonus credited successfully - Final wallet: ${referrer.walletAmount}');
    }
  }
}
