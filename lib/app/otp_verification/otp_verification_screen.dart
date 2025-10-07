import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/controller/otp_verification_controller.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
      init: OtpVerificationController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.getThem()
              ? AppThemeData.grey800
              : AppThemeData.grey100,
          appBar: AppBar(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.grey900
                : AppThemeData.grey50,
            centerTitle: false,
            titleSpacing: 0,
            leading: InkWell(
              onTap: () {
                Get.back();
              },
              child: Icon(
                Icons.chevron_left_outlined,
                color: themeChange.getThem()
                    ? AppThemeData.grey50
                    : AppThemeData.grey900,
              ),
            ),
            title: Text(
              "Verify Passenger".tr,
              style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey100
                    : AppThemeData.grey800,
                fontFamily: AppThemeData.semiBold,
                fontSize: 16,
              ),
            ),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4.0),
              child: Container(
                color: themeChange.getThem()
                    ? AppThemeData.grey700
                    : AppThemeData.grey200,
                height: 4.0,
              ),
            ),
          ),
          body: controller.isLoading.value
              ? Center(child: Constant.loader())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Enter OTP".tr,
                        style: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey100
                              : AppThemeData.grey800,
                          fontFamily: AppThemeData.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please enter the OTP provided by the passenger to verify their booking."
                            .tr,
                        style: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey300
                              : AppThemeData.grey600,
                          fontFamily: AppThemeData.medium,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        "OTP".tr,
                        style: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey100
                              : AppThemeData.grey800,
                          fontFamily: AppThemeData.semiBold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeChange.getThem()
                                ? AppThemeData.grey600
                                : AppThemeData.grey300,
                          ),
                          color: themeChange.getThem()
                              ? AppThemeData.grey700
                              : AppThemeData.grey50,
                        ),
                        child: TextFormField(
                          controller: controller.otpController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey100
                                : AppThemeData.grey800,
                            fontFamily: AppThemeData.medium,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter 6-digit OTP".tr,
                            hintStyle: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey400
                                  : AppThemeData.grey500,
                              fontFamily: AppThemeData.medium,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Spacer(),
                      RoundedButtonFill(
                        title: "Verify OTP".tr,
                        color: AppThemeData.primary300,
                        textColor: AppThemeData.grey50,
                        onPress: () {
                          controller.verifyOtp();
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
