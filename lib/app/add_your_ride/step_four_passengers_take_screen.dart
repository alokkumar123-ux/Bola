import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/add_your_ride/step_five_price_screen.dart';
import 'package:poolmate/controller/add_your_ride_controller.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/widgets/seat_selection_widget.dart';
import 'package:provider/provider.dart';

class StepFourPassengerTakeScreen extends StatelessWidget {
  const StepFourPassengerTakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: AddYourRideController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.grey800
                : AppThemeData.grey50,
            appBar: AppBar(
              backgroundColor: themeChange.getThem()
                  ? AppThemeData.grey900
                  : AppThemeData.grey100,
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          "Select seats to offer for ride".tr,
                          style: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey50
                                  : AppThemeData.grey900,
                              fontFamily: AppThemeData.bold,
                              fontSize: 20),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      // Show vehicle info if available
                      if (controller.selectedUserVehicle.value.id != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeChange.getThem()
                                ? AppThemeData.grey700
                                : AppThemeData.grey100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey600
                                  : AppThemeData.grey200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                color: AppThemeData.primary300,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${controller.selectedUserVehicle.value.vehicleBrand?.name ?? ''} ${controller.selectedUserVehicle.value.vehicleModel?.name ?? ''}",
                                      style: TextStyle(
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey50
                                            : AppThemeData.grey900,
                                        fontFamily: AppThemeData.medium,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "RC Number: ${controller.selectedUserVehicle.value.licensePlatNumber ?? ''}",
                                      style: TextStyle(
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey300
                                            : AppThemeData.grey600,
                                        fontFamily: AppThemeData.regular,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(
                        height: 20,
                      ),
                      // Seat selection widget
                      SeatSelectionWidget(
                        totalSeats: int.tryParse(
                                controller.selectedUserVehicle.value.seatCount ??
                                    '4') ??
                            4,
                        selectedSeats: controller.selectedSeats,
                        onSeatsChanged: (seats) {
                          controller.selectedSeats.value = seats;
                          controller.numberOfSheet.value = seats.length;
                        },
                        isDriverSeatVisible: true,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(),
                      ),
                      Text(
                        "Additional requirements".tr,
                        style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey50
                                : AppThemeData.grey900,
                            fontFamily: AppThemeData.medium,
                            fontSize: 16),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      // Additional requirements text field
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeChange.getThem()
                              ? AppThemeData.grey700
                              : AppThemeData.grey100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: themeChange.getThem()
                                ? AppThemeData.grey600
                                : AppThemeData.grey300,
                          ),
                        ),
                        child: TextFormField(
                          controller:
                              controller.additionalRequirementsController.value,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                "Enter any specific requirements for this ride (e.g., no smoking, quiet ride, etc.)"
                                    .tr,
                            hintStyle: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey400
                                  : AppThemeData.grey500,
                              fontFamily: AppThemeData.regular,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey100
                                : AppThemeData.grey800,
                            fontFamily: AppThemeData.regular,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      // InkWell(
                      //   onTap: () {
                      //     if (controller.twoPassengerMaxInBack.value) {
                      //       controller.twoPassengerMaxInBack.value = false;
                      //     } else {
                      //       controller.twoPassengerMaxInBack.value = true;
                      //     }
                      //   },
                      //   child: Row(
                      //     children: [
                      //       SvgPicture.asset("assets/icons/ic_two_passanger.svg"),
                      //       const SizedBox(
                      //         width: 10,
                      //       ),
                      //       Expanded(
                      //         child: Text(
                      //           "2 Passengers Max in Back Seat".tr,
                      //           style: TextStyle(
                      //               color: themeChange.getThem()
                      //                   ? AppThemeData.grey100
                      //                   : AppThemeData.grey800,
                      //               fontFamily: AppThemeData.bold,
                      //               fontSize: 14),
                      //         ),
                      //       ),
                      //       Checkbox(
                      //         activeColor: AppThemeData.primary300,
                      //         value: controller.twoPassengerMaxInBack.value,
                      //         onChanged: (val) {
                      //           controller.twoPassengerMaxInBack.value = val!;
                      //         },
                      //       )
                      //     ],
                      //   ),
                      // ),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      InkWell(
                        onTap: () {
                          if (controller.womenOnly.value) {
                            controller.womenOnly.value = false;
                          } else {
                            controller.womenOnly.value = true;
                          }
                        },
                        child: Row(
                          children: [
                            SvgPicture.asset("assets/icons/ic_women_only.svg"),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Text(
                                "Women Only".tr,
                                style: TextStyle(
                                    color: themeChange.getThem()
                                        ? AppThemeData.grey100
                                        : AppThemeData.grey800,
                                    fontFamily: AppThemeData.bold,
                                    fontSize: 14),
                              ),
                            ),
                            Checkbox(
                              activeColor: AppThemeData.primary300,
                              value: controller.womenOnly.value,
                              onChanged: (val) {
                                controller.womenOnly.value = val!;
                              },
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      InkWell(
                        onTap: () {
                          if (controller.onlyVerifiedPassenger.value) {
                            controller.onlyVerifiedPassenger.value = false;
                          } else {
                            controller.onlyVerifiedPassenger.value = true;
                          }
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified,
                              color: AppThemeData.primary300,
                              size: 24,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Text(
                                "Only Verified Passenger".tr,
                                style: TextStyle(
                                    color: themeChange.getThem()
                                        ? AppThemeData.grey100
                                        : AppThemeData.grey800,
                                    fontFamily: AppThemeData.bold,
                                    fontSize: 14),
                              ),
                            ),
                            Checkbox(
                              activeColor: AppThemeData.primary300,
                              value: controller.onlyVerifiedPassenger.value,
                              onChanged: (val) {
                                controller.onlyVerifiedPassenger.value = val!;
                              },
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: RoundedButtonFill(
                title: "Next".tr,
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                onPress: () {
                  if (controller.selectedSeats.isEmpty) {
                    Get.snackbar(
                      "Error".tr,
                      "Please select at least one seat to offer for ride".tr,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppThemeData.warning400,
                      colorText: AppThemeData.grey50,
                    );
                  } else {
                    Get.to(const StepFivePriceScreen());
                  }
                },
              ),
            ),
          );
        });
  }
}
