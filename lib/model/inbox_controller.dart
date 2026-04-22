import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';

class InboxController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<UserModel> senderUserModel = UserModel().obs;
  final TextEditingController searchController = TextEditingController();
  RxString searchText = ''.obs;
  RxBool isSearching = false.obs;
  RxList<UserModel> searchResults = <UserModel>[].obs;
  RxList<String> selectedShareUserIds = <String>[].obs;
  final Map<String, Future<UserModel?>> _userProfileFutureCache = {};

  Timer? _searchDebounce;

  @override
  void onInit() {
    getUser();
    super.onInit();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  getUser() async {
    await UserUtils.getUserProfile(AuthUtils.getCurrentUid()).then((value) {
      senderUserModel.value = value!;
    });
    isLoading.value = false;
  }

  void onSearchChanged(String value) {
    searchText.value = value;
    _searchDebounce?.cancel();

    final normalized = _digitsOnly(value);
    if (normalized.length < 3) {
      isSearching.value = false;
      searchResults.clear();
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      await _searchUsersByPhone(normalized);
    });
  }

  Future<void> _searchUsersByPhone(String queryDigits) async {
    try {
      isSearching.value = true;

      final snapshot = await FirebaseFirestore.instance
          .collection(CollectionName.users)
          .orderBy('phoneNumber')
          .startAt([queryDigits])
          .endAt(['$queryDigits\uf8ff'])
          .limit(25)
          .get();

      final currentUserId = senderUserModel.value.id;
      final List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .where((user) =>
              user.id != null &&
              user.id != currentUserId &&
              _digitsOnly(user.phoneNumber).contains(queryDigits))
          .toList();

      users.sort((a, b) {
        final aPhone = _digitsOnly(a.phoneNumber);
        final bPhone = _digitsOnly(b.phoneNumber);

        final aExact = aPhone == queryDigits ? 0 : 1;
        final bExact = bPhone == queryDigits ? 0 : 1;
        if (aExact != bExact) return aExact - bExact;

        final aStarts = aPhone.startsWith(queryDigits) ? 0 : 1;
        final bStarts = bPhone.startsWith(queryDigits) ? 0 : 1;
        if (aStarts != bStarts) return aStarts - bStarts;

        return (a.fullName().toString()).compareTo(b.fullName().toString());
      });

      searchResults.assignAll(users);
    } catch (_) {
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  String _digitsOnly(String? value) {
    return (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<UserModel?> getUserProfileFuture(String? userId) {
    if (userId == null || userId.isEmpty) {
      return Future<UserModel?>.value(null);
    }
    return _userProfileFutureCache.putIfAbsent(
      userId,
      () => UserUtils.getUserProfile(userId),
    );
  }

  void toggleShareSelection(String? userId) {
    if (userId == null || userId.isEmpty) return;
    if (selectedShareUserIds.contains(userId)) {
      selectedShareUserIds.remove(userId);
      return;
    }
    selectedShareUserIds.add(userId);
  }

  bool isShareSelected(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    return selectedShareUserIds.contains(userId);
  }

  void clearShareSelection() {
    selectedShareUserIds.clear();
  }
}
