import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:poolmate/app/dashboard_screen.dart';
import 'package:poolmate/app/help_support_screen/help_support_screen.dart';
import 'package:poolmate/app/on_boarding_screen/get_started_screen.dart';
import 'package:poolmate/app/on_boarding_screen/on_boarding_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/utils/fire_store_utils.dart';
import 'package:poolmate/utils/preferences.dart';

class SplashController extends GetxController {
  Timer? timer;
  @override
  void onInit() {
    // Test signature generation on app start
    Constant.testSignatureGeneration();

    timer = Timer(const Duration(seconds: 3), () => redirectScreen());
    super.onInit();
  }

  redirectScreen() async {
    if (Preferences.getBoolean(Preferences.isClickOnNotification) != true) {
      // Skip onboarding screen on web platform
      if (!kIsWeb &&
          Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
        Get.offAll(const OnBoardingScreen());
      } else {
        bool isLogin = await FireStoreUtils.isLogin();
        if (isLogin == true) {
          // Don't update FCM token on app startup - only during login/signup
          Get.offAll(const DashBoardScreen());
        } else {
          Get.offAll(const GetStartedScreen());
        }
      }
    } else {
      Get.to(HelpSupportScreen());
    }
  }
}
