import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/add_vehicle_controller.dart';
import 'package:poolmate/model/vehicle_brand_model.dart';
import 'package:poolmate/model/vehicle_model.dart';
import 'package:poolmate/model/vehicle_type_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/themes/text_field_widget.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/utils/network_image_widget.dart';
import 'package:provider/provider.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<AddVehicleController>(
        init: AddVehicleController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.grey900
                : AppThemeData.grey50,
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
                "Add Vehicle Information".tr,
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey100
                        : AppThemeData.grey800,
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 16),
              ),
              elevation: 0,
              actions: [
                Get.arguments == null
                    ? const SizedBox()
                    : InkWell(
                        onTap: () {
                          controller.deleteVehicle();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.delete,
                            color: AppThemeData.warning300,
                          ),
                        ),
                      )
              ],
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
                ? Center(
                    child: Center(
                        child: Center(child: Center(child: Constant.loader()))))
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFieldWidget(
                                  hintText:
                                      'Enter Vehicle Registration Number'.tr,
                                  controller: controller
                                      .licensePlatNumberController.value,
                                  title: 'Vehicle Registration Number'.tr,
                                  enable: !controller.isRcVerified.value,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Obx(() => controller.isRcVerified.value
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppThemeData.success300,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Verified".tr,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: () async {
                                        if (controller
                                            .licensePlatNumberController
                                            .value
                                            .text
                                            .isEmpty) {
                                          ShowToastDialog.showToast(
                                              "Please enter vehicle registration number"
                                                  .tr);
                                          return;
                                        }

                                        // Show loading while checking
                                        ShowToastDialog.showLoader(
                                            "Checking vehicle number...".tr);

                                        // Check if vehicle number already exists
                                        final vehicleExists = await controller
                                            .checkVehicleNumberExists(controller
                                                .licensePlatNumberController
                                                .value
                                                .text);

                                        ShowToastDialog.closeLoader();

                                        if (vehicleExists) {
                                          ShowToastDialog.showToast(
                                              "This vehicle number is already registered"
                                                  .tr);
                                          return;
                                        }

                                        // Call API to verify RC
                                        ShowToastDialog.showLoader(
                                            "Verifying RC...".tr);

                                        final rcData = await controller
                                            .verifyRcWithApi(controller
                                                .licensePlatNumberController
                                                .value
                                                .text);

                                        ShowToastDialog.closeLoader();

                                        if (rcData != null) {
                                          controller.isRcVerified.value = true;

                                          // Show success message with RC details
                                          String message =
                                              "RC verified successfully".tr;
                                          if (rcData['rc_expiry_date'] !=
                                              null) {
                                            message +=
                                                "\nExpiry: ${rcData['rc_expiry_date']}";
                                          }
                                          if (rcData['rc_status'] != null) {
                                            message +=
                                                "\nStatus: ${rcData['rc_status']}";
                                          }
                                          ShowToastDialog.showToast(message);
                                        }
                                      },
                                      child: Text("Verify".tr)))
                            ],
                          ),
                          Obx(() => !controller.isRcVerified.value
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 14,
                                        color: AppThemeData.warning300,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "RC verification is required to save vehicle"
                                            .tr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppThemeData.warning300,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink()),
                          // Display RC Information when verified
                          Obx(() => controller.isRcVerified.value == true
                              ? Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: themeChange.getThem()
                                        ? AppThemeData.grey800
                                        : AppThemeData.grey100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppThemeData.success300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            color: AppThemeData.success300,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "RC Information".tr,
                                            style: TextStyle(
                                              fontFamily: AppThemeData.semiBold,
                                              fontSize: 14,
                                              color: themeChange.getThem()
                                                  ? AppThemeData.grey100
                                                  : AppThemeData.grey800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildRcInfoRow(
                                        "RC Status".tr,
                                        controller.vehicleInformationModel.value
                                                .rcStatus ??
                                            "N/A",
                                        themeChange,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildRcInfoRow(
                                        "RC Expiry Date".tr,
                                        controller.vehicleInformationModel.value
                                                .rcExpiryDate ??
                                            "N/A",
                                        themeChange,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildRcInfoRow(
                                        "Insurance Valid Upto".tr,
                                        controller.vehicleInformationModel.value
                                                .vehicleInsuranceUpto ??
                                            "N/A",
                                        themeChange,
                                      ),
                                      if (controller.vehicleInformationModel
                                              .value.verifiedAt !=
                                          null) ...[
                                        const SizedBox(height: 8),
                                        _buildRcInfoRow(
                                          "Verified At".tr,
                                          controller.vehicleInformationModel
                                                  .value.verifiedAt ??
                                              "N/A",
                                          themeChange,
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink()),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('What kind of vehicle is it?'.tr,
                                  style: TextStyle(
                                      fontFamily: AppThemeData.semiBold,
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey100
                                          : AppThemeData.grey800)),
                              const SizedBox(
                                height: 5,
                              ),
                              DropdownButtonFormField<VehicleTypeModel>(
                                  dropdownColor: themeChange.getThem()
                                      ? AppThemeData.grey800
                                      : AppThemeData.grey100,
                                  hint: Text(
                                    'Vehicle Type'.tr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey700
                                          : AppThemeData.grey700,
                                      fontFamily: AppThemeData.regular,
                                    ),
                                  ),
                                  decoration: InputDecoration(
                                    errorStyle:
                                        const TextStyle(color: Colors.red),
                                    isDense: true,
                                    filled: true,
                                    fillColor: themeChange.getThem()
                                        ? AppThemeData.grey800
                                        : AppThemeData.grey100,
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.primary300
                                              : AppThemeData.primary300,
                                          width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                  ),
                                  value: controller
                                              .selectedVehicleType.value.id ==
                                          null
                                      ? null
                                      : controller.selectedVehicleType.value,
                                  onChanged: (value) {
                                    controller.selectedVehicleType.value =
                                        value!;
                                    controller.update();
                                  },
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey900,
                                      fontFamily: AppThemeData.medium),
                                  items: controller.vehicleTypeModelList
                                      .map((item) {
                                    return DropdownMenuItem<VehicleTypeModel>(
                                      value: item,
                                      child: Text(item.name.toString()),
                                    );
                                  }).toList()),
                            ],
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("What's your  vehicle brand?".tr,
                                  style: TextStyle(
                                      fontFamily: AppThemeData.semiBold,
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey100
                                          : AppThemeData.grey800)),
                              const SizedBox(
                                height: 5,
                              ),
                              DropdownButtonFormField<VehicleBrandModel>(
                                  dropdownColor: themeChange.getThem()
                                      ? AppThemeData.grey800
                                      : AppThemeData.grey100,
                                  hint: Text(
                                    'Vehicle Brand'.tr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey700
                                          : AppThemeData.grey700,
                                      fontFamily: AppThemeData.regular,
                                    ),
                                  ),
                                  decoration: InputDecoration(
                                    errorStyle:
                                        const TextStyle(color: Colors.red),
                                    isDense: true,
                                    filled: true,
                                    fillColor: themeChange.getThem()
                                        ? AppThemeData.grey800
                                        : AppThemeData.grey100,
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.primary300
                                              : AppThemeData.primary300,
                                          width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                  ),
                                  value: controller
                                              .selectedVehicleBrand.value.id ==
                                          null
                                      ? null
                                      : controller.selectedVehicleBrand.value,
                                  onChanged: (value) {
                                    controller.selectedVehicleBrand.value =
                                        value!;
                                    controller.getVehicleModel(controller
                                        .selectedVehicleBrand.value.id
                                        .toString());
                                    controller.update();
                                  },
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey900,
                                      fontFamily: AppThemeData.medium),
                                  items: controller.vehicleBrandModelList
                                      .map((item) {
                                    return DropdownMenuItem<VehicleBrandModel>(
                                      value: item,
                                      child: Text(item.name.toString()),
                                    );
                                  }).toList()),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 16,
                              ),
                              Text("What your vehicle's Vehicle Model?".tr,
                                  style: TextStyle(
                                      fontFamily: AppThemeData.semiBold,
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey100
                                          : AppThemeData.grey800)),
                              const SizedBox(
                                height: 5,
                              ),
                              DropdownButtonFormField<VehicleModel>(
                                  dropdownColor: themeChange.getThem()
                                      ? AppThemeData.grey800
                                      : AppThemeData.grey100,
                                  hint: Text(
                                    'Vehicle Model'.tr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey700
                                          : AppThemeData.grey700,
                                      fontFamily: AppThemeData.regular,
                                    ),
                                  ),
                                  decoration: InputDecoration(
                                    errorStyle:
                                        const TextStyle(color: Colors.red),
                                    isDense: true,
                                    filled: true,
                                    fillColor: themeChange.getThem()
                                        ? AppThemeData.grey800
                                        : AppThemeData.grey100,
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.primary300
                                              : AppThemeData.primary300,
                                          width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                  ),
                                  value: controller
                                              .selectedVehicleModel.value.id ==
                                          null
                                      ? null
                                      : controller.selectedVehicleModel.value,
                                  onChanged: (value) {
                                    controller.selectedVehicleModel.value =
                                        value!;
                                    controller.update();
                                  },
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey900,
                                      fontFamily: AppThemeData.medium),
                                  items:
                                      controller.vehicleModelList.map((item) {
                                    return DropdownMenuItem<VehicleModel>(
                                      value: item,
                                      child: Text(item.name.toString()),
                                    );
                                  }).toList()),
                            ],
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("What's your vehicle's  color?".tr,
                                  style: TextStyle(
                                      fontFamily: AppThemeData.semiBold,
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey100
                                          : AppThemeData.grey800)),
                              const SizedBox(
                                height: 5,
                              ),
                              DropdownButtonFormField<String>(
                                  dropdownColor: themeChange.getThem()
                                      ? AppThemeData.grey800
                                      : AppThemeData.grey100,
                                  hint: Text(
                                    'Vehicle color'.tr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey700
                                          : AppThemeData.grey700,
                                      fontFamily: AppThemeData.regular,
                                    ),
                                  ),
                                  decoration: InputDecoration(
                                    errorStyle:
                                        const TextStyle(color: Colors.red),
                                    isDense: true,
                                    filled: true,
                                    fillColor: themeChange.getThem()
                                        ? AppThemeData.grey800
                                        : AppThemeData.grey100,
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.primary300
                                              : AppThemeData.primary300,
                                          width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                  ),
                                  value: controller.selectedColor.value.isEmpty
                                      ? null
                                      : controller.selectedColor.value,
                                  onChanged: (value) {
                                    controller.selectedColor.value = value!;
                                    controller.update();
                                  },
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey900,
                                      fontFamily: AppThemeData.medium),
                                  items: controller.colourList.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(item.toString()),
                                    );
                                  }).toList()),
                            ],
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          TextFieldWidget(
                            hintText: '2012',
                            controller:
                                controller.vehicleRegisterYearController.value,
                            textInputType: TextInputType.number,
                            title: 'When is your vehicle registered?'.tr,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('How many seats does your vehicle have?'.tr,
                                  style: TextStyle(
                                      fontFamily: AppThemeData.semiBold,
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey100
                                          : AppThemeData.grey800)),
                              const SizedBox(
                                height: 5,
                              ),
                              DropdownButtonFormField<int>(
                                  dropdownColor: themeChange.getThem()
                                      ? AppThemeData.grey800
                                      : AppThemeData.grey100,
                                  hint: Text(
                                    'Select seat count',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey700
                                          : AppThemeData.grey700,
                                      fontFamily: AppThemeData.regular,
                                    ),
                                  ),
                                  decoration: InputDecoration(
                                    errorStyle:
                                        const TextStyle(color: Colors.red),
                                    isDense: true,
                                    filled: true,
                                    fillColor: themeChange.getThem()
                                        ? AppThemeData.grey800
                                        : AppThemeData.grey100,
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.primary300
                                              : AppThemeData.primary300,
                                          width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          width: 1),
                                    ),
                                  ),
                                  value: controller.selectedSeatCount.value == 0
                                      ? null
                                      : controller.selectedSeatCount.value,
                                  onChanged: (value) {
                                    controller.selectedSeatCount.value = value!;
                                    controller.seatCountController.value.text =
                                        value.toString();
                                    controller.update();
                                  },
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey900,
                                      fontFamily: AppThemeData.medium),
                                  items: [2, 5, 7].map((item) {
                                    return DropdownMenuItem<int>(
                                      value: item,
                                      child: Text('$item seats'),
                                    );
                                  }).toList()),
                            ],
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          SizedBox(
                            height: 100,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: InkWell(
                                      onTap: () {
                                        buildBottomSheet(context, controller);
                                      },
                                      child: Container(
                                        width: 100,
                                        height: 100.0,
                                        decoration: BoxDecoration(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                        ),
                                        child: Icon(Icons.add,
                                            color: AppThemeData.primary300),
                                      ),
                                    ),
                                  ),
                                  ListView.builder(
                                    itemCount: controller.images.length,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(10)),
                                              child: controller.images[index]
                                                          .runtimeType ==
                                                      XFile
                                                  ? Image.file(
                                                      File(controller
                                                          .images[index].path),
                                                      fit: BoxFit.cover,
                                                      width: 100,
                                                      height: 100.0,
                                                    )
                                                  : NetworkImageWidget(
                                                      imageUrl: controller
                                                          .images[index],
                                                      fit: BoxFit.cover,
                                                      width: 100,
                                                      height: 100.0,
                                                    ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              top: 0,
                                              left: 0,
                                              right: 0,
                                              child: InkWell(
                                                onTap: () {
                                                  controller.images
                                                      .removeAt(index);
                                                },
                                                child: const Icon(
                                                  Icons.remove_circle,
                                                  size: 30,
                                                  color:
                                                      AppThemeData.warning300,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Obx(() => RoundedButtonFill(
                                title: "Save".tr,
                                color: controller.isRcVerified.value
                                    ? AppThemeData.primary300
                                    : AppThemeData.grey400,
                                textColor: AppThemeData.grey50,
                                onPress: () {
                                  // First check RC verification
                                  if (!controller.isRcVerified.value) {
                                    ShowToastDialog.showToast(
                                        "Please verify the vehicle RC first."
                                            .tr);
                                    return;
                                  }

                                  if (controller.licensePlatNumberController
                                      .value.text.isEmpty) {
                                    ShowToastDialog.showToast(
                                        "Please enter vehicle number.".tr);
                                  } else if (controller
                                          .selectedVehicleType.value.id ==
                                      null) {
                                    ShowToastDialog.showToast(
                                        "Select vehicle Type.".tr);
                                  } else if (controller
                                          .selectedVehicleBrand.value.id ==
                                      null) {
                                    ShowToastDialog.showToast(
                                        "Select vehicle brand.".tr);
                                  } else if (controller
                                          .selectedVehicleModel.value.id ==
                                      null) {
                                    ShowToastDialog.showToast(
                                        "Select vehicle model.".tr);
                                  } else if (controller
                                      .selectedColor.value.isEmpty) {
                                    ShowToastDialog.showToast(
                                        "Select vehicle colour.".tr);
                                  } else if (controller
                                      .vehicleRegisterYearController
                                      .value
                                      .text
                                      .isEmpty) {
                                    ShowToastDialog.showToast(
                                        "Please enter vehicle registration year."
                                            .tr);
                                  } else if (controller
                                          .selectedSeatCount.value ==
                                      0) {
                                    ShowToastDialog.showToast(
                                        "Please select seat count.".tr);
                                  } else {
                                    controller.setVehicleInformationData();
                                  }
                                },
                              )),
                        ],
                      ),
                    ),
                  ),
          );
        });
  }

  // Helper method to build RC info rows
  Widget _buildRcInfoRow(
      String label, String value, DarkThemeProvider themeChange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: themeChange.getThem()
                ? AppThemeData.grey400
                : AppThemeData.grey600,
            fontFamily: AppThemeData.regular,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: themeChange.getThem()
                ? AppThemeData.grey100
                : AppThemeData.grey900,
            fontFamily: AppThemeData.semiBold,
          ),
        ),
      ],
    );
  }

  buildBottomSheet(BuildContext context, AddVehicleController controller) {
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: Responsive.height(22, context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Text("please select".tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => controller.pickFile(
                                    source: ImageSource.camera),
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                "camera".tr,
                                style: const TextStyle(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => controller.pickFile(
                                  source: ImageSource.gallery),
                              icon: const Icon(
                                Icons.photo_library_sharp,
                                size: 32,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                "gallery".tr,
                                style: const TextStyle(),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
