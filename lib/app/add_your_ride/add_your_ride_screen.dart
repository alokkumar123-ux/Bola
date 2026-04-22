
import 'package:bottom_picker/bottom_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:intl/intl.dart';
import 'package:poolmate/app/add_vehicle/add_vehicle_screen.dart';
import 'package:poolmate/app/add_your_ride/step_one_routes_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/add_your_ride_controller.dart';
import 'package:poolmate/model/map/city_list_model.dart';
import 'package:poolmate/model/map/geometry.dart';
import 'package:poolmate/model/vehicle_information_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class AddYourRideScreen extends StatelessWidget {
  const AddYourRideScreen({super.key});

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
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Image.asset(
                          Constant.getStartedImage,
                          fit: BoxFit.cover,
                          width: Responsive.width(100, context),
                          height: Responsive.height(50, context),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).viewPadding.top + 10,
                              left: 12),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Get.back();
                                },
                                child: Icon(
                                  Icons.close,
                                  color: themeChange.getThem()
                                      ? AppThemeData.primary300
                                      : AppThemeData.primary300,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * .32,
                            left: 16,
                            right: 16,
                          ),
                          child: Container(
                            width: Responsive.width(100, context),
                            decoration: BoxDecoration(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey900
                                  : AppThemeData.grey50,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              border: Border.all(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey700
                                    : AppThemeData.grey200,
                              ),
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () async {
                                    print(
                                        '✅ Opening PlacePicker for Pickup Location');
                                    print(
                                        '📍 API Endpoint: Places API (Camera Location Search)');
                                    print(
                                        '🔑 Using API Key: ${Constant.mapAPIKey.substring(0, 10)}...');
                                    try {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Theme(
                                            data: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? ThemeData.dark().copyWith(
                                                    primaryColor:
                                                        AppThemeData.primary300,
                                                    scaffoldBackgroundColor:
                                                        AppThemeData.grey900,
                                                  )
                                                : ThemeData.light().copyWith(
                                                    primaryColor:
                                                        AppThemeData.primary300,
                                                    scaffoldBackgroundColor:
                                                        AppThemeData.grey50,
                                                  ),
                                            child: PlacePicker(
                                              apiKey: Constant.mapAPIKey,
                                              onPlacePicked: (result) {
                                                print(
                                                    '✅ Place picked successfully for Pickup Location');
                                                Get.back();
                                                controller
                                                        .pickUpLocationController
                                                        .value
                                                        .text =
                                                    result.formattedAddress
                                                        .toString();
                                                controller.pickUpLocation
                                                    .value = CityModel(
                                                  name: result.formattedAddress
                                                      .toString(),
                                                  placeId:
                                                      result.placeId.toString(),
                                                  geometry: Geometry(
                                                      location:
                                                          Location.fromJson(
                                                              result.geometry!
                                                                  .location
                                                                  .toJson())),
                                                );
                                                print(controller
                                                    .pickUpLocation.value);
                                                // controller.pickUpLocation.value = Location(lat: result.geometry!.location.lat, lng: result.geometry!.location.lng);
                                              },
                                              onAutoCompleteFailed: (error) {
                                                print(
                                                    '🔴 PlacePicker AutoComplete Failed for Pickup Location');
                                                print(
                                                    '📍 API Endpoint: Places API Autocomplete');
                                                print(
                                                    '❌ Error Details: $error');
                                                print(
                                                    '🔑 API Key Used: ${Constant.mapAPIKey.substring(0, 10)}...');
                                              },
                                              onGeocodingSearchFailed: (error) {
                                                print(
                                                    '🔴 PlacePicker Geocoding Search Failed for Pickup Location');
                                                print(
                                                    '📍 API Endpoint: Geocoding API / Places API Reverse Geocoding');
                                                print(
                                                    '❌ Error Details: $error');
                                                print(
                                                    '🔑 API Key Used: ${Constant.mapAPIKey.substring(0, 10)}...');
                                              },
                                              initialPosition: const LatLng(
                                                  37.7749,
                                                  -122.4194), // Default to San Francisco, you can change this to your preferred default location
                                              useCurrentLocation: true,
                                              selectInitialPosition: true,
                                              usePinPointingSearch: true,
                                              usePlaceDetailSearch: true,
                                              zoomGesturesEnabled: true,
                                              zoomControlsEnabled: true,
                                              resizeToAvoidBottomInset:
                                                  false, // only works in page mode, less flickery, remove if wrong offsets
                                            ),
                                          ),
                                        ),
                                      );
                                    } catch (e, stackTrace) {
                                      print(
                                          '🔴 Exception in PlacePicker for Pickup Location');
                                      print(
                                          '📍 API Endpoint: Multiple (PlacePicker initialization)');
                                      print('❌ Error: $e');
                                      print('📚 Stack Trace: $stackTrace');
                                      print(
                                          '🔑 API Key Used: ${Constant.mapAPIKey.substring(0, 10)}...');
                                    }
                                  },
                                  child: TextFormField(
                                    controller: controller
                                        .pickUpLocationController.value,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey50
                                            : AppThemeData.grey900,
                                        fontFamily: AppThemeData.medium),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Enter Pickup Location'.tr,
                                      enabled: false,
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: SvgPicture.asset(
                                            "assets/icons/ic_source.svg"),
                                      ),
                                      hintStyle: TextStyle(
                                        fontSize: 16,
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey700
                                            : AppThemeData.grey700,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                ),
                                InkWell(
                                  onTap: () async {
                                    print(
                                        '✅ Opening PlacePicker for Drop Location');
                                    print(
                                        '📍 API Endpoint: Places API (Camera Location Search)');
                                    print(
                                        '🔑 Using API Key: ${Constant.mapAPIKey.substring(0, 10)}...');
                                    try {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PlacePicker(
                                            apiKey: Constant.mapAPIKey,
                                            onPlacePicked: (result) {
                                              print(
                                                  '✅ Place picked successfully for Drop Location');
                                              Get.back();
                                              controller.dropLocationController
                                                      .value.text =
                                                  result.formattedAddress
                                                      .toString();
                                              controller.dropLocation.value =
                                                  CityModel(
                                                name: result.formattedAddress
                                                    .toString(),
                                                placeId:
                                                    result.placeId.toString(),
                                                geometry: Geometry(
                                                    location: Location.fromJson(
                                                        result
                                                            .geometry!.location
                                                            .toJson())),
                                              );
                                            },
                                            onAutoCompleteFailed: (error) {
                                              print(
                                                  '🔴 PlacePicker AutoComplete Failed for Drop Location');
                                              print(
                                                  '📍 API Endpoint: Places API Autocomplete');
                                              print('❌ Error Details: $error');
                                              print(
                                                  '🔑 API Key Used: ${Constant.mapAPIKey.substring(0, 10)}...');
                                            },
                                            onGeocodingSearchFailed: (error) {
                                              print(
                                                  '🔴 PlacePicker Geocoding Search Failed for Drop Location');
                                              print(
                                                  '📍 API Endpoint: Geocoding API / Places API Reverse Geocoding');
                                              print('❌ Error Details: $error');
                                              print(
                                                  '🔑 API Key Used: ${Constant.mapAPIKey.substring(0, 10)}...');
                                            },
                                            initialPosition: const LatLng(
                                                37.7749,
                                                -122.4194), // Default to San Francisco, you can change this to your preferred default location
                                            useCurrentLocation: true,
                                            selectInitialPosition: true,
                                            usePinPointingSearch: true,
                                            usePlaceDetailSearch: true,
                                            zoomGesturesEnabled: true,
                                            zoomControlsEnabled: true,
                                            resizeToAvoidBottomInset:
                                                false, // only works in page mode, less flickery, remove if wrong offsets
                                          ),
                                        ),
                                      );
                                    } catch (e, stackTrace) {
                                      print(
                                          '🔴 Exception in PlacePicker for Drop Location');
                                      print(
                                          '📍 API Endpoint: Multiple (PlacePicker initialization)');
                                      print('❌ Error: $e');
                                      print('📚 Stack Trace: $stackTrace');
                                      print(
                                          '🔑 API Key Used: ${Constant.mapAPIKey.substring(0, 10)}...');
                                    }
                                  },
                                  child: TextFormField(
                                    controller:
                                        controller.dropLocationController.value,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey50
                                            : AppThemeData.grey900,
                                        fontFamily: AppThemeData.medium),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Enter Drop-off Location'.tr,
                                      enabled: false,
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: SvgPicture.asset(
                                            "assets/icons/ic_destination.svg"),
                                      ),
                                      hintStyle: TextStyle(
                                        fontSize: 16,
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey700
                                            : AppThemeData.grey700,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                ),
                                InkWell(
                                  onTap: () async {
                                    BottomPicker.dateTime(
                                      backgroundColor: themeChange.getThem()
                                          ? AppThemeData.grey900
                                          : AppThemeData.grey100,
                                      onSubmit: (index) async {
                                        if (controller.pickUpLocationController
                                            .value.text.isEmpty) {
                                          ShowToastDialog.showToast(
                                              "Please First Select Pickup Location"
                                                  .tr);
                                        } else if (controller
                                            .dropLocationController
                                            .value
                                            .text
                                            .isEmpty) {
                                          ShowToastDialog.showToast(
                                              "Please First Select Drop Location"
                                                  .tr);
                                        } else {
                                          ShowToastDialog.showLoader(
                                              "Please wait".tr);
                                          controller.selectedDate.value = index;
                                          DateFormat dateFormat = DateFormat(
                                              "EEE dd MMMM , hh:mm aa");
                                          String string =
                                              dateFormat.format(index);
                                          controller.dateController.value.text =
                                              string;
                                          Duration searchRideDuration =
                                              await controller.getDuration(
                                                  startLocation: controller
                                                      .pickUpLocation
                                                      .value
                                                      .geometry!
                                                      .location!,
                                                  endLocation: controller
                                                      .dropLocation
                                                      .value
                                                      .geometry!
                                                      .location!);
                                          var listOfRide = await controller
                                              .checkPublishRideBetweenIntervalTime();
                                          controller.newPublishRideActive
                                              .value = listOfRide.where((ride) {
                                            DateTime intervalDepartureTime =
                                                controller.selectedDate.value
                                                    .add(Duration(
                                                        hours: int.parse(Constant
                                                            .intervalHoursForPublishNewRide)));
                                            DateTime intervalDurationTime =
                                                intervalDepartureTime
                                                    .add(searchRideDuration);
                                            DateTime selectedDate =
                                                controller.selectedDate.value;
                                            print(
                                                "listOfRide :: Selected Date: ${Constant.dateToString(selectedDate)} selectedDate :: Interval Duration Time: ${Constant.dateToString(intervalDurationTime)}");
                                            DateTime rideDepartureTime = ride
                                                .departureDateTime!
                                                .toDate();
                                            return rideDepartureTime
                                                    .isAfter(selectedDate) &&
                                                rideDepartureTime.isBefore(
                                                    intervalDurationTime);
                                          }).toList();
                                          if (controller
                                              .newPublishRideActive.isEmpty) {
                                            controller.OldPublishRideActive
                                                    .value =
                                                listOfRide.where((ride) {
                                              DateTime pickUpTime = ride
                                                  .departureDateTime!
                                                  .toDate();
                                              DateTime intervalDepartureTime =
                                                  pickUpTime.add(Duration(
                                                      hours: int.parse(Constant
                                                          .intervalHoursForPublishNewRide)));
                                              DateTime droffTime =
                                                  intervalDepartureTime.add(Constant()
                                                      .stringConvertIntoDuration(
                                                          ride.estimatedTime ??
                                                              ''));
                                              print(
                                                  "listOfRide :: Start Date: ${Constant.dateToString(pickUpTime)} selectedDate :: End Time: ${Constant.dateToString(droffTime)} :: Selected Date :: ${Constant.dateToString(controller.selectedDate.value)}");
                                              return controller
                                                      .selectedDate.value
                                                      .isAfter(pickUpTime) &&
                                                  controller.selectedDate.value
                                                      .isBefore(droffTime);
                                            }).toList();
                                          }
                                          ShowToastDialog.closeLoader();
                                        }
                                      },
                                      minDateTime: DateTime.now(),
                                      buttonAlignment: MainAxisAlignment.center,
                                      displaySubmitButton: true,
                                      pickerTitle: const Text(''),
                                      pickerTextStyle: TextStyle(
                                        fontSize: 16,
                                        fontFamily: AppThemeData.regular,
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey100
                                            : AppThemeData.grey900,
                                      ),
                                      buttonSingleColor:
                                          AppThemeData.primary300,
                                    ).show(context);
                                  },
                                  child: TextFormField(
                                    controller: controller.dateController.value,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey50
                                            : AppThemeData.grey900,
                                        fontFamily: AppThemeData.medium),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      enabled: false,
                                      hintText: 'Date and time (departure)'.tr,
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: SvgPicture.asset(
                                            "assets/icons/ic_calender.svg"),
                                      ),
                                      hintStyle: TextStyle(
                                        fontSize: 16,
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey700
                                            : AppThemeData.grey700,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                ),
                                InkWell(
                                  onTap: () async {
                                    if (controller
                                            .newPublishRideActive.isEmpty &&
                                        controller
                                            .OldPublishRideActive.isEmpty) {
                                      await addVehicleBuildBottomSheet(
                                          context, themeChange.getThem());
                                    }
                                  },
                                  child: TextFormField(
                                    controller: controller
                                        .selectedVehicleController.value,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey50
                                            : AppThemeData.grey900,
                                        fontFamily: AppThemeData.medium),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Select Vehicle'.tr,
                                      enabled: false,
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: SvgPicture.asset(
                                          "assets/icons/ic_car.svg",
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey700
                                              : AppThemeData.grey700,
                                        ),
                                      ),
                                      suffixIcon:
                                          const Icon(Icons.arrow_drop_down),
                                      hintStyle: TextStyle(
                                        fontSize: 16,
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey700
                                            : AppThemeData.grey700,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                if (controller
                                        .OldPublishRideActive.isNotEmpty ||
                                    controller.newPublishRideActive.isNotEmpty)
                                  Text(
                                    "You cannot create a new ride at the selected time of the periods because a previous ride is active at that time.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppThemeData.warning400,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: RoundedButtonFill(
                  title: "Next".tr,
                  color: AppThemeData.primary300,
                  textColor: AppThemeData.grey50,
                  onPress: () {
                    if (controller
                        .pickUpLocationController.value.text.isEmpty) {
                      ShowToastDialog.showToast(
                          "Please select pickup location".tr);
                    } else if (controller
                        .pickUpLocationController.value.text.isEmpty) {
                      ShowToastDialog.showToast(
                          "Please select drop location".tr);
                    } else if (controller.dateController.value.text.isEmpty) {
                      ShowToastDialog.showToast(
                          "Please select departure date".tr);
                    } else if (controller
                        .selectedVehicleController.value.text.isEmpty) {
                      ShowToastDialog.showToast("Please select vehicle".tr);
                    } else {
                      if (controller.OldPublishRideActive.isEmpty &&
                          controller.newPublishRideActive.isEmpty) {
                        Get.to(const StepOneRoutesScreen());
                      }
                    }
                  },
                ),
              ),
            ),
          );
        });
  }

  bool _isRcExpired(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      DateTime? d;
      try { d = DateFormat('dd-MMM-yyyy').parse(dateStr); } catch(e){}
      if (d == null) {
        try { d = DateFormat('yyyy-MM-dd').parse(dateStr); } catch(e){}
      }
      if (d == null) {
        d = DateTime.tryParse(dateStr);
      }
      if (d != null) {
        return d.isBefore(DateTime.now());
      }
    } catch (e) {
      print('RC Date parse error: $e');
    }
    return false;
  }

  addVehicleBuildBottomSheet(BuildContext context, bool isdarkmode) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: isdarkmode ? AppThemeData.grey800 : AppThemeData.grey100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.50,
        minChildSize: 0.50,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          final themeChange = Provider.of<DarkThemeProvider>(context);
          return GetX<AddYourRideController>(
              init: AddYourRideController(),
              builder: (controller) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Text(
                                "Select a vehicle".tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: AppThemeData.bold,
                                  color: isdarkmode
                                      ? AppThemeData.grey50
                                      : AppThemeData.grey900,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                              onTap: () {
                                Get.back();
                              },
                              child: const Icon(Icons.close))
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Flexible(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: controller.userVehicleList.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            VehicleInformationModel vehicleInformationModel =
                                controller.userVehicleList[index];
                            bool isExpired = _isRcExpired(vehicleInformationModel.rcExpiryDate);
                            return Obx(
                              () => InkWell(
                                onTap: isExpired ? null : () {
                                  controller.selectedUserVehicle.value =
                                      vehicleInformationModel;
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "${vehicleInformationModel.vehicleBrand!.name} ${vehicleInformationModel.vehicleModel!.name} (${vehicleInformationModel.licensePlatNumber})"
                                                .tr,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: isExpired
                                                    ? AppThemeData.grey500
                                                    : (themeChange.getThem()
                                                        ? AppThemeData.grey100
                                                        : AppThemeData.grey800),
                                                fontFamily:
                                                    AppThemeData.medium),
                                          ),
                                        ),
                                        Radio<VehicleInformationModel>(
                                          value: vehicleInformationModel,
                                          groupValue: controller
                                              .selectedUserVehicle.value,
                                          activeColor: isExpired ? AppThemeData.grey500 : AppThemeData.primary300,
                                          onChanged: isExpired ? null : (VehicleInformationModel? value) {
                                            if (value != null) {
                                              controller.selectedUserVehicle
                                                  .value = value;
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    if (isExpired)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Text(
                                          "Vehicle RC has expired. Please verify your RC to use this vehicle.".tr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppThemeData.warning300,
                                            fontFamily: AppThemeData.regular,
                                          ),
                                        ),
                                      ),
                                    const Divider(),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      InkWell(
                        onTap: () async {
                          String? id = await Get.to(AddVehicleScreen());
                          if (id != null) {
                            await controller.getVehicleInformation(
                                selectedId: id);
                            Get.back(result: true);
                          }
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.add,
                              color: AppThemeData.primary300,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              "Add new vehicle".tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppThemeData.primary300,
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      RoundedButtonFill(
                        title: "Select".tr,
                        color: AppThemeData.primary300,
                        textColor: AppThemeData.grey50,
                        onPress: () {
                          controller.selectedVehicleController.value.text =
                              "${controller.selectedUserVehicle.value.vehicleBrand!.name} ${controller.selectedUserVehicle.value.vehicleModel!.name} (${controller.selectedUserVehicle.value.licensePlatNumber})";
                          Get.back();
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                );
              });
        },
      ),
    );
  }
}
