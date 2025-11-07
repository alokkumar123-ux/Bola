import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
import 'package:poolmate/utils/fire_store_utils.dart';
import 'package:poolmate/utils/notification_service.dart';
import 'package:provider/provider.dart';

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
            body: controller.isLoading.value
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
                          const SizedBox(
                            height: 40,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
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
                            color: AppThemeData.primary300,
                            textColor: AppThemeData.grey50,
                            onPress: () async {
                              if (controller.otpController.value.text.length ==
                                  6) {
                                ShowToastDialog.showLoader("Verify otp".tr);

                                PhoneAuthCredential credential =
                                    PhoneAuthProvider.credential(
                                        verificationId:
                                            controller.verificationId.value,
                                        smsCode: controller
                                            .otpController.value.text);
                                String fcmToken = '';
                                try {
                                  fcmToken =
                                      await NotificationService.getToken();
                                } catch (e) {
                                  debugPrint(
                                      "Failed to get FCM token during phone verification: $e");
                                  // Continue with verification even if FCM token fails
                                }
                                await FirebaseAuth.instance
                                    .signInWithCredential(credential)
                                    .then((value) async {
                                  if (value.additionalUserInfo!.isNewUser) {
                                    UserModel userModel = UserModel();
                                    userModel.id = value.user!.uid;
                                    userModel.countryCode =
                                        controller.countryCode.value;
                                    userModel.phoneNumber =
                                        controller.phoneNumber.value;
                                    userModel.loginType =
                                        Constant.phoneLoginType;
                                    userModel.fcmToken = fcmToken;

                                    ShowToastDialog.closeLoader();
                                    Get.off(const InformationScreen(),
                                        arguments: {
                                          "userModel": userModel,
                                        });
                                  } else {
                                    await FireStoreUtils.userExistOrNot(
                                            value.user!.uid)
                                        .then((userExit) async {
                                      ShowToastDialog.closeLoader();
                                      if (userExit == true) {
                                        UserModel? userModel =
                                            await FireStoreUtils.getUserProfile(
                                                value.user!.uid);
                                        if (userModel != null) {
                                          if (userModel.isActive == true) {
                                            // Update FCM token for existing user on phone login with error handling
                                            try {
                                              String fcmToken =
                                                  await NotificationService
                                                      .getToken();
                                              userModel.fcmToken = fcmToken;
                                              await FireStoreUtils.updateUser(
                                                  userModel);
                                              debugPrint(
                                                  "FCM token updated for existing phone user: $fcmToken");
                                            } catch (e) {
                                              debugPrint(
                                                  "Failed to update FCM token for existing phone user: $e");
                                              // Continue with login even if FCM token update fails
                                            }

                                            Get.offAll(const DashBoardScreen());
                                          } else {
                                            await FirebaseAuth.instance
                                                .signOut();
                                            ShowToastDialog.showToast(
                                                "This user is disable please contact administrator"
                                                    .tr);
                                          }
                                        }
                                      } else {
                                        UserModel userModel = UserModel();
                                        userModel.id = value.user!.uid;
                                        userModel.countryCode =
                                            controller.countryCode.value;
                                        userModel.phoneNumber =
                                            controller.phoneNumber.value;
                                        userModel.loginType =
                                            Constant.phoneLoginType;
                                        userModel.fcmToken = fcmToken;

                                        Get.off(const InformationScreen(),
                                            arguments: {
                                              "userModel": userModel,
                                            });
                                      }
                                    });
                                  }
                                }).catchError((error) {
                                  ShowToastDialog.closeLoader();
                                  ShowToastDialog.showToast("Invalid Code".tr);
                                });
                              } else {
                                ShowToastDialog.showToast("Enter Valid otp".tr);
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
                                      decorationColor: AppThemeData.primary300),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
          );
        });
  }
}
