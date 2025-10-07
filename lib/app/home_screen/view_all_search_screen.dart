import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/home_screen/datepicker_screen.dart';
import 'package:poolmate/app/home_screen/home_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/controller/view_all_search_controller.dart';
import 'package:poolmate/model/recent_search_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class ViewAllSearchScreen extends StatelessWidget {
  const ViewAllSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: ViewAllSearchController(),
        builder: (controller) {
          return Scaffold(
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
                "Recent Searches".tr,
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey100
                        : AppThemeData.grey800,
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 16),
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
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: controller.isLoading.value
                  ? Center(child: Constant.loader())
                  : ListView.separated(
                      separatorBuilder: (context, index) =>
                          const Padding(padding: EdgeInsets.only(bottom: 10)),
                      shrinkWrap: true,
                      itemCount: controller.recentSearch.length,
                      itemBuilder: (context, index) {
                        RecentSearchModel recentSearchModel =
                            controller.recentSearch[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: InkWell(
                              onTap: () {
                                if (recentSearchModel.bookedDate!
                                    .toDate()
                                    .isBefore(DateTime.now()
                                        .subtract(const Duration(days: 1)))) {
                                  Get.to(const DatepickerScreen(),
                                          transition: Transition.downToUp)
                                      ?.then((date) {
                                    if (date is DateTime) {
                                      Get.back(result: {
                                        'recentSearchModel': recentSearchModel,
                                        'date': date
                                      });
                                    }
                                  });
                                } else {
                                  Get.back(result: {
                                    'recentSearchModel': recentSearchModel,
                                    'date':
                                        recentSearchModel.bookedDate!.toDate()
                                  });
                                }
                              },
                              child: recentSearchWidget(
                                  recentSearchModel: recentSearchModel,
                                  themeChange: themeChange)),
                        );
                      },
                    ),
            ),
          );
        });
  }
}
