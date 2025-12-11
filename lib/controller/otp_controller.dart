import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/services/whatsapp_auth_service.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';

class OtpController extends GetxController {
  Rx<TextEditingController> otpController = TextEditingController().obs;

  RxString countryCode = "".obs;
  RxString phoneNumber = "".obs;
  RxString storedOtp = "".obs; // Store the OTP for local verification
  RxBool isLoading = true.obs;
  RxBool isLogin = false.obs; // Track if this is login or signup

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

  /// Resend OTP via WhatsApp
  Future<bool> sendOTP() async {
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
