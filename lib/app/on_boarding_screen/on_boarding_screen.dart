import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/on_boarding_screen/get_started_screen.dart';
import 'package:poolmate/controller/on_boarding_controller.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/utils/network_image_widget.dart';
import 'package:poolmate/utils/preferences.dart';
import 'package:provider/provider.dart';

import '../../constant/constant.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<OnBoardingController>(
        init: OnBoardingController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.grey900
                : AppThemeData.grey50,
            body: SafeArea(
                child: controller.isLoading.value
                    ? Center(child: Constant.loader())
                    : controller.onBoardingList.isEmpty
                        ? _EmptyOnboardingState(
                            onRetry: () => controller.getOnBoardingData(),
                          )
                        : Padding(
                            padding: EdgeInsets.only(
                              top: 20,
                              left: 0,
                              right: 0,
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 20,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: Responsive.height(12, context)),
                                  child: _OnboardingImage(
                                    imagePath: controller
                                        .onBoardingList[
                                            controller.selectedPageIndex.value]
                                        .image,
                                    width: Responsive.width(100, context),
                                    height: Responsive.height(45, context),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: PageView.builder(
                                        controller: controller.pageController,
                                        onPageChanged:
                                            controller.selectedPageIndex.call,
                                        itemCount:
                                            controller.onBoardingList.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 30),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  controller
                                                      .onBoardingList[index]
                                                      .title
                                                      .toString()
                                                      .tr,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: themeChange.getThem()
                                                        ? AppThemeData.grey50
                                                        : AppThemeData.grey900,
                                                    fontSize: 28,
                                                    fontFamily:
                                                        AppThemeData.bold,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                Text(
                                                  controller
                                                      .onBoardingList[index]
                                                      .description
                                                      .toString()
                                                      .tr,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: AppThemeData.grey700,
                                                    fontSize: 16,
                                                    fontFamily:
                                                        AppThemeData.regular,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                  ),
                                ),
                                SizedBox(
                                  height: Responsive.height(4, context),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      controller.onBoardingList.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        width: controller
                                                    .selectedPageIndex.value ==
                                                index
                                            ? 38
                                            : 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: controller.selectedPageIndex
                                                      .value ==
                                                  index
                                              ? Colors.black
                                              : AppThemeData.grey300,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20.0)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: Responsive.height(4, context),
                                ),
                                // const SizedBox(height: 20),
                              ],
                            ),
                          )),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                child: Row(
                  children: [
                    controller.selectedPageIndex.value == 2
                        ? const SizedBox()
                        : Expanded(
                            child: RoundedButtonFill(
                              title: "Skip".tr,
                              color: AppThemeData.grey200,
                              textColor: AppThemeData.grey800,
                              onPress: () {
                                if (controller.selectedPageIndex.value == 2) {
                                  Preferences.setBoolean(
                                      Preferences.isFinishOnBoardingKey, true);
                                  Get.offAll(const GetStartedScreen());
                                } else {
                                  controller.pageController.jumpToPage(
                                      controller.selectedPageIndex.value + 1);
                                }
                              },
                            ),
                          ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: RoundedButtonFill(
                        title: controller.selectedPageIndex.value == 2
                            ? "Get Started".tr
                            : "Next".tr,
                        color: Colors.black,
                        textColor: AppThemeData.grey50,
                        onPress: () {
                          if (controller.selectedPageIndex.value == 2) {
                            Preferences.setBoolean(
                                Preferences.isFinishOnBoardingKey, true);
                            Get.offAll(const GetStartedScreen());
                          } else {
                            controller.pageController.jumpToPage(
                                controller.selectedPageIndex.value + 1);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}

class _OnboardingImage extends StatelessWidget {
  final String? imagePath;
  final double width;
  final double height;

  const _OnboardingImage(
      {required this.imagePath, required this.width, required this.height});

  bool _isSvg(String path) {
    return path.toLowerCase().endsWith('.svg');
  }

  @override
  Widget build(BuildContext context) {
    final path = imagePath ?? '';
    final isNetwork = path.startsWith('http');
    final isSvg = _isSvg(path);

    if (path.isEmpty) {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported),
      );
    }

    // Handle SVG images
    if (isSvg) {
      if (isNetwork) {
        return SvgPicture.network(
          path,
          width: width,
          height: height,
          fit: BoxFit.cover,
          placeholderBuilder: (context) => Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
        );
      } else {
        return SvgPicture.asset(
          path,
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      }
    }

    // Handle raster images (PNG, JPEG, etc.)
    if (isNetwork) {
      return NetworkImageWidget(
        imageUrl: path,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }

    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }
}

class _EmptyOnboardingState extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyOnboardingState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppThemeData.grey500),
            const SizedBox(height: 16),
            const Text(
              'Unable to load onboarding content.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppThemeData.grey800),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            RoundedButtonFill(
              title: 'Retry',
              color: Colors.black,
              textColor: AppThemeData.grey50,
              onPress: onRetry,
            )
          ],
        ),
      ),
    );
  }
}
