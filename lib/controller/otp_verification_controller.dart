import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/utils/fire_store_utils.dart';

class OtpVerificationController extends GetxController {
  TextEditingController otpController = TextEditingController();
  RxBool isLoading = false.obs;
  RxString expectedOtp = "".obs;

  BookingModel? bookingModel;
  BookedUserModel? bookingUserModel;
  Function? onVerificationSuccess;

  @override
  void onInit() {
    super.onInit();
    getArguments();
  }

  getArguments() {
    if (Get.arguments != null) {
      bookingModel = Get.arguments["bookingModel"];
      bookingUserModel = Get.arguments["bookingUserModel"];
      onVerificationSuccess = Get.arguments["onVerificationSuccess"];
      expectedOtp.value = bookingUserModel?.otp ?? "";
    }
  }

  verifyOtp() async {
    if (otpController.text.isEmpty) {
      ShowToastDialog.showToast("Please enter OTP".tr);
      return;
    }

    if (otpController.text.length != 6) {
      ShowToastDialog.showToast("Please enter valid 6-digit OTP".tr);
      return;
    }

    if (otpController.text != expectedOtp.value) {
      ShowToastDialog.showToast("Invalid OTP. Please try again.".tr);
      return;
    }

    try {
      isLoading.value = true;

      // Update the verified status in Firebase
      bookingUserModel!.verified = true;

      await FireStoreUtils.setUserBooking(
        bookingModel!,
        bookingUserModel!,
      );

      ShowToastDialog.showToast("Passenger verified successfully!".tr);

      // Call the success callback if provided
      if (onVerificationSuccess != null) {
        onVerificationSuccess!();
      }

      Get.back(result: true);
    } catch (e) {
      ShowToastDialog.showToast(
          "Failed to verify passenger. Please try again.".tr);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }
}
