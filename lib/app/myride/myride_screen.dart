import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/myride/booked_details_screen.dart';
import 'package:poolmate/app/myride/published_details_screen.dart';
import 'package:poolmate/app/rating_view_screen/rating_view_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/controller/myride_controller.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/utils/firestore/booking_utils.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/network_image_widget.dart';
import 'package:provider/provider.dart';

class MyRideScreen extends StatelessWidget {
  const MyRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    // Check if we need to show published tab
    final arguments = Get.arguments as Map<String, dynamic>?;
    final initialIndex =
        (arguments != null && arguments['goToMyRidePublished'] == true) ? 1 : 0;

    return GetX(
        init: MyRideController(),
        builder: (controller) {
          return controller.isLoading.value
              ? Center(child: Center(child: Constant.loader()))
              : DefaultTabController(
                  initialIndex: initialIndex,
                  length: 4,
                  child: Scaffold(
                    backgroundColor: themeChange.getThem()
                        ? AppThemeData.grey800
                        : AppThemeData.grey100,
                    appBar: AppBar(
                      backgroundColor: themeChange.getThem()
                          ? AppThemeData.grey900
                          : AppThemeData.grey50,
                      centerTitle: false,
                      automaticallyImplyLeading: false,
                      title: Row(
                        children: [
                          Text(
                            "My Rides".tr,
                            style: TextStyle(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey100
                                    : AppThemeData.grey800,
                                fontFamily: AppThemeData.bold,
                                fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      elevation: 0,
                      bottom: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: AppThemeData.primary300,
                        indicatorColor: AppThemeData.primary300,
                        unselectedLabelStyle: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey50
                              : AppThemeData.grey700,
                        ),
                        tabs: [
                          Tab(
                            text: 'Booked'.tr,
                          ),
                          Tab(
                            text: 'Publishes'.tr,
                          ),
                          Tab(
                            text: 'Cancelled'.tr,
                          ),
                          Tab(
                            text: 'Completed'.tr,
                          ),
                        ],
                      ),
                    ),
                    body: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: TabBarView(
                          children: [
                            if (controller.myBooking.isEmpty)
                              Constant.showEmptyView(
                                  message: "Booking Not found".tr,
                                  isDarkMode: themeChange.getThem())
                            else
                              RefreshIndicator(
                                onRefresh: () => controller.getBookedRight(),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: controller.myBooking.length,
                                  itemBuilder: (context, index) {
                                    BookingModel bookingModel =
                                        controller.myBooking[index];
                                    return StreamBuilder<BookedUserModel?>(
                                        stream:
                                            BookingUtils.getMyBookingUserStream(
                                                bookingModel),
                                        builder: (context, snapshot) {
                                          switch (snapshot.connectionState) {
                                            case ConnectionState.waiting:
                                              return const SizedBox();
                                            case ConnectionState.active:
                                            case ConnectionState.done:
                                              if (snapshot.hasError) {
                                                return Text(
                                                    snapshot.error.toString());
                                              } else {
                                                BookedUserModel?
                                                    bookingUserModel =
                                                    snapshot.data;
                                                if (bookingUserModel == null) {
                                                  return const SizedBox();
                                                }
                                                StopOverModel? stopOverModel =
                                                    bookingUserModel.stopOver;
                                                return InkWell(
                                                  onTap: () {
                                                    Get.to(const BookedDetailsScreen(),
                                                            arguments: {
                                                          "bookingModel":
                                                              bookingModel,
                                                          "bookingUserModel":
                                                              bookingUserModel
                                                        })!
                                                        .then(
                                                      (value) {
                                                        controller
                                                            .getBookedRight();
                                                      },
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 5),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: themeChange
                                                                .getThem()
                                                            ? AppThemeData
                                                                .grey900
                                                            : AppThemeData
                                                                .grey50,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(20),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          RichText(
                                                                            text:
                                                                                TextSpan(
                                                                              style: Theme.of(context).textTheme.bodyLarge,
                                                                              children: [
                                                                                // Use address strings instead of geocoding for better web support
                                                                                TextSpan(
                                                                                  text: stopOverModel?.startAddress?.split(',').first ?? 'Location',
                                                                                  style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800, fontFamily: AppThemeData.bold, fontSize: 14),
                                                                                ),
                                                                                WidgetSpan(
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                                                                    child: SvgPicture.asset("assets/icons/ic_right_arrow.svg"),
                                                                                  ),
                                                                                ),
                                                                                TextSpan(
                                                                                  text: stopOverModel?.endAddress?.split(',').first ?? 'Location',
                                                                                  style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800, fontFamily: AppThemeData.bold, fontSize: 14),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            Constant.amountShow(amount: bookingModel.pricePerSeat.toString()),
                                                                            maxLines:
                                                                                1,
                                                                            style:
                                                                                TextStyle(
                                                                              color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
                                                                              fontSize: 16,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              fontFamily: AppThemeData.bold,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    RoundedButtonFill(
                                                                      title: bookingModel.status ==
                                                                              Constant
                                                                                  .placed
                                                                          ? "Accepted"
                                                                          : bookingModel
                                                                              .status
                                                                              .toString()
                                                                              .toUpperCase(),
                                                                      color: bookingModel.status ==
                                                                              Constant
                                                                                  .placed
                                                                          ? AppThemeData
                                                                              .secondary300
                                                                          : AppThemeData
                                                                              .success400,
                                                                      width: 22,
                                                                      height: 4,
                                                                      fontSizes:
                                                                          12,
                                                                      textColor: bookingModel.status ==
                                                                              Constant
                                                                                  .placed
                                                                          ? AppThemeData
                                                                              .secondary600
                                                                          : AppThemeData
                                                                              .grey50,
                                                                      onPress:
                                                                          () {},
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                  height: 20,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          SvgPicture
                                                                              .asset(
                                                                            "assets/icons/ic_calender.svg",
                                                                            height:
                                                                                18,
                                                                            width:
                                                                                18,
                                                                            colorFilter:
                                                                                ColorFilter.mode(themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey700, BlendMode.srcIn),
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                10,
                                                                          ),
                                                                          Text(
                                                                            Constant.timestampToDate(bookingModel.departureDateTime!),
                                                                            maxLines:
                                                                                1,
                                                                            style:
                                                                                TextStyle(
                                                                              color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey700,
                                                                              fontSize: 14,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              fontFamily: AppThemeData.medium,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          SvgPicture
                                                                              .asset(
                                                                            "assets/icons/ic_time.svg",
                                                                            height:
                                                                                18,
                                                                            width:
                                                                                18,
                                                                            colorFilter:
                                                                                ColorFilter.mode(themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey700, BlendMode.srcIn),
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                10,
                                                                          ),
                                                                          Text(
                                                                            Constant.timestampToTime(bookingModel.departureDateTime!),
                                                                            maxLines:
                                                                                1,
                                                                            style:
                                                                                TextStyle(
                                                                              color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey700,
                                                                              fontSize: 14,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              fontFamily: AppThemeData.medium,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          SvgPicture
                                                                              .asset(
                                                                            "assets/icons/ic_user_icon.svg",
                                                                            height:
                                                                                18,
                                                                            width:
                                                                                18,
                                                                            colorFilter:
                                                                                ColorFilter.mode(themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey700, BlendMode.srcIn),
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                10,
                                                                          ),
                                                                          Text(
                                                                            "${_formatSeatLabelsCsv(bookingUserModel.bookedSeat)} Passenger",
                                                                            maxLines:
                                                                                1,
                                                                            style:
                                                                                TextStyle(
                                                                              color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey700,
                                                                              fontSize: 14,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              fontFamily: AppThemeData.medium,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          SingleChildScrollView(
                                                                        scrollDirection:
                                                                            Axis.horizontal,
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            SvgPicture.asset(
                                                                              "assets/icons/ic_wallet.svg",
                                                                              height: 18,
                                                                              width: 18,
                                                                              colorFilter: ColorFilter.mode(themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey700, BlendMode.srcIn),
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            Text(
                                                                              "${bookingUserModel.paymentType}",
                                                                              maxLines: 1,
                                                                              style: TextStyle(
                                                                                color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey700,
                                                                                fontSize: 14,
                                                                                overflow: TextOverflow.ellipsis,
                                                                                fontFamily: AppThemeData.medium,
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              " (${bookingUserModel.paymentStatus == true ? "Paid" : "UnPaid"})",
                                                                              style: TextStyle(color: bookingUserModel.paymentStatus == true ? AppThemeData.success400 : AppThemeData.warning300, fontFamily: AppThemeData.bold, fontSize: 14),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )
                                                              ],
                                                            ),
                                                            const Padding(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      vertical:
                                                                          10),
                                                              child: Divider(),
                                                            ),
                                                            FutureBuilder<
                                                                    UserModel?>(
                                                                future: UserUtils.getUserProfile(
                                                                    bookingModel
                                                                        .createdBy
                                                                        .toString()),
                                                                builder: (context,
                                                                    snapshot) {
                                                                  switch (snapshot
                                                                      .connectionState) {
                                                                    case ConnectionState
                                                                          .waiting:
                                                                      return Center(
                                                                          child:
                                                                              Constant.loader());
                                                                    case ConnectionState
                                                                          .done:
                                                                      if (snapshot
                                                                          .hasError) {
                                                                        return Text(snapshot
                                                                            .error
                                                                            .toString());
                                                                      } else if (snapshot
                                                                              .data ==
                                                                          null) {
                                                                        return const SizedBox();
                                                                      } else {
                                                                        UserModel?
                                                                            userModel =
                                                                            snapshot.data;

                                                                        return Row(
                                                                          children: [
                                                                            Stack(
                                                                              children: [
                                                                                ClipRRect(
                                                                                  borderRadius: BorderRadius.circular(60),
                                                                                  child: NetworkImageWidget(
                                                                                    imageUrl: userModel!.profilePic.toString(),
                                                                                    fit: BoxFit.cover,
                                                                                    height: Responsive.width(10, context),
                                                                                    width: Responsive.width(10, context),
                                                                                  ),
                                                                                ),
                                                                                Positioned(bottom: 0, right: 0, child: SvgPicture.asset("assets/icons/ic_verify.svg"))
                                                                              ],
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            Expanded(
                                                                              child: Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                                                            const SizedBox(
                                                                              width: 5,
                                                                            ),
                                                                            bookingModel.womenOnly == false
                                                                                ? const SizedBox()
                                                                                : SvgPicture.asset(
                                                                                    "assets/icons/ic_woman_icon.svg",
                                                                                    colorFilter: ColorFilter.mode(themeChange.getThem() ? Colors.pink : Colors.pink, BlendMode.srcIn),
                                                                                  ),
                                                                            const SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            SvgPicture.asset(
                                                                              "assets/icons/ic_luggage.svg",
                                                                              colorFilter: ColorFilter.mode(themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600, BlendMode.srcIn),
                                                                            )
                                                                          ],
                                                                        );
                                                                      }
                                                                    default:
                                                                      return Text(
                                                                          'Error'
                                                                              .tr);
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
                                              return Text('Error'.tr);
                                          }
                                        });
                                  },
                                ),
                              ),
                            if (controller.publisherBooking.isEmpty)
                              Constant.showEmptyView(
                                  message: "Booking Not found".tr,
                                  isDarkMode: themeChange.getThem())
                            else
                              RefreshIndicator(
                                onRefresh: () => controller.getBookedRight(),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: controller.publisherBooking.length,
                                  itemBuilder: (context, index) {
                                    BookingModel bookingModel =
                                        controller.publisherBooking[index];
                                    return InkWell(
                                      onTap: () {
                                        Get.to(const PublishedDetailsScreen(),
                                                arguments: {
                                              "bookingModel": bookingModel
                                            })!
                                            .then(
                                          (value) {
                                            if (value == true) {
                                              controller.getBookedRight();
                                            }
                                          },
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
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge,
                                                        children: [
                                                          // Use address strings instead of geocoding
                                                          TextSpan(
                                                            text: bookingModel
                                                                    .pickUpAddress
                                                                    ?.split(',')
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
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10),
                                                              child: SvgPicture
                                                                  .asset(
                                                                      "assets/icons/ic_right_arrow.svg"),
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text: bookingModel
                                                                    .dropAddress
                                                                    ?.split(',')
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
                                                    Text(
                                                      Constant.amountShow(
                                                          amount: bookingModel
                                                              .pricePerSeat
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
                                                  height: 5,
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      SvgPicture.asset(
                                                        "assets/icons/ic_calender.svg",
                                                        height: 18,
                                                        width: 18,
                                                        colorFilter: ColorFilter.mode(
                                                            themeChange
                                                                    .getThem()
                                                                ? AppThemeData
                                                                    .grey200
                                                                : AppThemeData
                                                                    .grey700,
                                                            BlendMode.srcIn),
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        Constant.timestampToDate(
                                                            bookingModel
                                                                .departureDateTime!),
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          color: themeChange
                                                                  .getThem()
                                                              ? AppThemeData
                                                                  .grey200
                                                              : AppThemeData
                                                                  .grey700,
                                                          fontSize: 14,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          fontFamily:
                                                              AppThemeData
                                                                  .medium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      SvgPicture.asset(
                                                        "assets/icons/ic_time.svg",
                                                        height: 18,
                                                        width: 18,
                                                        colorFilter: ColorFilter.mode(
                                                            themeChange
                                                                    .getThem()
                                                                ? AppThemeData
                                                                    .grey200
                                                                : AppThemeData
                                                                    .grey700,
                                                            BlendMode.srcIn),
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        Constant.timestampToTime(
                                                            bookingModel
                                                                .departureDateTime!),
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          color: themeChange
                                                                  .getThem()
                                                              ? AppThemeData
                                                                  .grey200
                                                              : AppThemeData
                                                                  .grey700,
                                                          fontSize: 14,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          fontFamily:
                                                              AppThemeData
                                                                  .medium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      SvgPicture.asset(
                                                        "assets/icons/ic_user_icon.svg",
                                                        height: 18,
                                                        width: 18,
                                                        colorFilter: ColorFilter.mode(
                                                            themeChange
                                                                    .getThem()
                                                                ? AppThemeData
                                                                    .grey200
                                                                : AppThemeData
                                                                    .grey700,
                                                            BlendMode.srcIn),
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        "${_formatSeatLabelsCsv(bookingModel.bookedSeat)} Seats Booked"
                                                            .tr,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          color: themeChange
                                                                  .getThem()
                                                              ? AppThemeData
                                                                  .grey200
                                                              : AppThemeData
                                                                  .grey700,
                                                          fontSize: 14,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          fontFamily:
                                                              AppThemeData
                                                                  .medium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      SvgPicture.asset(
                                                        bookingModel.publish ==
                                                                true
                                                            ? "assets/icons/ic_check.svg"
                                                            : "assets/icons/ic_uncheck.svg",
                                                        height: 18,
                                                        width: 18,
                                                        colorFilter: ColorFilter.mode(
                                                            bookingModel.publish ==
                                                                    true
                                                                ? AppThemeData
                                                                    .success400
                                                                : AppThemeData
                                                                    .warning300,
                                                            BlendMode.srcIn),
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        bookingModel.publish ==
                                                                true
                                                            ? "Published"
                                                            : "UnPublished",
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          color: bookingModel.publish ==
                                                                  true
                                                              ? AppThemeData
                                                                  .success400
                                                              : AppThemeData
                                                                  .warning300,
                                                          fontSize: 14,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          fontFamily:
                                                              AppThemeData
                                                                  .medium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 5),
                                                  child: Divider(),
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "Publish on : ${Constant.timestampToDateTime(bookingModel.createdAt!)}",
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
                                                          fontFamily:
                                                              AppThemeData
                                                                  .regular,
                                                        ),
                                                      ),
                                                    ),
                                                    // RoundedButtonFill(
                                                    //   title: bookingModel.status == Constant.onGoing
                                                    //       ? "Complete"
                                                    //       : bookingModel.status == Constant.completed
                                                    //           ? "Completed"
                                                    //           : "OnGoing",
                                                    //   color: bookingModel.status == Constant.onGoing
                                                    //       ? AppThemeData.primary300
                                                    //       : bookingModel.status == Constant.completed
                                                    //           ? AppThemeData.success500
                                                    //           : AppThemeData.secondary400,
                                                    //   width: 20,
                                                    //   height: 4,
                                                    //   fontSizes: 12,
                                                    //   textColor: AppThemeData.grey50,
                                                    //   onPress: () async {
                                                    //     if (bookingModel.status != Constant.completed) {
                                                    //       if (bookingModel.status == Constant.placed) {
                                                    //         if (bookingModel.departureDateTime!.toDate().isAfter(DateTime.now())) {
                                                    //           ShowToastDialog.showToast(
                                                    //               "You will ride departure time is ${Constant.timestampToDateTime(bookingModel.departureDateTime!)}");
                                                    //         } else {
                                                    //           bookingModel.status = Constant.onGoing;
                                                    //           await BookingUtils.setBooking(bookingModel).then(
                                                    //             (value) {
                                                    //               ShowToastDialog.showToast("Status change successfully".tr);
                                                    //               controller.getBookedRight();
                                                    //             },
                                                    //           );
                                                    //         }
                                                    //       } else if (bookingModel.status == Constant.onGoing) {
                                                    //         bookingModel.status = Constant.completed;
                                                    //
                                                    //         bookingModel.bookedUserId!.forEach(
                                                    //           (element) async {
                                                    //             await UserUtils.getUserProfile(element.toString()).then(
                                                    //               (value) {
                                                    //                 SendNotification.sendOneNotification(
                                                    //                     type: Constant.ride_completed, token: value!.fcmToken.toString(), payload: {});
                                                    //                 SendNotification.sendOneNotification(type: Constant.feedback, token: value.fcmToken.toString(), payload: {});
                                                    //               },
                                                    //             );
                                                    //           },
                                                    //         );
                                                    //         await BookingUtils.setBooking(bookingModel).then(
                                                    //           (value) {
                                                    //             ShowToastDialog.showToast("Status change successfully".tr);
                                                    //             controller.getBookedRight();
                                                    //           },
                                                    //         );
                                                    //       }
                                                    //     }
                                                    //   },
                                                    // ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            // Third tab - Cancelled bookings
                            if (controller.cancelledBooking.isEmpty)
                              Constant.showEmptyView(
                                  message: "No Cancelled Bookings".tr,
                                  isDarkMode: themeChange.getThem())
                            else
                              RefreshIndicator(
                                onRefresh: () => controller.getBookedRight(),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: controller.cancelledBooking.length,
                                  itemBuilder: (context, index) {
                                    BookingModel bookingModel =
                                        controller.cancelledBooking[index];
                                    return InkWell(
                                      onTap: () async {
                                        // Check if this is a published ride (created by current user) or a booked ride
                                        bool isPublishedRide =
                                            bookingModel.createdBy ==
                                                AuthUtils.getCurrentUid();

                                        if (isPublishedRide) {
                                          // Navigate to PublishedDetailsScreen for driver's cancelled rides
                                          Get.to(const PublishedDetailsScreen(),
                                                  arguments: {
                                                "bookingModel": bookingModel
                                              })!
                                              .then(
                                            (value) {
                                              if (value == true) {
                                                controller.getBookedRight();
                                              }
                                            },
                                          );
                                        } else {
                                          // Fetch booking user data for passenger's cancelled bookings
                                          BookedUserModel? bookingUserModel =
                                              await BookingUtils
                                                  .getMyBookingUser(
                                                      bookingModel);

                                          Get.to(const BookedDetailsScreen(),
                                                  arguments: {
                                                "bookingModel": bookingModel,
                                                "bookingUserModel":
                                                    bookingUserModel
                                              })!
                                              .then(
                                            (value) {
                                              controller.getBookedRight();
                                            },
                                          );
                                        }
                                      },
                                      // Use publishes-style visual for Cancelled
                                      child: _buildPublishesStyleCard(
                                        bookingModel,
                                        themeChange,
                                        context,
                                        statusLabel: "Cancelled",
                                      ),
                                    );
                                  },
                                ),
                              ),
                            // Fourth tab - Completed bookings
                            if (controller.completedBooking.isEmpty)
                              Constant.showEmptyView(
                                  message: "No Completed Bookings".tr,
                                  isDarkMode: themeChange.getThem())
                            else
                              RefreshIndicator(
                                onRefresh: () => controller.getBookedRight(),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: controller.completedBooking.length,
                                  itemBuilder: (context, index) {
                                    BookingModel bookingModel =
                                        controller.completedBooking[index];
                                    return StreamBuilder<BookedUserModel?>(
                                        stream:
                                            BookingUtils.getMyBookingUserStream(
                                                bookingModel),
                                        builder: (context, snapshot) {
                                          switch (snapshot.connectionState) {
                                            case ConnectionState.waiting:
                                              return const SizedBox();
                                            case ConnectionState.active:
                                            case ConnectionState.done:
                                              if (snapshot.hasError) {
                                                return Text(
                                                    snapshot.error.toString());
                                              } else {
                                                BookedUserModel?
                                                    bookingUserModel =
                                                    snapshot.data;

                                                // For completed bookings, always use publishes-style card
                                                return InkWell(
                                                  onTap: () {
                                                    // Check if this is a published ride (created by current user) or a booked ride
                                                    bool isPublishedRide =
                                                        bookingModel
                                                                .createdBy ==
                                                            AuthUtils
                                                                .getCurrentUid();

                                                    if (isPublishedRide) {
                                                      // Navigate to PublishedDetailsScreen for driver's completed rides
                                                      Get.to(const PublishedDetailsScreen(),
                                                              arguments: {
                                                            "bookingModel":
                                                                bookingModel
                                                          })!
                                                          .then(
                                                        (value) {
                                                          if (value == true) {
                                                            controller
                                                                .getBookedRight();
                                                          }
                                                        },
                                                      );
                                                    } else {
                                                      // Navigate to BookedDetailsScreen for passenger's completed rides
                                                      Get.to(const BookedDetailsScreen(),
                                                              arguments: {
                                                            "bookingModel":
                                                                bookingModel,
                                                            "bookingUserModel":
                                                                bookingUserModel
                                                          })!
                                                          .then(
                                                        (value) {
                                                          controller
                                                              .getBookedRight();
                                                        },
                                                      );
                                                    }
                                                  },
                                                  // Use publishes-style visual for Completed
                                                  child:
                                                      _buildPublishesStyleCard(
                                                    bookingModel,
                                                    themeChange,
                                                    context,
                                                    statusLabel: "Completed",
                                                  ),
                                                );
                                              }
                                            default:
                                              return Text('Error'.tr);
                                          }
                                        });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
        });
  }

  // Publishes-style card reused for Completed and Cancelled tabs with a custom status label
  Widget _buildPublishesStyleCard(
    BookingModel bookingModel,
    DarkThemeProvider themeChange,
    BuildContext context, {
    String statusLabel = "Completed",
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: themeChange.getThem()
              ? AppThemeData.grey900
              : AppThemeData.grey50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge,
                      children: [
                        // Use address strings instead of geocoding
                        TextSpan(
                          text: bookingModel.pickUpAddress?.split(',').first ??
                              'Location',
                          style: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey100
                                  : AppThemeData.grey800,
                              fontFamily: AppThemeData.bold,
                              fontSize: 14),
                        ),
                        WidgetSpan(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: SvgPicture.asset(
                                "assets/icons/ic_right_arrow.svg"),
                          ),
                        ),
                        TextSpan(
                          text: bookingModel.dropAddress?.split(',').first ??
                              'Location',
                          style: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey100
                                  : AppThemeData.grey800,
                              fontFamily: AppThemeData.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Constant.amountShow(
                        amount: bookingModel.pricePerSeat.toString()),
                    maxLines: 1,
                    style: TextStyle(
                      color: themeChange.getThem()
                          ? AppThemeData.grey100
                          : AppThemeData.grey800,
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                      fontFamily: AppThemeData.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                Constant.timestampToDateTime(bookingModel.departureDateTime!),
                maxLines: 1,
                style: TextStyle(
                  color: themeChange.getThem()
                      ? AppThemeData.grey200
                      : AppThemeData.grey700,
                  fontSize: 12,
                  overflow: TextOverflow.ellipsis,
                  fontFamily: AppThemeData.regular,
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      "assets/icons/ic_calender.svg",
                      height: 18,
                      width: 18,
                      colorFilter: ColorFilter.mode(
                        themeChange.getThem()
                            ? AppThemeData.grey200
                            : AppThemeData.grey700,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      Constant.timestampToDate(bookingModel.departureDateTime!),
                      maxLines: 1,
                      style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey200
                            : AppThemeData.grey700,
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                        fontFamily: AppThemeData.medium,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      "assets/icons/ic_time.svg",
                      height: 18,
                      width: 18,
                      colorFilter: ColorFilter.mode(
                        themeChange.getThem()
                            ? AppThemeData.grey200
                            : AppThemeData.grey700,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      Constant.timestampToTime(bookingModel.departureDateTime!),
                      maxLines: 1,
                      style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey200
                            : AppThemeData.grey700,
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                        fontFamily: AppThemeData.medium,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      "assets/icons/ic_user_icon.svg",
                      height: 18,
                      width: 18,
                      colorFilter: ColorFilter.mode(
                        themeChange.getThem()
                            ? AppThemeData.grey200
                            : AppThemeData.grey700,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "${_formatSeatLabelsCsv(bookingModel.bookedSeat)} Seats Booked"
                          .tr,
                      maxLines: 1,
                      style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey200
                            : AppThemeData.grey700,
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                        fontFamily: AppThemeData.medium,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      statusLabel == "Cancelled"
                          ? "assets/icons/ic_cancel.svg"
                          : "assets/icons/ic_check.svg",
                      height: 18,
                      width: 18,
                      colorFilter: ColorFilter.mode(
                        statusLabel == "Cancelled"
                            ? AppThemeData.warning300
                            : AppThemeData.success400,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      statusLabel,
                      maxLines: 1,
                      style: TextStyle(
                        color: statusLabel == "Cancelled"
                            ? AppThemeData.warning300
                            : AppThemeData.success400,
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                        fontFamily: AppThemeData.medium,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Divider(),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Publish on : ${Constant.timestampToDateTime(bookingModel.createdAt!)}",
                      maxLines: 1,
                      style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey200
                            : AppThemeData.grey700,
                        overflow: TextOverflow.ellipsis,
                        fontFamily: AppThemeData.regular,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Convert stored seat indices CSV (e.g., "1,2") to labels CSV (e.g., "A1,A2")
  String _formatSeatLabelsCsv(String? csv) {
    if (csv == null || csv.trim().isEmpty) return 'No';
    final parts =
        csv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    // Filter out seat index 0 (A1 - driver's seat) as it's always occupied by the driver
    final passengerSeats =
        parts.where((p) => (int.tryParse(p) ?? -1) != 0).map((p) {
      final idx = int.tryParse(p) ?? -1;
      return _seatIndexToLabel(idx);
    }).toList();

    // If no passenger seats are booked (only driver seat), return 'No'
    if (passengerSeats.isEmpty) return 'No';

    return passengerSeats.join(',');
  }

  String _seatIndexToLabel(int index) {
    const labels = ['A1', 'A2', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3'];
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return 'S$index';
  }
}
