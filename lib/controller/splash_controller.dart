import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:poolmate/app/dashboard_screen.dart';
import 'package:poolmate/controller/dashboard_controller.dart';
import 'package:poolmate/app/help_support_screen/help_support_screen.dart';
import 'package:poolmate/app/on_boarding_screen/get_started_screen.dart';
import 'package:poolmate/app/on_boarding_screen/on_boarding_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/utils/preferences.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/services/fcm_token_manager.dart';
import 'package:poolmate/services/pending_payment_service.dart';

class SplashController extends GetxController {
  Timer? timer;

  // Pre-loaded values to avoid delay during navigation
  bool? _isLoggedIn;
  bool _preloadComplete = false;

  @override
  void onInit() {
    // Test signature generation on app start
    Constant.testSignatureGeneration();

    // Start preloading immediately (runs in parallel with animation)
    _preloadData();

    timer = Timer(const Duration(milliseconds: 3500), () => redirectScreen());
    super.onInit();
  }

  // Pre-load all async data during splash animation
  Future<void> _preloadData() async {
    try {
      // Check login status early
      if (!kIsWeb &&
          Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == true) {
        _isLoggedIn = await AuthUtils.isLogin();
        print('🔄 Pre-loaded login status: $_isLoggedIn');

        if (_isLoggedIn == true) {
          await FcmTokenManager.instance.initialize();
          print('🔄 Pre-loaded FCM initialization');

          // Check for pending payment recovery (app crash during Cashfree payment)
          try {
            bool recovered =
                await PendingPaymentService.checkAndRecoverPendingPayments();
            if (recovered) {
              print('🔄 Recovered pending payment and created booking');
            }
          } catch (e) {
            print('🔄 Pending payment recovery error: $e');
          }

          // Pre-initialize Dashboard Controller to fetch data in background
          if (!Get.isRegistered<DashboardScreenController>()) {
            Get.put(DashboardScreenController());
            print('🔄 DashboardScreenController initialized in background');
          }
        }
      }
    } catch (e) {
      print('🔄 Preload error: $e');
    }
    _preloadComplete = true;
  }

  redirectScreen() async {
    print('🔄 SplashController: redirectScreen() called');

    // Wait for preload to complete if not done yet
    while (!_preloadComplete) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (Preferences.getBoolean(Preferences.isClickOnNotification) != true) {
      // Skip onboarding screen on web platform
      if (!kIsWeb &&
          Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
        print('🔄 Navigating to OnBoardingScreen');
        Get.offAll(
          () => const OnBoardingScreen(),
          transition: Transition.downToUp,
          duration: const Duration(milliseconds: 800),
        );
      } else {
        // Use pre-loaded login status (instant, no await needed)
        print('🔄 Using pre-loaded login status: $_isLoggedIn');
        if (_isLoggedIn == true) {
          print('🔄 FCM already initialized, navigating to DashBoardScreen');
          Get.offAll(
            () => const DashBoardScreen(),
            transition: Transition.downToUp,
            duration: const Duration(milliseconds: 800),
          );
        } else {
          print('🔄 Navigating to GetStartedScreen');
          Get.offAll(
            () => const GetStartedScreen(),
            transition: Transition.downToUp,
            duration: const Duration(milliseconds: 800),
          );
        }
      }
    } else {
      print(
          '🔄 isClickOnNotification is true, navigating to HelpSupportScreen');
      Get.to(
        () => HelpSupportScreen(),
        transition: Transition.rightToLeftWithFade,
        duration: const Duration(milliseconds: 500),
      );
    }
  }
}
