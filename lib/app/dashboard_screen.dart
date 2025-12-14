import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:poolmate/controller/dashboard_controller.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<DashboardScreenController>(
        init: DashboardScreenController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.grey800
                : AppThemeData.grey100,
            body: SafeArea(
              child: controller.pageList[controller.selectedIndex.value],
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              showSelectedLabels: true,
              selectedFontSize: 12,
              selectedLabelStyle:
                  const TextStyle(fontFamily: AppThemeData.bold),
              unselectedLabelStyle:
                  const TextStyle(fontFamily: AppThemeData.bold),
              currentIndex: controller.selectedIndex.value,
              backgroundColor: themeChange.getThem()
                  ? AppThemeData.grey900
                  : AppThemeData.grey50,
              selectedItemColor: themeChange.getThem()
                  ? AppThemeData.primary300
                  : AppThemeData.primary300,
              unselectedItemColor: themeChange.getThem()
                  ? AppThemeData.grey300
                  : AppThemeData.grey600,
              onTap: (int index) {
                controller.selectedIndex.value = index;
              },
              items: [
                navigationBarItem(
                  themeChange,
                  index: 0,
                  assetIcon: "assets/icons/ic_car.svg",
                  label: 'Search'.tr,
                  controller: controller,
                ),
                navigationBarItem(
                  themeChange,
                  index: 1,
                  assetIcon: "assets/icons/ic_my_ride.svg",
                  label: 'My Rides'.tr,
                  controller: controller,
                ),
                navigationBarItem(
                  themeChange,
                  index: 2,
                  assetIcon: "assets/icons/ic_wallet.svg",
                  label: 'Wallet'.tr,
                  controller: controller,
                ),
                navigationBarItem(
                  themeChange,
                  index: 3,
                  assetIcon: "assets/icons/ic_inbox.svg",
                  label: 'Inbox'.tr,
                  controller: controller,
                ),
                navigationBarItem(
                  themeChange,
                  index: 4,
                  assetIcon: "assets/icons/ic_user.svg",
                  label: 'Profile'.tr,
                  controller: controller,
                ),
              ],
            ),
          );
        });
  }

  BottomNavigationBarItem navigationBarItem(themeChange,
      {required int index,
      required String label,
      required String assetIcon,
      required DashboardScreenController controller}) {
    // Cap the unread count for display (e.g., 99+)
    final int unread = int.tryParse(controller.count.value) ?? 0;
    final int unreadble = unread - 1;
    final String unreadLabel = unreadble > 99 ? "99+" : unreadble.toString();
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: SizedBox(
          width: 40,
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 9,
                top: 4,
                child: SvgPicture.asset(
                  assetIcon,
                  height: 22,
                  width: 22,
                  color: controller.selectedIndex.value == index
                      ? themeChange.getThem()
                          ? AppThemeData.primary300
                          : AppThemeData.primary300
                      : themeChange.getThem()
                          ? AppThemeData.grey300
                          : AppThemeData.grey600,
                ),
              ),
              index == 3 && unread > 0
                  ? unreadble > 0
                      ? Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppThemeData.primary300,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.white, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            child: Center(
                              child: Text(
                                unreadLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: AppThemeData.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : SizedBox()
                  : const SizedBox(),
            ],
          ),
        ),
      ),
      label: label,
    );
  }
}
