import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/add_vehicle/add_vehicle_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/controller/vehicle_list_controller.dart';
import 'package:poolmate/model/vehicle_information_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class VehicleListScreen extends StatelessWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: VehicleListController(),
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
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              leading: InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
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
                "Vehicles".tr,
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
            body: controller.isLoading.value
                ? Center(child: Constant.loader())
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Column(
                      children: [
                        controller.userVehicleList.isEmpty
                            ? const SizedBox()
                            : ListView.builder(
                                itemCount: controller.userVehicleList.length,
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemBuilder: (context, index) {
                                  VehicleInformationModel
                                      vehicleInformationModel =
                                      controller.userVehicleList[index];
                                  return InkWell(
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      log("CLICK::1");
                                      await Get.to(const AddVehicleScreen(),
                                          arguments: {
                                            "vehicleInformationModel":
                                                vehicleInformationModel
                                          })?.then(
                                        (value) async {
                                          if (value != null) {
                                            await controller
                                                .getVehicleInformation();
                                          }
                                        },
                                      );
                                    },
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                  "assets/icons/ic_vehicle_icon.svg"),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${vehicleInformationModel.licensePlatNumber}"
                                                          .tr,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: themeChange
                                                                  .getThem()
                                                              ? AppThemeData
                                                                  .grey100
                                                              : AppThemeData
                                                                  .grey800,
                                                          fontFamily:
                                                              AppThemeData
                                                                  .bold),
                                                    ),
                                                    Text(
                                                      "${vehicleInformationModel.vehicleBrand!.name} (${vehicleInformationModel.vehicleModel!.name})"
                                                          .tr,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: TextStyle(
                                                          color: themeChange
                                                                  .getThem()
                                                              ? AppThemeData
                                                                  .grey100
                                                              : AppThemeData
                                                                  .grey800,
                                                          fontFamily:
                                                              AppThemeData
                                                                  .medium),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                  Icons.chevron_right_outlined)
                                            ],
                                          ),
                                        ),
                                        const Divider(),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            log("CLICK::2");
                            await Get.to(const AddVehicleScreen())?.then(
                              (value) async {
                                if (value != null) {
                                  await controller.getVehicleInformation();
                                }
                              },
                            );
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.add,
                                color: AppThemeData.primary300,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Add Vehicle".tr,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    color: themeChange.getThem()
                                        ? AppThemeData.primary300
                                        : AppThemeData.primary300,
                                    fontFamily: AppThemeData.bold,
                                    fontSize: 14),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        });
  }
}
