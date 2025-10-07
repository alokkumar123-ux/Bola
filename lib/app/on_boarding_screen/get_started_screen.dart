import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/auth_screen/login_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/utils/network_image_widget.dart';
import 'package:provider/provider.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
      body: Column(
        children: [
          NetworkImageWidget(
            filterQuality: FilterQuality.high,
            imageUrl: themeChange.getThem() ? Constant.appBannerImageDark : Constant.appBannerImageLight,
            fit: BoxFit.fill,
            width: Responsive.width(100, context),
            height: Responsive.height(50, context),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Welcome to \n Bola".tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                      fontSize: 28,
                      fontFamily: AppThemeData.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "Let’s get Started".tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppThemeData.grey700,
                      fontSize: 16,
                      fontFamily: AppThemeData.regular,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  RoundedButtonFill(
                    title: "Sign up".tr,
                    width: Responsive.width(14, context),
                    color: AppThemeData.primary300,
                    textColor: AppThemeData.grey50,
                    onPress: () {
                      Get.to(const LoginScreen(), arguments: {"isLogin": false}, transition: Transition.downToUp);
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  RoundedButtonFill(
                    title: "Log in".tr,
                    width: Responsive.width(14, context),
                    color: AppThemeData.grey200,
                    textColor: AppThemeData.grey800,
                    onPress: () {
                      Get.to(const LoginScreen(), arguments: {"isLogin": true}, transition: Transition.downToUp);
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
