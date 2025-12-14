import 'dart:async';

import 'package:get/get.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/model/referral_edge_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/referral_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<UserModel> user = UserModel().obs;
  RxList<ReferralEdgeModel> edges = <ReferralEdgeModel>[].obs;
  RxBool referralPopupShown =
      false.obs; // Track if popup was shown in this session

  StreamSubscription? _edgeSub;
  StreamSubscription? _userSub;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  @override
  void onClose() {
    _edgeSub?.cancel();
    _userSub?.cancel();
    super.onClose();
  }

  Future<void> _init() async {
    isLoading.value = true;
    final uid = AuthUtils.getCurrentUid();
    final profile = await UserUtils.getUserProfile(uid);
    if (profile != null) {
      await ReferralUtils.ensureUserReferralCode(profile);
      final refreshed = await UserUtils.getUserProfile(uid);
      user.value = refreshed ?? profile;
    }

    // Listen to user document changes for real-time task list updates
    _userSub = FirebaseFirestore.instance
        .collection(CollectionName.users)
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        user.value = UserModel.fromJson(snapshot.data()!);
      }
    });

    _edgeSub = FirebaseFirestore.instance
        .collection(CollectionName.referral)
        .where('referrerId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      edges.value = snapshot.docs
          .map((doc) => ReferralEdgeModel.fromJson(doc.data()))
          .toList();
    });

    isLoading.value = false;
  }

  Future<void> refreshUser() async {
    final updated = await UserUtils.getUserProfile(
        user.value.id ?? AuthUtils.getCurrentUid());
    if (updated != null) {
      user.value = updated;
    }
  }

  double get commissionRate =>
      double.tryParse(user.value.commissionRate ?? '0') ?? 0;

  int get task1Progress => user.value.task1Refs?.length ?? 0;
  int get task2Progress => _completedCount(user.value.task2Refs);

  int get task3Progress => _completedCount(user.value.task3Refs);

  int get totalFirstRideReferrals =>
      edges.where((e) => (e.rideCount ?? 0) >= 1).length;

  List<ReferralEdgeModel> get task1Edges =>
      _edgesForIds(user.value.task1Refs) ?? [];

  List<ReferralEdgeModel> get task2Edges =>
      _edgesForIds(user.value.task2Refs) ?? [];

  List<ReferralEdgeModel> get task3Edges =>
      _edgesForIds(user.value.task3Refs) ?? [];

  int _completedCount(List<String>? ids) {
    if (ids == null || ids.isEmpty) return 0;
    return edges
        .where(
            (e) => ids.contains(e.referredUserId) && ((e.rideCount ?? 0) >= 1))
        .length;
  }

  List<ReferralEdgeModel>? _edgesForIds(List<String>? ids) {
    if (ids == null || ids.isEmpty) return [];
    return ids
        .map((id) => edges.firstWhere(
              (e) => e.referredUserId == id,
              orElse: () => ReferralEdgeModel(),
            ))
        .where((edge) => edge.referredUserId != null)
        .toList();
  }

  /// Apply referral code from popup dialog
  Future<bool> applyReferralCodeFromPopup(String code) async {
    try {
      final success = await ReferralUtils.applyReferralCodeAfterSignup(
        referralCode: code,
        currentUser: user.value,
      );

      if (success) {
        // Mark popup as dismissed and update user
        await ReferralUtils.dismissReferralPopup(user.value.id ?? '');
        // Refresh user data
        await refreshUser();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Mark referral popup as dismissed
  Future<void> dismissReferralPopup() async {
    try {
      await ReferralUtils.dismissReferralPopup(user.value.id ?? '');
      user.value.referralPromptDismissed = true;
    } catch (e) {
      // Continue even if dismissal fails
    }
  }

  /// Check if referral popup should be shown
  Future<bool> shouldShowReferralPopup() async {
    return await ReferralUtils.shouldShowReferralPopup(user.value);
  }
}
