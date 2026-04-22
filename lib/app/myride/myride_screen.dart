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
import 'package:poolmate/services/share_ride_service.dart';
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
                                                                            "${BookingUtils.formatSeatLabelsCsv(bookingUserModel.bookedSeat)} Passenger",
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
                                      child: _buildBookingCard(
                                        bookingModel,
                                        themeChange,
                                        context,
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
                                      child: _buildBookingCard(
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
                                                  child: _buildBookingCard(
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
  // Now also used for the main "Published" tab to remove duplication
  Widget _buildBookingCard(
    BookingModel bookingModel,
    DarkThemeProvider themeChange,
    BuildContext context, {
    String?
        statusLabel, // Optional: if null, logic inside decides (e.g., Published/UnPublished)
  }) {
    // Determine status label and color if not provided
    String displayStatus;
    Color statusColor;
    String statusIcon;

    if (statusLabel != null) {
      // Use provided override (e.g. "Cancelled", "Completed")
      displayStatus = statusLabel;
      if (statusLabel == "Cancelled") {
        statusColor = AppThemeData.warning300;
        statusIcon = "assets/icons/ic_cancel.svg";
      } else {
        statusColor = AppThemeData.success400;
        statusIcon = "assets/icons/ic_check.svg";
      }
    } else {
      // Default logic for Published/UnPublished based on model
      if (bookingModel.publish == true) {
        displayStatus = "Published";
        statusColor = AppThemeData.success400;
        statusIcon = "assets/icons/ic_check.svg";
      } else {
        displayStatus = "UnPublished";
        statusColor = AppThemeData.warning300;
        statusIcon = "assets/icons/ic_uncheck.svg";
      }
    }

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyLarge,
                            children: [
                              // Use address strings instead of geocoding
                              TextSpan(
                                text: bookingModel.pickUpAddress
                                        ?.split(',')
                                        .first ??
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: SvgPicture.asset(
                                      "assets/icons/ic_right_arrow.svg"),
                                ),
                              ),
                              TextSpan(
                                text: bookingModel.dropAddress
                                        ?.split(',')
                                        .first ??
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
                  ),
                  if (statusLabel == null)
                    Builder(builder: (context) {
                      // Calculate available seats
                      int avSeats = 0;
                      final totalS = int.tryParse(
                              bookingModel.vehicleInformation?.seatCount ??
                                  '0') ??
                          0;
                      final allowed = bookingModel.selectedSeats ?? [];
                      final bookedSStr = (bookingModel.bookedSeat ?? "0")
                          .split(',')
                          .where((s) => s.isNotEmpty);
                      final bookedS =
                          bookedSStr.map((s) => int.tryParse(s) ?? -1).toList();
                      final tempSel = bookingModel.tempSeatSelection ?? [];

                      for (int i = 1; i < totalS; i++) {
                        if (allowed.contains(i.toString()) &&
                            !bookedS.contains(i) &&
                            !tempSel.contains(i)) {
                          avSeats++;
                        }
                      }

                      // Calculate distance
                      String distString = "N/A";
                      if (bookingModel
                                  .pickupLocation?.geometry?.location?.lat !=
                              null &&
                          bookingModel.dropLocation?.geometry?.location?.lat !=
                              null) {
                        final startLoc =
                            bookingModel.pickupLocation!.geometry!.location!;
                        final endLoc =
                            bookingModel.dropLocation!.geometry!.location!;
                        distString =
                            "${Constant.calculateDistance(startLoc, endLoc).toStringAsFixed(2)} ${Constant.distanceType}";
                      }

                      final isShareEnabled = avSeats > 0;
                      final isShareLoading = ValueNotifier<bool>(false);

                      return ValueListenableBuilder<bool>(
                        valueListenable: isShareLoading,
                        builder: (context, isLoading, child) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: InkWell(
                              onTap: (isShareEnabled && !isLoading)
                                  ? () async {
                                      isShareLoading.value = true;
                                      final stopOver = StopOverModel(
                                        startAddress: bookingModel.pickUpAddress,
                                        endAddress: bookingModel.dropAddress,
                                        price: bookingModel.pricePerSeat,
                                      );
                                      await ShareRideService.shareRide(
                                        context,
                                        bookingModel,
                                        stopOver,
                                        availableSeats: avSeats,
                                        distance: distString,
                                      );
                                      isShareLoading.value = false;
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: themeChange.getThem()
                                      ? (isShareEnabled
                                          ? AppThemeData.grey800
                                          : AppThemeData.grey900)
                                      : (isShareEnabled
                                          ? AppThemeData.grey100
                                          : AppThemeData.grey200),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: themeChange.getThem()
                                        ? (isShareEnabled
                                            ? AppThemeData.grey700
                                            : AppThemeData.grey800)
                                        : (isShareEnabled
                                            ? AppThemeData.grey300
                                            : AppThemeData.grey200),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    isLoading
                                        ? SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: themeChange.getThem()
                                                  ? AppThemeData.grey200
                                                  : AppThemeData.grey600,
                                            ),
                                          )
                                        : Icon(
                                            Icons.share_outlined,
                                            size: 14,
                                            color: themeChange.getThem()
                                                ? (isShareEnabled
                                                    ? AppThemeData.grey200
                                                    : AppThemeData.grey600)
                                                : (isShareEnabled
                                                    ? AppThemeData.grey700
                                                    : AppThemeData.grey400),
                                          ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isLoading ? 'Sharing...' : 'Share',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: AppThemeData.medium,
                                        color: themeChange.getThem()
                                            ? (isShareEnabled
                                                ? AppThemeData.grey200
                                                : AppThemeData.grey600)
                                            : (isShareEnabled
                                                ? AppThemeData.grey700
                                                : AppThemeData.grey400),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      );
                    }),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
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
              const SizedBox(
                height: 5,
              ),
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
                          BlendMode.srcIn),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
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
                          BlendMode.srcIn),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
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
                          BlendMode.srcIn),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      "${BookingUtils.formatSeatLabelsCsv(bookingModel.bookedSeat)} Seats Booked"
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
                      statusIcon,
                      height: 18,
                      width: 18,
                      colorFilter:
                          ColorFilter.mode(statusColor, BlendMode.srcIn),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      displayStatus,
                      maxLines: 1,
                      style: TextStyle(
                        color: statusColor,
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
}
