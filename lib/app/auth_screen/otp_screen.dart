import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:poolmate/app/auth_screen/information_screen.dart';
import 'package:poolmate/app/dashboard_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/otp_controller.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/services/fcm_token_manager.dart';
import 'package:provider/provider.dart';

import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/services/deep_link_service.dart';
// GOOGLE PLAY REVIEW LOGIN
import 'package:poolmate/services/google_play_review_config.dart';
import 'package:poolmate/services/google_play_review_auth_service.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<OtpController>(
        init: OtpController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.grey900
                : AppThemeData.grey50,
            appBar: AppBar(
              backgroundColor: themeChange.getThem()
                  ? AppThemeData.grey900
                  : AppThemeData.grey50,
              centerTitle: true,
              leading: InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Icon(
                    Icons.arrow_back_outlined,
                    color: themeChange.getThem()
                        ? AppThemeData.grey200
                        : AppThemeData.grey700,
                  )),
              title: Text(
                "Verify Mobile Number".tr,
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey100
                        : AppThemeData.grey800,
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 16),
              ),
            ),
            body: SafeArea(
              child: controller.isLoading.value
                  ? Center(child: Constant.loader())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Enter the 6 digit code we’re sent to ${controller.countryCode.value} ${Constant.maskingString(controller.phoneNumber.value, 3)}"
                                  .tr,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey200
                                    : AppThemeData.grey700,
                                fontSize: 16,
                                fontFamily: AppThemeData.regular,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            // -----------------------------------------------
                            // GOOGLE PLAY REVIEW LOGIN: review-mode badge
                            // Only shown for the dedicated review phone number.
                            // -----------------------------------------------
                            if (controller.isReviewMode.value) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  border: Border.all(
                                      color: Colors.green.shade300, width: 1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.verified_user_rounded,
                                        color: Colors.green.shade700, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Google Play Review Mode Detected',
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontSize: 13,
                                        fontFamily: AppThemeData.semiBold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(
                              height: 40,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: PinCodeTextField(
                                length: 6,
                                appContext: context,
                                keyboardType: TextInputType.phone,
                                enablePinAutofill: true,
                                hintCharacter: "-",
                                hintStyle: TextStyle(
                                    color: themeChange.getThem()
                                        ? AppThemeData.grey50
                                        : AppThemeData.grey900,
                                    fontFamily: AppThemeData.regular),
                                textStyle: TextStyle(
                                    color: themeChange.getThem()
                                        ? AppThemeData.grey50
                                        : AppThemeData.grey900,
                                    fontFamily: AppThemeData.regular),
                                pinTheme: PinTheme(
                                    fieldHeight: 50,
                                    fieldWidth: 50,
                                    selectedColor: themeChange.getThem()
                                        ? AppThemeData.primary300
                                        : AppThemeData.primary300,
                                    activeColor: themeChange.getThem()
                                        ? AppThemeData.grey800
                                        : AppThemeData.grey100,
                                    inactiveColor: themeChange.getThem()
                                        ? AppThemeData.grey800
                                        : AppThemeData.grey100,
                                    disabledColor: themeChange.getThem()
                                        ? AppThemeData.grey800
                                        : AppThemeData.grey100,
                                    shape: PinCodeFieldShape.box,
                                    errorBorderColor: themeChange.getThem()
                                        ? AppThemeData.grey600
                                        : AppThemeData.grey300,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10))),
                                cursorColor: AppThemeData.primary300,
                                controller: controller.otpController.value,
                                onCompleted: (v) async {},
                                onChanged: (value) {},
                              ),
                            ),
                            const SizedBox(
                              height: 50,
                            ),
                            RoundedButtonFill(
                              title: "Verify & Next".tr,
                              color: Colors.black,
                              textColor: Colors.white,
                              onPress: () async {
                                if (controller
                                        .otpController.value.text.length ==
                                    6) {
                                  ShowToastDialog.showLoader("Verify otp".tr);

                                  // -------------------------------------------
                                  // GOOGLE PLAY REVIEW LOGIN: bypass auth path.
                                  // If review mode is active AND OTP matches the
                                  // static review OTP, authenticate via the
                                  // dedicated review service — no Firestore phone
                                  // query, no Firebase Auth sign-in.
                                  // -------------------------------------------
                                  if (controller.isReviewMode.value &&
                                      GooglePlayReviewConfig.isReviewOtp(
                                          controller.otpController.value.text)) {
                                    debugPrint(
                                      '[GOOGLE PLAY REVIEW LOGIN] Correct review OTP. '
                                      'Authenticating reviewer...',
                                    );
                                    ShowToastDialog.closeLoader();

                                    final reviewerModel =
                                        await GooglePlayReviewAuthService
                                            .authenticateReviewer();

                                    if (reviewerModel != null) {
                                      Get.offAll(const DashBoardScreen());
                                    } else {
                                      ShowToastDialog.showToast(
                                          'Review login failed. Please try again.');
                                    }
                                    return; // do NOT fall through to normal flow
                                  }
                                  // -------------------------------------------
                                  // Normal OTP verification continues below
                                  // -------------------------------------------

                                  // Verify OTP locally
                                  if (controller.verifyOTP(
                                      controller.otpController.value.text)) {
                                    // OTP is correct
                                    ShowToastDialog.closeLoader();

                                    if (controller.isLogin.value) {
                                      // Login flow - get existing user by phone number
                                      UserModel? userModel =
                                          await AuthUtils.getUserByPhoneNumber(
                                              controller.countryCode.value,
                                              controller.phoneNumber.value);
                                      if (userModel != null) {
                                        if (userModel.isActive == true) {
                                          // Save user ID to local storage for session
                                          await AuthUtils.setCurrentUid(
                                              userModel.id!);

                                          // Initialize FCM token manager
                                          try {
                                            await FcmTokenManager
                                                .saveCurrentToken();
                                            debugPrint(
                                                "FCM token saved for existing phone user");
                                          } catch (e) {
                                            debugPrint(
                                                "Failed to save FCM token: $e");
                                          }

                                          Get.offAll(const DashBoardScreen());
                                          // Handle pending deep link after login
                                          await DeepLinkService.handlePendingLink();
                                        } else {
                                          ShowToastDialog.showToast(
                                              "This user is disable please contact administrator"
                                                  .tr);
                                        }
                                      } else {
                                        ShowToastDialog.showToast(
                                            "User not found".tr);
                                      }
                                    } else {
                                      // Signup flow - create new user with secure UUID
                                      String generatedUserId =
                                          controller.generateUserId();
                                      UserModel newUserModel = UserModel();
                                      newUserModel.id = generatedUserId;
                                      newUserModel.countryCode =
                                          controller.countryCode.value;
                                      newUserModel.phoneNumber =
                                          controller.phoneNumber.value;
                                      newUserModel.loginType =
                                          Constant.phoneLoginType;
                                      // FCM token will be saved after account creation

                                      Get.off(const InformationScreen(),
                                          arguments: {
                                            "userModel": newUserModel,
                                          });
                                    }
                                  } else {
                                    // OTP is incorrect
                                    ShowToastDialog.closeLoader();
                                    ShowToastDialog.showToast(
                                        "Invalid Code".tr);
                                  }
                                } else {
                                  ShowToastDialog.showToast(
                                      "Enter Valid otp".tr);
                                }
                              },
                            ),
                            const SizedBox(
                              height: 40,
                            ),
                            Text.rich(
                              textAlign: TextAlign.start,
                              TextSpan(
                                text: "${'Didn’t receive any code? '.tr} ",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  fontFamily: AppThemeData.medium,
                                  color: themeChange.getThem()
                                      ? AppThemeData.grey100
                                      : AppThemeData.grey800,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        controller.otpController.value.clear();
                                        controller.sendOTP();
                                      },
                                    text: 'Send Again'.tr,
                                    style: TextStyle(
                                        color: themeChange.getThem()
                                            ? AppThemeData.primary300
                                            : AppThemeData.primary300,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        fontFamily: AppThemeData.medium,
                                        decoration: TextDecoration.underline,
                                        decorationColor:
                                            AppThemeData.primary300),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
            ),
          );
        });
  }
}
