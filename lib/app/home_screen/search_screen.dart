import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/rating_view_screen/rating_view_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/controller/home_controller.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/map/geometry.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/model/vehicle_type_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/utils/fire_store_utils.dart';
import 'package:poolmate/utils/network_image_widget.dart';
import 'package:poolmate/app/home_screen/ride_dialog.dart';
import 'package:poolmate/app/profile_screen/profile_screen.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Filter state
  List<VehicleTypeModel> _vehicleTypes = [];
  VehicleTypeModel? _selectedVehicleType;

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    try {
      final vehicleTypes = await FireStoreUtils.getVehicleType();
      if (vehicleTypes != null) {
        setState(() {
          _vehicleTypes = vehicleTypes;
        });
      }
    } catch (e) {
      print('Error loading vehicle types: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: HomeController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.grey800
                : AppThemeData.grey100,
            appBar: AppBar(
              backgroundColor: themeChange.getThem()
                  ? AppThemeData.primary300
                  : AppThemeData.primary300,
              centerTitle: false,
              titleSpacing: 0,
              leading: IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: const Icon(
                    Icons.chevron_left_outlined,
                    color: Colors.white,
                  )),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          controller.pickUpLocationController.value.text,
                          maxLines: 1,
                          style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey50
                                : AppThemeData.grey50,
                            fontSize: 16,
                            overflow: TextOverflow.ellipsis,
                            fontFamily: AppThemeData.medium,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: SvgPicture.asset(
                          "assets/icons/ic_right_arrow.svg",
                          colorFilter: const ColorFilter.mode(
                              AppThemeData.grey50, BlendMode.srcIn),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          controller.dropLocationController.value.text,
                          maxLines: 1,
                          style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey50
                                : AppThemeData.grey50,
                            fontSize: 16,
                            overflow: TextOverflow.ellipsis,
                            fontFamily: AppThemeData.medium,
                          ),
                        ),
                      )
                    ],
                  ),
                  Text(
                    controller.dateController.value.text,
                    maxLines: 1,
                    style: TextStyle(
                      color: themeChange.getThem()
                          ? AppThemeData.grey50
                          : AppThemeData.grey50,
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                      fontFamily: AppThemeData.medium,
                    ),
                  )
                ],
              ),
              elevation: 0,
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Showing ${controller.searchedBookingList.length} Rides",
                        maxLines: 1,
                        style: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey300
                              : AppThemeData.grey600,
                          fontSize: 16,
                          overflow: TextOverflow.ellipsis,
                          fontFamily: AppThemeData.medium,
                        ),
                      ),
                      Spacer(),
                      _buildVehicleTypeFilter(themeChange)
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          _getFilteredBookings(controller.searchedBookingList)
                              .length,
                      itemBuilder: (context, index) {
                        BookingModel bookingModel = _getFilteredBookings(
                            controller.searchedBookingList)[index];

                        return FutureBuilder<StopOverModel?>(
                            future: controller.getPrice(bookingModel),
                            builder: (context, snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 60),
                                    child: Center(child: Constant.loader()),
                                  );
                                case ConnectionState.done:
                                  if (snapshot.hasError) {
                                    return Text(snapshot.error.toString());
                                  } else if (snapshot.data == null) {
                                    return SizedBox();
                                  } else {
                                    StopOverModel stopOverModel =
                                        snapshot.data!;
                                    return InkWell(
                                      onTap: () async {
                                        // Check if user is verified before showing ride dialog
                                        await _checkUserVerificationAndShowDialog(
                                          context,
                                          bookingModel,
                                          stopOverModel,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey900
                                                : AppThemeData.grey50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: RichText(
                                                        text: TextSpan(
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge,
                                                          children: [
                                                            // Use address strings instead of geocoding
                                                            TextSpan(
                                                              text: stopOverModel
                                                                      .startAddress
                                                                      ?.split(
                                                                          ',')
                                                                      .first ??
                                                                  'Location',
                                                              style: TextStyle(
                                                                  color: themeChange.getThem()
                                                                      ? AppThemeData
                                                                          .grey100
                                                                      : AppThemeData
                                                                          .grey800,
                                                                  fontFamily:
                                                                      AppThemeData
                                                                          .bold,
                                                                  fontSize: 14),
                                                            ),
                                                            WidgetSpan(
                                                              child: Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        10),
                                                                child: SvgPicture
                                                                    .asset(
                                                                        "assets/icons/ic_right_arrow.svg"),
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text: stopOverModel
                                                                      .endAddress
                                                                      ?.split(
                                                                          ',')
                                                                      .first ??
                                                                  'Location',
                                                              style: TextStyle(
                                                                  color: themeChange.getThem()
                                                                      ? AppThemeData
                                                                          .grey100
                                                                      : AppThemeData
                                                                          .grey800,
                                                                  fontFamily:
                                                                      AppThemeData
                                                                          .bold,
                                                                  fontSize: 14),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      Constant.amountShow(
                                                          amount: controller
                                                              .getCorrectPrice(
                                                                  bookingModel,
                                                                  stopOverModel)
                                                              .toString()),
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        color: themeChange
                                                                .getThem()
                                                            ? AppThemeData
                                                                .grey100
                                                            : AppThemeData
                                                                .grey800,
                                                        fontSize: 16,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontFamily:
                                                            AppThemeData.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                                Text(
                                                  Constant.timestampToDateTime(
                                                      bookingModel
                                                          .departureDateTime!),
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    color: themeChange.getThem()
                                                        ? AppThemeData.grey200
                                                        : AppThemeData.grey700,
                                                    fontSize: 12,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontFamily:
                                                        AppThemeData.regular,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Row(
                                                  children: [
                                                    SvgPicture.asset(
                                                      "assets/icons/ic_walk.svg",
                                                      colorFilter:
                                                          const ColorFilter
                                                              .mode(
                                                              AppThemeData
                                                                  .secondary300,
                                                              BlendMode.srcIn),
                                                    ),
                                                    Text(
                                                      "${Constant.calculateDistance(Location(lat: stopOverModel.startLocation!.lat, lng: stopOverModel.startLocation!.lng), controller.pickUpLocation.value).toStringAsFixed(2)} ${Constant.distanceType}",
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        color: themeChange
                                                                .getThem()
                                                            ? AppThemeData
                                                                .grey200
                                                            : AppThemeData
                                                                .grey700,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontFamily: AppThemeData
                                                            .regular,
                                                      ),
                                                    ),
                                                    const Icon(
                                                      Icons
                                                          .chevron_right_outlined,
                                                      color:
                                                          AppThemeData.grey700,
                                                    ),
                                                    // Show icon based on vehicle type
                                                    _isMotorcycleType(bookingModel
                                                            .vehicleInformation
                                                            ?.vehicleType
                                                            ?.name)
                                                        ? Icon(
                                                            Icons.motorcycle,
                                                            color: themeChange
                                                                    .getThem()
                                                                ? AppThemeData
                                                                    .grey300
                                                                : AppThemeData
                                                                    .grey600,
                                                            size: 20,
                                                          )
                                                        : SvgPicture.asset(
                                                            "assets/icons/ic_car.svg",
                                                            colorFilter: ColorFilter.mode(
                                                                themeChange
                                                                        .getThem()
                                                                    ? AppThemeData
                                                                        .grey300
                                                                    : AppThemeData
                                                                        .grey600,
                                                                BlendMode
                                                                    .srcIn),
                                                          ),
                                                    const Icon(
                                                      Icons
                                                          .chevron_right_outlined,
                                                      color:
                                                          AppThemeData.grey700,
                                                    ),
                                                    SvgPicture.asset(
                                                      "assets/icons/ic_walk.svg",
                                                      colorFilter:
                                                          const ColorFilter
                                                              .mode(
                                                              AppThemeData
                                                                  .success400,
                                                              BlendMode.srcIn),
                                                    ),
                                                    Text(
                                                      "${Constant.calculateDistance(Location(lat: stopOverModel.endLocation!.lat, lng: stopOverModel.endLocation!.lng), controller.dropLocation.value).toStringAsFixed(2)} ${Constant.distanceType}",
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        color: themeChange
                                                                .getThem()
                                                            ? AppThemeData
                                                                .grey200
                                                            : AppThemeData
                                                                .grey700,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontFamily: AppThemeData
                                                            .regular,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  '${_calculateAvailableSeats(bookingModel, stopOverModel)} seats available',
                                                  style: TextStyle(
                                                    color: themeChange.getThem()
                                                        ? AppThemeData.grey200
                                                        : AppThemeData.grey700,
                                                    fontSize: 14,
                                                    fontFamily:
                                                        AppThemeData.medium,
                                                  ),
                                                ),
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 10),
                                                  child: Divider(),
                                                ),
                                                FutureBuilder<UserModel?>(
                                                    future: FireStoreUtils
                                                        .getUserProfile(
                                                            bookingModel
                                                                .createdBy
                                                                .toString()),
                                                    builder:
                                                        (context, snapshot) {
                                                      switch (snapshot
                                                          .connectionState) {
                                                        case ConnectionState
                                                              .waiting:
                                                          return Center(
                                                              child: Constant
                                                                  .loader());
                                                        case ConnectionState
                                                              .done:
                                                          if (snapshot
                                                              .hasError) {
                                                            return Text(snapshot
                                                                .error
                                                                .toString());
                                                          } else {
                                                            UserModel?
                                                                userModel =
                                                                snapshot.data;
                                                            return userModel
                                                                        ?.id ==
                                                                    null
                                                                ? Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            4),
                                                                    child:
                                                                        Center(
                                                                      child:
                                                                          Text(
                                                                        'Driver is not available'
                                                                            .tr,
                                                                        style:
                                                                            TextStyle(
                                                                          color: themeChange.getThem()
                                                                              ? AppThemeData.grey100
                                                                              : AppThemeData.grey800,
                                                                          fontFamily:
                                                                              AppThemeData.medium,
                                                                          fontSize:
                                                                              16,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  )
                                                                : Row(
                                                                    children: [
                                                                      Stack(
                                                                        children: [
                                                                          ClipRRect(
                                                                            borderRadius:
                                                                                BorderRadius.circular(60),
                                                                            child:
                                                                                NetworkImageWidget(
                                                                              fit: BoxFit.cover,
                                                                              imageUrl: userModel!.profilePic.toString(),
                                                                              height: Responsive.width(10, context),
                                                                              width: Responsive.width(10, context),
                                                                            ),
                                                                          ),
                                                                          bookingModel.driverVerify == true
                                                                              ? Positioned(bottom: 0, right: 0, child: SvgPicture.asset("assets/icons/ic_verify.svg"))
                                                                              : const SizedBox()
                                                                        ],
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            10,
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              userModel.fullName().toString(),
                                                                              style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800, fontFamily: AppThemeData.medium, fontSize: 16),
                                                                            ),
                                                                            Row(
                                                                              children: [
                                                                                Text(
                                                                                  Constant.calculateReview(reviewCount: userModel.reviewCount, reviewSum: userModel.reviewSum),
                                                                                  style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey700, fontFamily: AppThemeData.medium, fontSize: 14),
                                                                                ),
                                                                                const SizedBox(
                                                                                  width: 5,
                                                                                ),
                                                                                Icon(
                                                                                  Icons.star,
                                                                                  size: 14,
                                                                                  color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey700,
                                                                                ),
                                                                                const SizedBox(
                                                                                  width: 5,
                                                                                ),
                                                                                Text(
                                                                                  "•",
                                                                                  style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey500 : AppThemeData.grey500, fontFamily: AppThemeData.medium, fontSize: 14),
                                                                                ),
                                                                                const SizedBox(
                                                                                  width: 5,
                                                                                ),
                                                                                InkWell(
                                                                                  onTap: () {
                                                                                    Get.to(const RatingViewScreen(), arguments: {
                                                                                      "receiverUserId": userModel.id
                                                                                    });
                                                                                  },
                                                                                  child: Text(
                                                                                    "${double.parse(userModel.reviewCount ?? "0").toStringAsFixed(0)} Ratings",
                                                                                    style: TextStyle(decoration: TextDecoration.underline, decorationColor: AppThemeData.primary300, color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300, fontFamily: AppThemeData.medium, fontSize: 14),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      bookingModel.driverVerify ==
                                                                              true
                                                                          ? RoundedButtonFill(
                                                                              title: "Safe",
                                                                              color: AppThemeData.info400,
                                                                              textColor: AppThemeData.grey50,
                                                                              width: 14,
                                                                              height: 4,
                                                                              onPress: () {},
                                                                            )
                                                                          : const SizedBox(),
                                                                      const SizedBox(
                                                                        width:
                                                                            5,
                                                                      ),
                                                                      bookingModel.womenOnly ==
                                                                              false
                                                                          ? const SizedBox()
                                                                          : SvgPicture
                                                                              .asset(
                                                                              "assets/icons/ic_woman_icon.svg",
                                                                              colorFilter: ColorFilter.mode(themeChange.getThem() ? Colors.pink : Colors.pink, BlendMode.srcIn),
                                                                            ),
                                                                      const SizedBox(
                                                                        width:
                                                                            10,
                                                                      ),
                                                                      SvgPicture
                                                                          .asset(
                                                                        "assets/icons/ic_luggage.svg",
                                                                        colorFilter: ColorFilter.mode(
                                                                            themeChange.getThem()
                                                                                ? AppThemeData.grey300
                                                                                : AppThemeData.grey600,
                                                                            BlendMode.srcIn),
                                                                      )
                                                                    ],
                                                                  );
                                                          }
                                                        default:
                                                          return Text(
                                                              'Error'.tr);
                                                      }
                                                    })
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                default:
                                  return SizedBox();
                              }
                            });
                      },
                    ),
                  )
                ],
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionButton.extended(
              isExtended: true,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40)),
              backgroundColor: AppThemeData.primary300,
              onPressed: () async {
                filterBuildBottomSheet(themeChange, context);
              },
              icon: const Icon(Icons.filter_alt_sharp,
                  color: AppThemeData.grey50),
              label: const Text(
                'Filters',
                style: TextStyle(color: AppThemeData.grey50),
              ),
            ),
          );
        });
  }

  filterBuildBottomSheet(themeChange, BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize: 0.50,
        maxChildSize: 0.90,
        expand: false,
        builder: (context, scrollController) {
          final themeChange = Provider.of<DarkThemeProvider>(context);
          return GetX(
              init: HomeController(),
              builder: (controller) {
                return Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: Text(
                                      "Filters".tr,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(),
                            ),
                            Text(
                              "Departure time".tr,
                              style: TextStyle(
                                  color: themeChange.getThem()
                                      ? AppThemeData.grey100
                                      : AppThemeData.grey800,
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 16),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: controller.departureTime.length,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return Obx(
                                  () => Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          controller.departureTime[index].title,
                                          style: TextStyle(
                                              color: themeChange.getThem()
                                                  ? AppThemeData.grey200
                                                  : AppThemeData.grey700,
                                              fontFamily: AppThemeData.medium,
                                              fontSize: 14),
                                        ),
                                      ),
                                      Checkbox(
                                        visualDensity: VisualDensity.compact,
                                        activeColor: AppThemeData.primary300,
                                        value: controller.selectedDepartureTime
                                            .contains(controller
                                                .departureTime[index]),
                                        onChanged: (val) {
                                          if (controller.selectedDepartureTime
                                              .contains(controller
                                                  .departureTime[index])) {
                                            controller.selectedDepartureTime
                                                .remove(controller
                                                    .departureTime[index]);
                                          } else {
                                            controller.selectedDepartureTime
                                                .add(controller
                                                    .departureTime[index]);
                                          }
                                        },
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(),
                            ),
                            Text(
                              "Driver Preferences".tr,
                              style: TextStyle(
                                  color: themeChange.getThem()
                                      ? AppThemeData.grey100
                                      : AppThemeData.grey800,
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 16),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Verify Drivers".tr,
                                    style: TextStyle(
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey200
                                            : AppThemeData.grey700,
                                        fontFamily: AppThemeData.medium,
                                        fontSize: 14),
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.8,
                                  child: CupertinoSwitch(
                                    value: controller.verifyDriver.value,
                                    activeColor: AppThemeData.primary300,
                                    onChanged: (value) {
                                      controller.verifyDriver.value = value;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Woman only".tr,
                                    style: TextStyle(
                                        color: themeChange.getThem()
                                            ? AppThemeData.grey200
                                            : AppThemeData.grey700,
                                        fontFamily: AppThemeData.medium,
                                        fontSize: 14),
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.8,
                                  child: CupertinoSwitch(
                                    value: controller.isWoman.value,
                                    activeColor: AppThemeData.primary300,
                                    onChanged: (value) {
                                      controller.isWoman.value = value;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(),
                            ),
                            Text(
                              "Price Range".tr,
                              style: TextStyle(
                                  color: themeChange.getThem()
                                      ? AppThemeData.grey100
                                      : AppThemeData.grey800,
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 16),
                            ),
                            RangeSlider(
                              values: controller.currentRangeValues.value,
                              max: 10000,
                              divisions: 5000,
                              activeColor: AppThemeData.primary300,
                              labels: RangeLabels(
                                controller.currentRangeValues.value.start
                                    .round()
                                    .toString(),
                                controller.currentRangeValues.value.end
                                    .round()
                                    .toString(),
                              ),
                              onChanged: (RangeValues values) {
                                controller.currentRangeValues.value = values;
                                controller.minPriceController.value.text =
                                    controller.currentRangeValues.value.start
                                        .round()
                                        .toString();
                                controller.maxPriceController.value.text =
                                    controller.currentRangeValues.value.end
                                        .round()
                                        .toString();
                              },
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Min Price".tr,
                                        style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey100
                                                : AppThemeData.grey800,
                                            fontFamily: AppThemeData.bold,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      TextFormField(
                                        keyboardType: TextInputType.text,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        maxLines: 1,
                                        controller:
                                            controller.minPriceController.value,
                                        textInputAction: TextInputAction.done,
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey50
                                                : AppThemeData.grey900,
                                            fontFamily: AppThemeData.medium),
                                        decoration: InputDecoration(
                                          errorStyle: const TextStyle(
                                              color: Colors.red),
                                          filled: true,
                                          fillColor: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Text(Constant
                                                .currencyModel!.symbol
                                                .toString()),
                                          ),
                                          disabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(30)),
                                            borderSide: BorderSide(
                                                color: themeChange.getThem()
                                                    ? AppThemeData.grey200
                                                    : AppThemeData.grey700,
                                                width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(30)),
                                            borderSide: BorderSide(
                                                color: themeChange.getThem()
                                                    ? AppThemeData.primary300
                                                    : AppThemeData.primary300,
                                                width: 1),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(30)),
                                            borderSide: BorderSide(
                                                color: themeChange.getThem()
                                                    ? AppThemeData.grey200
                                                    : AppThemeData.grey700,
                                                width: 1),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(30)),
                                            borderSide: BorderSide(
                                                color: themeChange.getThem()
                                                    ? AppThemeData.grey200
                                                    : AppThemeData.grey700,
                                                width: 1),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(30)),
                                            borderSide: BorderSide(
                                                color: themeChange.getThem()
                                                    ? AppThemeData.grey200
                                                    : AppThemeData.grey700,
                                                width: 1),
                                          ),
                                          hintText: "Min Price".tr,
                                          hintStyle: TextStyle(
                                            fontSize: 14,
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey700
                                                : AppThemeData.grey700,
                                            fontFamily: AppThemeData.regular,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Center(
                                    child: Text(
                                      "-",
                                      style: TextStyle(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey100
                                              : AppThemeData.grey800,
                                          fontFamily: AppThemeData.medium,
                                          fontSize: 30),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Max Price",
                                        style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey100
                                                : AppThemeData.grey800,
                                            fontFamily: AppThemeData.bold,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      TextFormField(
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        maxLines: 1,
                                        controller:
                                            controller.maxPriceController.value,
                                        textInputAction: TextInputAction.done,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey50
                                                : AppThemeData.grey900,
                                            fontFamily: AppThemeData.medium),
                                        decoration: InputDecoration(
                                          errorStyle: const TextStyle(
                                              color: Colors.red),
                                          filled: true,
                                          fillColor: themeChange.getThem()
                                              ? AppThemeData.grey800
                                              : AppThemeData.grey100,
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Text(Constant
                                                .currencyModel!.symbol
                                                .toString()),
                                          ),
                                          disabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(30)),
                                            borderSide: BorderSide(
                                                color: themeChange.getThem()
                                                    ? AppThemeData.grey200
                                                    : AppThemeData.grey700,
                                                width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(30)),
                                            borderSide: BorderSide(
                                                color: themeChange.getThem()
                                                    ? AppThemeData.primary300
                                                    : AppThemeData.primary300,
                                                width: 1),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(30)),
                                            borderSide: BorderSide(
                                                color: themeChange.getThem()
                                                    ? AppThemeData.grey200
                                                    : AppThemeData.grey700,
                                                width: 1),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(30)),
                                            borderSide: BorderSide(
                                                color: themeChange.getThem()
                                                    ? AppThemeData.grey200
                                                    : AppThemeData.grey700,
                                                width: 1),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(30)),
                                            borderSide: BorderSide(
                                                color: themeChange.getThem()
                                                    ? AppThemeData.grey200
                                                    : AppThemeData.grey700,
                                                width: 1),
                                          ),
                                          hintText: "Max Price".tr,
                                          hintStyle: TextStyle(
                                            fontSize: 14,
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey700
                                                : AppThemeData.grey700,
                                            fontFamily: AppThemeData.regular,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    bottomNavigationBar: Container(
                      color: themeChange.getThem()
                          ? AppThemeData.grey900
                          : AppThemeData.grey50,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  controller.selectedDepartureTime.clear();
                                  controller.verifyDriver.value = false;
                                  controller.isWoman.value = false;
                                  controller.minPriceController.value.text =
                                      "1";
                                  controller.maxPriceController.value.text =
                                      "10000";
                                  controller.currentRangeValues =
                                      const RangeValues(1, 10000).obs;
                                  controller.searchRide();
                                  Get.back();
                                },
                                child: Text(
                                  "Clear all".tr,
                                  style: TextStyle(
                                      color: themeChange.getThem()
                                          ? AppThemeData.primary300
                                          : AppThemeData.primary300,
                                      fontFamily: AppThemeData.bold,
                                      fontSize: 16),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: RoundedButtonFill(
                                title: "Show Results".tr,
                                width: 32,
                                color: AppThemeData.primary300,
                                textColor: AppThemeData.grey50,
                                onPress: () async {
                                  controller.filterBookings(
                                      timeSlots:
                                          controller.selectedDepartureTime,
                                      womenOnly: controller.isWoman.value,
                                      verifyDrivers:
                                          controller.verifyDriver.value,
                                      maxPrice: double.parse(controller
                                          .maxPriceController.value.text),
                                      minPrice: double.parse(controller
                                          .minPriceController.value.text));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ));
              });
        },
      ),
    );
  }

  // Widget for vehicle type filter dropdown
  Widget _buildVehicleTypeFilter(DarkThemeProvider themeChange) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: themeChange.getThem()
              ? AppThemeData.grey500
              : AppThemeData.grey300,
        ),
        borderRadius: BorderRadius.circular(8),
        color: themeChange.getThem() ? AppThemeData.grey900 : Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VehicleTypeModel?>(
          dropdownColor: AppThemeData.grey100,
          value: _selectedVehicleType,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_outlined,
                size: 20,
                color:
                    themeChange.getThem() ? Colors.white : AppThemeData.grey800,
              ),
              const SizedBox(width: 4),
              Text(
                'Filter',
                style: TextStyle(
                  color: themeChange.getThem()
                      ? Colors.white
                      : AppThemeData.grey800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          items: [
            // "All" option
            DropdownMenuItem<VehicleTypeModel?>(
              value: null,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    Icons.filter_list_outlined,
                    size: 16,
                    color: themeChange.getThem()
                        ? Colors.white
                        : AppThemeData.grey800,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'All Vehicles',
                    style: TextStyle(
                      color: themeChange.getThem()
                          ? Colors.white
                          : AppThemeData.grey800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Vehicle type options
            ..._vehicleTypes.map((vehicleType) {
              return DropdownMenuItem<VehicleTypeModel?>(
                value: vehicleType,
                child: Row(
                  children: [
                    Icon(
                      _getVehicleTypeIcon(vehicleType.name ?? ''),
                      size: 16,
                      color: themeChange.getThem()
                          ? Colors.white
                          : AppThemeData.grey800,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      vehicleType.name ?? '',
                      style: TextStyle(
                        color: themeChange.getThem()
                            ? Colors.white
                            : AppThemeData.grey800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          onChanged: (VehicleTypeModel? newValue) {
            setState(() {
              _selectedVehicleType = newValue;
            });
            // Apply filter to search results
            _applyVehicleTypeFilter();
          },
          isExpanded: false,
          icon: Icon(
            Icons.arrow_drop_down,
            color: themeChange.getThem() ? Colors.white : AppThemeData.grey800,
          ),
        ),
      ),
    );
  }

  // Check if vehicle type is motorcycle/bike/twowheeler
  bool _isMotorcycleType(String? vehicleTypeName) {
    if (vehicleTypeName == null) return false;
    final lowerName = vehicleTypeName.toLowerCase();
    return lowerName == 'bike' ||
        lowerName == 'motorcycle' ||
        lowerName == 'twowheeler' ||
        lowerName == 'two wheeler' ||
        lowerName.contains('two wheeler');
  }

  // Get appropriate icon for vehicle type
  IconData _getVehicleTypeIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'bike':
      case 'motorcycle':
      case 'twowheeler':
      case 'two wheeler':
        return Icons.motorcycle;
      case 'suv':
        return Icons.directions_car;
      case 'sedan':
        return Icons.directions_car;
      case 'hatchback':
        return Icons.directions_car;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  // Apply vehicle type filter to search results
  void _applyVehicleTypeFilter() {
    // Trigger a rebuild to apply the filter
    setState(() {});
  }

  // Get filtered bookings based on selected vehicle type
  List<BookingModel> _getFilteredBookings(List<BookingModel> bookings) {
    if (_selectedVehicleType == null) {
      return bookings; // Return all if no filter selected
    }

    return bookings
        .where((booking) => _matchesVehicleTypeFilter(booking))
        .toList();
  }

  // Check if a booking matches the selected vehicle type filter
  bool _matchesVehicleTypeFilter(BookingModel booking) {
    if (_selectedVehicleType == null) {
      return true; // Show all if no filter selected
    }

    return booking.vehicleInformation?.vehicleType?.id ==
        _selectedVehicleType!.id;
  }

  // Check user verification and show appropriate dialog
  Future<void> _checkUserVerificationAndShowDialog(
    BuildContext context,
    BookingModel bookingModel,
    StopOverModel stopOverModel,
  ) async {
    try {
      // Get current user
      UserModel? currentUser =
          await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());

      if (currentUser == null) {
        return; // User not found, do nothing
      }

      // Only check verification if the ride specifically requires verified passengers
      if (bookingModel.onlyVerifiedPassenger == true) {
        if (currentUser.aadharVerified != true) {
          _showVerificationRequiredDialog(context);
          return;
        }
      }

      // Check women only requirement (only for verified users)
      if (bookingModel.womenOnly == true) {
        if (currentUser.gender?.toLowerCase() != 'female' &&
            currentUser.gender?.toLowerCase() != 'woman') {
          _showGenderRestrictionDialog(context);
          return;
        }
      }

      // User is verified and can access the ride - show ride dialog
      final result = await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return RideDialog(
            bookingModel: bookingModel,
            stopOverModel: stopOverModel,
          );
        },
      );

      // If booking was successful, reload the search results
      if (result == true) {
        final controller = Get.find<HomeController>();
        await controller.searchRide();

        // Force a rebuild of the UI to show updated results
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error checking user verification: $e');
    }
  }

  // Show verification required dialog
  void _showVerificationRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Verification Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'The driver has accepted booking only from  verified users, please verify yourself in profile section and book. Thanks',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to profile screen for verification
                Get.to(const ProfileScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Verify Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show gender restriction dialog
  void _showGenderRestrictionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.female_outlined,
                color: Colors.pink,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Women Only Ride',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This ride is only available for women passengers.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.pink.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.pink.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Please search for rides that are available for all passengers.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Okay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Calculate available seats for a booking and stopover
  int _calculateAvailableSeats(
      BookingModel bookingModel, StopOverModel stopOverModel) {
    // Get total seats from vehicle information
    final totalSeats =
        int.tryParse(bookingModel.vehicleInformation?.seatCount ?? '0') ?? 0;

    // Get selected seats that are available for booking
    final allowedSeats = bookingModel.selectedSeats ?? [];

    // Get already booked seats
    final bookedSeats = (bookingModel.bookedSeat ?? "0")
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => int.tryParse(s) ?? -1)
        .toList();

    // Get temporarily selected seats by other users
    final tempSelectedSeats = bookingModel.tempSeatSelection ?? [];

    // Count available seats
    int availableCount = 0;
    for (int i = 1; i < totalSeats; i++) {
      // Skip driver seat (index 0)
      // Check if seat is in allowed seats and not booked and not temp selected
      if (allowedSeats.contains(i.toString()) &&
          !bookedSeats.contains(i) &&
          !tempSelectedSeats.contains(i)) {
        availableCount++;
      }
    }

    return availableCount;
  }
}
