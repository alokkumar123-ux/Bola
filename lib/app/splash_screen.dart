import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/controller/splash_controller.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder<SplashController>(
      init: SplashController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppThemeData.primary300,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/ic_logo.png",
                  height: 120,
                ),
                const SizedBox(
                  height: 30,
                ),
                Text(
                  "Bola".tr,
                  style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey50, fontSize: 28, fontFamily: AppThemeData.bold),
                ),
                Text(
                  "Let's move together".tr,
                  style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey50),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
