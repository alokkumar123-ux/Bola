import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/accessibility/accessibility_screen.dart';
import 'package:poolmate/app/add_vehicle/vehicle_list_screen.dart';
import 'package:poolmate/app/edit_profile/edit_profile_screen.dart';
import 'package:poolmate/app/help_support_screen/help_support_screen.dart';
import 'package:poolmate/app/webview_screen.dart';
import 'package:poolmate/app/on_boarding_screen/get_started_screen.dart';
import 'package:poolmate/app/rating_view_screen/rating_view_screen.dart';
import 'package:poolmate/app/travel_preference/travel_preference_screen.dart';
import 'package:poolmate/app/verification_screen/verification_screen.dart';
import 'package:poolmate/app/withdraw_payment_setup_screen/payment_setup_screen.dart';
import 'package:poolmate/app/referral/referral_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/controller/profile_controller.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/custom_dialog_box.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/utils/network_image_widget.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/services/fcm_token_manager.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:poolmate/widgets/app_tutorial_tooltip.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: ProfileController(),
        builder: (controller) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (controller.isLoading.value) return;
            if (controller.hasShownSosDialog) return;

            final user = controller.userModel.value;
            final sosNumbers = user.sosWhatsAppNumbers;
            final hasValidNumber = sosNumbers != null &&
                sosNumbers.any((n) => n.trim().isNotEmpty);
            if (!hasValidNumber) {
              controller.hasShownSosDialog = true;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    title: Text('SOS WhatsApp Number Required'),
                    content: Text(
                        'Please enter your SOS WhatsApp number(s) in your profile for safety.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Get.to(const EditProfileScreen(), arguments: {'scrollToBottom': true})?.then((value) {
                            controller.hasShownSosDialog = false;
                            controller.getData();
                          });
                        },
                        child: Text('Go to Edit Profile'),
                      ),
                    ],
                  );
                },
              );
            }
            if (controller.isTutorialAvailable.value && !ProfileController.hasShownTutorialThisSession) {
              ProfileController.hasShownTutorialThisSession = true;
              if (controller.tutorialKey.currentContext != null) {
                await Scrollable.ensureVisible(
                  controller.tutorialKey.currentContext!,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
                // Show tooltip after scrolling
                controller.showTutorialTooltip.value = true;
              }
            }
          });
          return Scaffold(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.grey800
                : AppThemeData.grey100,
            appBar: AppBar(
              backgroundColor: themeChange.getThem()
                  ? AppThemeData.grey900
                  : AppThemeData.grey50,
              centerTitle: false,
              automaticallyImplyLeading: false,
              title: Text(
                "Profile".tr,
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey100
                        : AppThemeData.grey800,
                    fontFamily: AppThemeData.bold,
                    fontSize: 18),
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
            body: SafeArea(
              child: controller.isLoading.value
                  ? Center(child: Constant.loader())
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 30),
                      child: SingleChildScrollView(
                        controller: controller.scrollController,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: NetworkImageWidget(
                                fit: BoxFit.cover,
                                imageUrl: controller.userModel.value.profilePic
                                    .toString(),
                                height: Responsive.width(24, context),
                                width: Responsive.width(24, context),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${controller.userModel.value.fullName()}",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontFamily: AppThemeData.medium,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey900),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      Constant.calculateReview(
                                          reviewCount: controller
                                              .userModel.value.reviewCount,
                                          reviewSum: controller
                                              .userModel.value.reviewSum),
                                      style: TextStyle(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey200
                                              : AppThemeData.grey700,
                                          fontFamily: AppThemeData.medium,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(
                                      width: 2,
                                    ),
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey200
                                          : AppThemeData.grey700,
                                    ),
                                    const SizedBox(
                                      width: 2,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Get.to(const RatingViewScreen(),
                                            arguments: {
                                              "receiverUserId":
                                                  controller.userModel.value.id
                                            });
                                      },
                                      child: Text(
                                        "${double.parse(controller.userModel.value.reviewCount ?? "0").toStringAsFixed(0)} Ratings",
                                        style: TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AppThemeData.primary300,
                                            color: themeChange.getThem()
                                                ? AppThemeData.primary300
                                                : AppThemeData.primary300,
                                            fontFamily: AppThemeData.medium,
                                            fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            InkWell(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () {
                                Get.to(const EditProfileScreen())!
                                    .then((value) {
                                  if (value == true) {
                                    controller.getData();
                                  }
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Edit Profile".tr,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: AppThemeData.bold,
                                        color: themeChange.getThem()
                                            ? AppThemeData.primary300
                                            : AppThemeData.primary300,
                                        decoration: TextDecoration.underline,
                                        decorationColor:
                                            AppThemeData.primary300),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppThemeData.primary300,
                                    fill: 1,
                                    size: 22,
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 32,
                            ),

                            menuItemWidget(
                              onTap: () {
                                Get.to(VerificationScreen(
                                    usermodel: controller.userModel.value));
                              },
                              title: "Account Verification".tr,
                              subTitle:
                                  'Verify your account and update the documents'
                                      .tr,
                              svgImage: "assets/icons/ic_account_setting.svg",
                              themeChange: themeChange,
                              isVerified:
                                  controller.userModel.value.aadharVerified ==
                                      true,
                            ),
                            menuItemWidget(
                              onTap: () {
                                Get.to(const PaymentSetupScreen());
                              },
                              title: "Withdraw Methods".tr,
                              subTitle:
                                  'Manage your transaction via bank account details'
                                      .tr,
                              svgImage: "assets/icons/ic_bank_account.svg",
                              themeChange: themeChange,
                            ),
                            menuItemWidget(
                              onTap: () {
                                Get.to(const VehicleListScreen());
                              },
                              title: "Vehicles".tr,
                              subTitle: 'Manage your traveling vehicle'.tr,
                              svgImage: "assets/icons/ic_car.svg",
                              themeChange: themeChange,
                            ),
                            menuItemWidget(
                              onTap: () {
                                Get.to(const TravelPreferenceScreen());
                              },
                              title: "Travel Preference".tr,
                              subTitle:
                                  'Discover Your Ideal Travel Destination Based on Personal Preferences'
                                      .tr,
                              svgImage: "assets/icons/ic_wallet.svg",
                              themeChange: themeChange,
                            ),
                            menuItemWidget(
                              onTap: () {
                                Get.to(const AccessibilityScreen());
                              },
                              title: "Accessibility".tr,
                              subTitle: 'Language, mode change and more'.tr,
                              svgImage: "assets/icons/ic_settings.svg",
                              themeChange: themeChange,
                            ),
                            menuItemWidget(
                              onTap: () {
                                Get.to(HelpSupportScreen());
                              },
                              title: "Help & Contact".tr,
                              subTitle:
                                  'Manage user queries and resolve issues efficiently from the admin panel.'
                                      .tr,
                              svgImage: "assets/icons/ic_shield.svg",
                              themeChange: themeChange,
                            ),
                            menuItemWidget(
                              onTap: () {
                                Get.to(WebViewScreen(
                                  url: 'https://bolaletsgo.com/privacy.html',
                                ));
                              },
                              title: "Privacy Policy".tr,
                              subTitle: 'View our privacy policy.'.tr,
                              svgImage: "assets/icons/ic_document.svg",
                              themeChange: themeChange,
                            ),
                            menuItemWidget(
                              onTap: () {
                                Get.to(WebViewScreen(
                                  url: 'https://bolaletsgo.com/terms.html',
                                ));
                              },
                              title: "Terms & Conditions".tr,
                              subTitle: 'View our terms and conditions.'.tr,
                              svgImage: "assets/icons/ic_cancel.svg",
                              themeChange: themeChange,
                            ),
                            menuItemWidget(
                              onTap: () {
                                Get.to(WebViewScreen(
                                  url: 'https://bolaletsgo.com/refund.html',
                                ));
                              },
                              title: "Refund & Cancellation Policy".tr,
                              subTitle:
                                  'View our refund & cancellation policy.'.tr,
                              svgImage: "assets/icons/ic_help_support.svg",
                              themeChange: themeChange,
                            ),
                            menuItemWidget(
                              onTap: () {
                                Get.to(const ReferralScreen());
                              },
                              title: "Referral Program".tr,
                              subTitle: 'Invite friends and earn rewards'.tr,
                              svgImage: "assets/icons/ic_wallet.svg",
                              themeChange: themeChange,
                            ),
                            menuItemWidget(
                              onTap: () {
                                Get.to(WebViewScreen(
                                  url: 'https://bolaletsgo.com/#faq',
                                ));
                              },
                              title: "FAQ".tr,
                              subTitle: 'Frequently asked questions'.tr,
                              svgImage: "assets/icons/ic_help_support.svg",
                              themeChange: themeChange,
                            ),
                            AppTutorialTooltip(
                              key: controller.tutorialKey,
                              onWatch: () async {
                                final Uri url = Uri.parse(
                                    'https://www.youtube.com/watch?v=DE_4jamwYac&list=PLVHZUxZWcQfyNVPVN_YqBm8_cA0s4kaIi');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              onSkip: () {
                                // Just hide, handled in the widget
                              },
                              child: menuItemWidget(
                                onTap: () async {
                                  final Uri url = Uri.parse(
                                      'https://www.youtube.com/watch?v=DE_4jamwYac&list=PLVHZUxZWcQfyNVPVN_YqBm8_cA0s4kaIi');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                                title: "App Tutorial".tr,
                                subTitle: 'Learn how to use the app'.tr,
                                svgImage: "assets/icons/ic_document.svg",
                                themeChange: themeChange,
                              ),
                            ),
                            InkWell(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return CustomDialogBox(
                                        title: "Log out".tr,
                                        descriptions:
                                            "You will be signed out of the app. Tap Log Out to confirm."
                                                .tr,
                                        positiveString: "Log out".tr,
                                        negativeString: "Cancel".tr,
                                        positiveClick: () async {
                                          // Deactivate FCM token before logout
                                          await FcmTokenManager.instance
                                              .deactivateCurrentDeviceToken();
                                          // Clear local user ID
                                          await AuthUtils.clearCurrentUid();
                                          // Sign out from Firebase if signed in
                                          if (FirebaseAuth
                                                  .instance.currentUser !=
                                              null) {
                                            await FirebaseAuth.instance
                                                .signOut();
                                          }
                                          Get.offAll(const GetStartedScreen());
                                        },
                                        negativeClick: () {
                                          Get.back();
                                        },
                                        img: Image.asset(
                                          'assets/images/ic_logout_dialog.png',
                                          height: 40,
                                          width: 40,
                                        ),
                                      );
                                    });
                              },
                              child: Row(
                                children: [
                                  Container(
                                    height: 46,
                                    width: 46,
                                    decoration: BoxDecoration(
                                        color: themeChange.getThem()
                                            ? AppThemeData.warning50
                                            : AppThemeData.warning50,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(30))),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: SvgPicture.asset(
                                        'assets/icons/ic_logout.svg',
                                        color: themeChange.getThem()
                                            ? AppThemeData.warning300
                                            : AppThemeData.warning300,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    "Log out".tr,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: AppThemeData.bold,
                                        color: themeChange.getThem()
                                            ? AppThemeData.warning300
                                            : AppThemeData.warning300),
                                  ),
                                ],
                              ),
                            )
                            // menuItemWidget(
                            //   onTap: () {},
                            //   title: "Account Verification",
                            //   subTitle: 'Verify your account and update the documents',
                            //   svgImage: "assets/icons/ic_account_setting.svg",
                            //   themeChange: themeChange,
                            // ),
                            // menuItemWidget(
                            //   onTap: () {},
                            //   title: "Ride Statics",
                            //   subTitle: 'Ratting, reviews and more',
                            //   svgImage: "assets/icons/ic_account_setting.svg",
                            //   themeChange: themeChange,
                            // ),
                          ],
                        ),
                      ),
                    ),
            ),
          );
        });
  }

  Widget menuItemWidget({
    required String svgImage,
    required String title,
    required String subTitle,
    required VoidCallback onTap,
    required themeChange,
    bool isVerified = false,
  }) {
    return Column(
      children: [
        InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                    color: themeChange.getThem()
                        ? AppThemeData.grey800
                        : AppThemeData.grey100,
                    borderRadius: const BorderRadius.all(Radius.circular(30))),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset(
                    svgImage,
                    color: themeChange.getThem()
                        ? AppThemeData.grey200
                        : AppThemeData.grey700,
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                              fontSize: 16,
                              fontFamily: AppThemeData.bold,
                              color: themeChange.getThem()
                                  ? AppThemeData.grey100
                                  : AppThemeData.grey800),
                        ),
                      ],
                    ),
                    Text(
                      subTitle,
                      maxLines: 2,
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppThemeData.regular,
                          color: themeChange.getThem()
                              ? AppThemeData.grey300
                              : AppThemeData.grey600),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: AppThemeData.success400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Verified as Passenger",
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: AppThemeData.medium,
                              color: AppThemeData.success400,
                            ),
                          ),
                        ],
                      )
                    ],
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppThemeData.grey500,
              )
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Divider(),
        ),
      ],
    );
  }
}
