import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/services/whatsapp_auth_service.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
// GOOGLE PLAY REVIEW LOGIN
import 'package:poolmate/services/google_play_review_config.dart';

class OtpController extends GetxController {
  Rx<TextEditingController> otpController = TextEditingController().obs;

  RxString countryCode = "".obs;
  RxString phoneNumber = "".obs;
  RxString storedOtp = "".obs; // Store the OTP for local verification
  RxBool isLoading = true.obs;
  RxBool isLogin = false.obs; // Track if this is login or signup

  // GOOGLE PLAY REVIEW LOGIN: Flag set when the reviewer uses the bypass number.
  RxBool isReviewMode = false.obs;

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      countryCode.value = argumentData['countryCode'];
      phoneNumber.value = argumentData['phoneNumber'];
      storedOtp.value = argumentData['otp'] ?? '';
      isLogin.value = argumentData['isLogin'] ?? false;
      // GOOGLE PLAY REVIEW LOGIN: read review-mode flag from arguments
      isReviewMode.value = argumentData['isReviewMode'] ?? false;
      if (isReviewMode.value) {
        debugPrint(
          '[GOOGLE PLAY REVIEW LOGIN] OtpController loaded in review mode. '
          'Static OTP stored. No WhatsApp OTP was sent.',
        );
      }
    }
    isLoading.value = false;
    update();
  }

  /// Verify OTP locally
  bool verifyOTP(String enteredOTP) {
    return WhatsAppAuthService.verifyOTP(enteredOTP, storedOtp.value);
  }

  /// Generate a secure unique user ID (UUID format similar to Firebase)
  String generateUserId() {
    return WhatsAppAuthService.generateUserId();
  }

  /// Resend OTP via WhatsApp (blocked for review accounts)
  Future<bool> sendOTP() async {
    // GOOGLE PLAY REVIEW LOGIN: Never resend WhatsApp OTP for the review account.
    if (isReviewMode.value ||
        GooglePlayReviewConfig.isReviewNumber(
          countryCode: countryCode.value,
          phoneNumber: phoneNumber.value,
        )) {
      debugPrint(
        '[GOOGLE PLAY REVIEW LOGIN] Resend blocked for review account. '
        'Static OTP remains: ${GooglePlayReviewConfig.reviewOtp}',
      );
      ShowToastDialog.showToast(
        'Use OTP: ${GooglePlayReviewConfig.reviewOtp} (Review Mode)',
      );
      return true;
    }

    ShowToastDialog.showLoader("Sending OTP...".tr);

    // Generate new OTP
    String newOtp = WhatsAppAuthService.generateOTP();

    // Send OTP via WhatsApp
    final result = await WhatsAppAuthService.sendOTP(
      countryCode: countryCode.value,
      phoneNumber: phoneNumber.value,
      otp: newOtp,
    );

    ShowToastDialog.closeLoader();

    if (result['success'] == true) {
      // Update stored OTP
      storedOtp.value = newOtp;
      ShowToastDialog.showToast("OTP sent successfully".tr);
      return true;
    } else {
      ShowToastDialog.showToast(result['message'] ?? "Failed to send OTP".tr);
      return false;
    }
  }
}
