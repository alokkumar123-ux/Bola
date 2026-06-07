import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<UserModel> userModel = UserModel().obs;
  bool hasShownSosDialog = false;
  RxString appVersion = "".obs;

  static bool hasShownTutorialThisSession = false;
  RxBool isTutorialAvailable = false.obs;
  RxBool showTutorialTooltip = false.obs;
  final ScrollController scrollController = ScrollController();
  final GlobalKey tutorialKey = GlobalKey();

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  getData() async {
    await UserUtils.getUserProfile(AuthUtils.getCurrentUid()).then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });

    try {
      var snapshot = await FirebaseFirestore.instance.collection(CollectionName.settings).doc("Tutorial").get();
      if (snapshot.exists) {
        isTutorialAvailable.value = snapshot.data()?['isTutorialavailable'] ?? false;
      }
    } catch (e) {
      print("Error fetching tutorial settings: $e");
    }

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      appVersion.value = "v${packageInfo.version}+${packageInfo.buildNumber}";
    } catch (e) {
      print("Error fetching app version: $e");
    }

    isLoading.value = false;
  }
}
