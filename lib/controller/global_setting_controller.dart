import 'dart:developer';

import 'package:get/get.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/model/currency_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/settings_utils.dart';
import 'package:poolmate/utils/notification_service.dart';

import '../constant/collection_name.dart';

class GlobalSettingController extends GetxController {
  @override
  void onInit() {
    notificationInit();
    getCurrentCurrency();

    super.onInit();
  }

  getCurrentCurrency() async {
    AuthUtils.fireStore
        .collection(CollectionName.currency)
        .where("enable", isEqualTo: true)
        .snapshots()
        .listen((event) {
      if (event.docs.isNotEmpty) {
        Constant.currencyModel =
            CurrencyModel.fromJson(event.docs.first.data());
      } else {
        Constant.currencyModel = CurrencyModel(
            id: "",
            code: "USD",
            decimalDigits: 2,
            enable: true,
            name: "US Dollar",
            symbol: "\$",
            symbolAtRight: false);
      }
    });
    await SettingsUtils().getSettings();
  }

  NotificationService notificationService = NotificationService();

  notificationInit() async {
    // Only initialize notification service without updating FCM token
    // FCM token should only be updated during login/signup
    try {
      await notificationService.initInfo();
      log("Notification service initialized successfully");
    } catch (error) {
      log("Failed to initialize notification service: $error");
    }
  }
}
