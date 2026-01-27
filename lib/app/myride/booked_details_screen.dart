import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:location/location.dart' as loc;
import 'package:poolmate/app/chat/chat_screen.dart';
import 'package:poolmate/app/rating_view_screen/rating_view_screen.dart';
import 'package:poolmate/app/report_help_screen/report_help_screen.dart';
import 'package:poolmate/app/review/review_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/booked_details_controller.dart';
import 'package:poolmate/model/map/geometry.dart';
import 'package:poolmate/model/sos_model.dart';
import 'package:poolmate/model/tax_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/custom_dialog_box.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/sos_utils.dart';
import 'package:poolmate/utils/network_image_widget.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:poolmate/services/whatsapp_service.dart';
import 'package:poolmate/constant/send_notification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:poolmate/services/ticket_service.dart';
import 'package:poolmate/app/pdf_viewer/pdf_viewer_screen.dart';

class BookedDetailsScreen extends StatelessWidget {
  const BookedDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: BookedDetailsController(),
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
                    )),
                title: Text(
                  "Ride Details".tr,
                  style: TextStyle(
                      color: themeChange.getThem()
                          ? AppThemeData.grey100
                          : AppThemeData.grey800,
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 16),
                ),
                elevation: 0,
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: InkWell(
                      onTap: () {
                        Get.to(const ReportHelpScreen(), arguments: {
                          "reportedBy": "customer",
                          "reportedTo": controller.bookingModel.value.createdBy,
                          "bookingId": controller.bookingModel.value.id
                        });
                      },
                      child: Text(
                        "Report Ride".tr,
                        style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.primary300
                                : AppThemeData.primary300,
                            fontFamily: AppThemeData.semiBold,
                            fontSize: 16),
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
              body: SafeArea(
                child: controller.isLoading.value
                    ? Center(child: Constant.loader())
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Trip info".tr,
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
                                      ),
                                      InkWell(
                                        onTap: () {
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return CustomDialogBox(
                                                  title: "Ride ID".tr,
                                                  descriptions: controller
                                                      .bookingModel.value.id
                                                      .toString(),
                                                  positiveString: "Copied".tr,
                                                  negativeString: "Cancel".tr,
                                                  positiveClick: () async {
                                                    Clipboard.setData(
                                                            ClipboardData(
                                                                text: controller
                                                                    .bookingModel
                                                                    .value
                                                                    .id
                                                                    .toString()))
                                                        .then((_) {
                                                      ShowToastDialog.showToast(
                                                          "Booking id copied");
                                                      Get.back(result: true);
                                                    });
                                                  },
                                                  negativeClick: () {
                                                    Get.back();
                                                  },
                                                  img: null,
                                                );
                                              });
                                        },
                                        child: Text(
                                          Constant.orderId(
                                              orderId: controller
                                                  .bookingModel.value.id
                                                  .toString()),
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey100
                                                : AppThemeData.grey800,
                                            fontSize: 14,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.bold,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/icons/ic_calender.svg",
                                          height: 20,
                                          width: 20,
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
                                          Constant.timestampToDateTime(
                                              controller.bookingModel.value
                                                  .departureDateTime!),
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey200
                                                : AppThemeData.grey700,
                                            fontSize: 16,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.medium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/icons/ic_time.svg",
                                          height: 20,
                                          width: 20,
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
                                          controller.bookingUserModel.value
                                              .stopOver!.duration!.text
                                              .toString(),
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey200
                                                : AppThemeData.grey700,
                                            fontSize: 16,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.medium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/icons/ic_distance.svg",
                                          height: 20,
                                          width: 20,
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
                                          "${Constant.distanceCalculate(controller.bookingUserModel.value.stopOver!.distance!.value.toString())} ${Constant.distanceType}",
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey200
                                                : AppThemeData.grey700,
                                            fontSize: 16,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.medium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/icons/ic_luggage.svg",
                                          height: 20,
                                          width: 20,
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
                                          "${controller.bookingModel.value.luggageAllowed!.toString()} luggage",
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey200
                                                : AppThemeData.grey700,
                                            fontSize: 16,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.medium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  controller.bookingModel.value
                                              .twoPassengerMaxInBack ==
                                          false
                                      ? const SizedBox()
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                "assets/icons/ic_back_two.svg",
                                                height: 20,
                                                width: 20,
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                "2 Passengers Max in Back Seat",
                                                maxLines: 1,
                                                style: TextStyle(
                                                  color: themeChange.getThem()
                                                      ? AppThemeData.grey200
                                                      : AppThemeData.grey700,
                                                  fontSize: 16,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  fontFamily:
                                                      AppThemeData.medium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/icons/ic_wallet.svg",
                                          height: 20,
                                          width: 20,
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
                                          "${controller.bookingUserModel.value.paymentType}",
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey200
                                                : AppThemeData.grey700,
                                            fontSize: 16,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.medium,
                                          ),
                                        ),
                                        Text(
                                          " (${controller.bookingUserModel.value.paymentStatus == true ? "Paid" : "UnPaid"})",
                                          style: TextStyle(
                                              color: controller
                                                          .bookingUserModel
                                                          .value
                                                          .paymentStatus ==
                                                      true
                                                  ? AppThemeData.success400
                                                  : AppThemeData.warning300,
                                              fontFamily: AppThemeData.bold,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.verified_user,
                                          color: const Color(0xFF7E7D7D),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          "OTP : ",
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey200
                                                : AppThemeData.grey700,
                                            fontSize: 16,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.medium,
                                          ),
                                        ),
                                        Text(
                                          controller
                                                  .bookingUserModel.value.otp ??
                                              "-",
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey100
                                                : AppThemeData.grey900,
                                            fontSize: 16,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 5),
                                    child: Divider(),
                                  ),
                                  Timeline.tileBuilder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    theme: TimelineThemeData(
                                      nodePosition: 0,
                                      // indicatorPosition: 0,
                                    ),
                                    builder: TimelineTileBuilder.connected(
                                      contentsAlign: ContentsAlign.basic,
                                      indicatorBuilder: (context, index) {
                                        return Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const ShapeDecoration(
                                            color: Color(0xFFF5F7F8),
                                            shape: OvalBorder(),
                                            shadows: [
                                              BoxShadow(
                                                color: Color(0xFFC1CED6),
                                                blurRadius: 0,
                                                offset: Offset(0, 0),
                                                spreadRadius: 2,
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                      connectorBuilder:
                                          (context, index, connectorType) {
                                        return const DashedLineConnector(
                                          color: AppThemeData.grey300,
                                          gap: 2,
                                        );
                                      },
                                      contentsBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 14),
                                          child: index == 0
                                              ? Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        controller
                                                                .bookingUserModel
                                                                .value
                                                                .stopOver!
                                                                .startAddress
                                                                ?.split(',')
                                                                .first ??
                                                            'Location',
                                                        style: TextStyle(
                                                            color: themeChange
                                                                    .getThem()
                                                                ? AppThemeData
                                                                    .grey100
                                                                : AppThemeData
                                                                    .grey800,
                                                            fontFamily:
                                                                AppThemeData
                                                                    .bold,
                                                            fontSize: 18)),
                                                    Text(
                                                      controller
                                                          .bookingUserModel
                                                          .value
                                                          .stopOver!
                                                          .startAddress
                                                          .toString(),
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                          color: themeChange
                                                                  .getThem()
                                                              ? AppThemeData
                                                                  .grey100
                                                              : AppThemeData
                                                                  .grey800,
                                                          fontFamily:
                                                              AppThemeData
                                                                  .regular,
                                                          fontSize: 14),
                                                    ),
                                                    const SizedBox(
                                                      height: 5,
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
                                                                  BlendMode
                                                                      .srcIn),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Text(
                                                          "${Constant.calculateDistance(Location(lat: controller.bookingUserModel.value.stopOver!.startLocation!.lat, lng: controller.bookingUserModel.value.stopOver!.startLocation!.lng), controller.bookingUserModel.value.pickupLocation!).toStringAsFixed(2)} ${Constant.distanceType} from your pickup location",
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                            color: themeChange
                                                                    .getThem()
                                                                ? AppThemeData
                                                                    .grey200
                                                                : AppThemeData
                                                                    .grey700,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            fontFamily:
                                                                AppThemeData
                                                                    .regular,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                )
                                              : Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        controller
                                                                .bookingUserModel
                                                                .value
                                                                .stopOver!
                                                                .endAddress
                                                                ?.split(',')
                                                                .first ??
                                                            'Location',
                                                        style: TextStyle(
                                                            color: themeChange
                                                                    .getThem()
                                                                ? AppThemeData
                                                                    .grey100
                                                                : AppThemeData
                                                                    .grey800,
                                                            fontFamily:
                                                                AppThemeData
                                                                    .bold,
                                                            fontSize: 18)),
                                                    Text(
                                                      controller
                                                          .bookingUserModel
                                                          .value
                                                          .stopOver!
                                                          .endAddress
                                                          .toString(),
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                          color: themeChange
                                                                  .getThem()
                                                              ? AppThemeData
                                                                  .grey100
                                                              : AppThemeData
                                                                  .grey800,
                                                          fontFamily:
                                                              AppThemeData
                                                                  .regular,
                                                          fontSize: 14),
                                                    ),
                                                    const SizedBox(
                                                      height: 5,
                                                    ),
                                                    Row(
                                                      children: [
                                                        SvgPicture.asset(
                                                          "assets/icons/ic_walk.svg",
                                                          colorFilter:
                                                              const ColorFilter
                                                                  .mode(
                                                                  AppThemeData
                                                                      .success400,
                                                                  BlendMode
                                                                      .srcIn),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Text(
                                                          "${Constant.calculateDistance(Location(lat: controller.bookingUserModel.value.stopOver!.endLocation!.lat, lng: controller.bookingUserModel.value.stopOver!.endLocation!.lng), controller.bookingUserModel.value.dropLocation!).toStringAsFixed(2)} ${Constant.distanceType} from your drop location",
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                            color: themeChange
                                                                    .getThem()
                                                                ? AppThemeData
                                                                    .grey200
                                                                : AppThemeData
                                                                    .grey700,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            fontFamily:
                                                                AppThemeData
                                                                    .regular,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                        );
                                      },
                                      itemCount: 2,
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
                                          "Seat No. Booked".tr,
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey200
                                                : AppThemeData.grey700,
                                            fontSize: 16,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.medium,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        " ${_formatSeatLabelsCsv(controller.bookingUserModel.value.bookedSeat)}",
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
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Price for one seat".tr,
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey200
                                                : AppThemeData.grey700,
                                            fontSize: 16,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.medium,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        Constant.amountShow(
                                            amount: controller
                                                .bookingModel.value.pricePerSeat
                                                .toString()),
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
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Subtotal".tr,
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey200
                                                : AppThemeData.grey700,
                                            fontSize: 16,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.medium,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        Constant.amountShow(
                                            amount: controller.bookingUserModel
                                                .value.subTotal),
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
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  controller.bookingUserModel.value.taxList ==
                                          null
                                      ? const SizedBox()
                                      : ListView.builder(
                                          padding: EdgeInsets.zero,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: controller.bookingUserModel
                                              .value.taxList!.length,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            TaxModel taxModel = controller
                                                .bookingUserModel
                                                .value
                                                .taxList![index];
                                            return Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "${taxModel.title.toString()} (${taxModel.type == "fix" ? Constant.amountShow(amount: taxModel.tax) : "${taxModel.tax}%"})",
                                                        style: TextStyle(
                                                          color: themeChange
                                                                  .getThem()
                                                              ? AppThemeData
                                                                  .grey200
                                                              : AppThemeData
                                                                  .grey700,
                                                          fontSize: 16,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          fontFamily:
                                                              AppThemeData
                                                                  .medium,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      "${Constant.amountShow(amount: Constant().calculateTax(amount: controller.bookingUserModel.value.subTotal.toString(), taxModel: taxModel).toStringAsFixed(Constant.currencyModel!.decimalDigits!).toString())} ",
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
                                                const Divider(
                                                  thickness: 1,
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Total".tr,
                                          style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey200
                                                : AppThemeData.grey700,
                                            fontSize: 16,
                                            overflow: TextOverflow.ellipsis,
                                            fontFamily: AppThemeData.medium,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "${Constant.amountShow(amount: controller.calculateAmount().toString())} ",
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
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: PreferredSize(
                                preferredSize: const Size.fromHeight(4.0),
                                child: Container(
                                  color: themeChange.getThem()
                                      ? AppThemeData.grey800
                                      : AppThemeData.grey100,
                                  height: 8.0,
                                ),
                              ),
                            ),
                            if (controller.publisherUserModel.value.id != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 5),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(60),
                                          child: NetworkImageWidget(
                                            imageUrl: controller
                                                .publisherUserModel
                                                .value
                                                .profilePic
                                                .toString(),
                                            height:
                                                Responsive.width(14, context),
                                            width:
                                                Responsive.width(14, context),
                                          ),
                                        ),
                                        Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: SvgPicture.asset(
                                                "assets/icons/ic_verify.svg",
                                                height: 24,
                                                width: 24))
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            controller.publisherUserModel.value
                                                .fullName()
                                                .toString(),
                                            style: TextStyle(
                                                color: themeChange.getThem()
                                                    ? AppThemeData.grey100
                                                    : AppThemeData.grey800,
                                                fontFamily: AppThemeData.bold,
                                                fontSize: 16),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                Constant.calculateReview(
                                                    reviewCount: controller
                                                        .publisherUserModel
                                                        .value
                                                        .reviewCount,
                                                    reviewSum: controller
                                                        .publisherUserModel
                                                        .value
                                                        .reviewSum),
                                                style: TextStyle(
                                                    color: themeChange.getThem()
                                                        ? AppThemeData.grey200
                                                        : AppThemeData.grey700,
                                                    fontFamily:
                                                        AppThemeData.medium,
                                                    fontSize: 14),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Icon(
                                                Icons.star,
                                                size: 14,
                                                color: themeChange.getThem()
                                                    ? AppThemeData.grey200
                                                    : AppThemeData.grey700,
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Text(
                                                "•",
                                                style: TextStyle(
                                                    color: themeChange.getThem()
                                                        ? AppThemeData.grey500
                                                        : AppThemeData.grey500,
                                                    fontFamily:
                                                        AppThemeData.medium,
                                                    fontSize: 14),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  Get.to(
                                                      const RatingViewScreen(),
                                                      arguments: {
                                                        "receiverUserId":
                                                            controller
                                                                .publisherUserModel
                                                                .value
                                                                .id
                                                      });
                                                },
                                                child: Text(
                                                  "${double.parse(controller.publisherUserModel.value.reviewCount ?? "0").toStringAsFixed(0)} Ratings",
                                                  style: TextStyle(
                                                      decoration: TextDecoration
                                                          .underline,
                                                      decorationColor:
                                                          AppThemeData
                                                              .primary300,
                                                      color:
                                                          themeChange.getThem()
                                                              ? AppThemeData
                                                                  .primary300
                                                              : AppThemeData
                                                                  .primary300,
                                                      fontFamily:
                                                          AppThemeData.medium,
                                                      fontSize: 14),
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
                                    InkWell(
                                      onTap: () async {
                                        await Constant.makePhoneCall(
                                            "${controller.publisherUserModel.value.countryCode.toString()} ${controller.publisherUserModel.value.phoneNumber.toString()}");
                                      },
                                      child: SvgPicture.asset(
                                        "assets/icons/ic_call.svg",
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Get.to(const ChatScreen(), arguments: {
                                          "receiverModel": controller
                                              .publisherUserModel.value
                                        });
                                      },
                                      child: SvgPicture.asset(
                                        "assets/icons/ic_chat.svg",
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/icons/ic_car.svg",
                                    colorFilter: ColorFilter.mode(
                                        themeChange.getThem()
                                            ? AppThemeData.grey300
                                            : AppThemeData.grey600,
                                        BlendMode.srcIn),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    "${controller.bookingModel.value.vehicleInformation!.vehicleBrand!.name} ${controller.bookingModel.value.vehicleInformation!.vehicleModel!.name} (${controller.bookingModel.value.vehicleInformation!.licensePlatNumber})",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey200
                                          : AppThemeData.grey700,
                                      fontFamily: AppThemeData.medium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            controller.bookingModel.value.travelPreference ==
                                    null
                                ? const SizedBox()
                                : Column(
                                    children: [
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 5),
                                        child: Divider(),
                                      ),
                                      controller
                                                      .bookingModel
                                                      .value
                                                      .travelPreference!
                                                      .chattiness ==
                                                  null ||
                                              controller
                                                  .bookingModel
                                                  .value
                                                  .travelPreference!
                                                  .chattiness!
                                                  .isEmpty
                                          ? const SizedBox()
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 5),
                                              child: Row(
                                                children: [
                                                  controller
                                                              .bookingModel
                                                              .value
                                                              .travelPreference!
                                                              .chattiness ==
                                                          "I’m the quite type"
                                                      ? SvgPicture.asset(
                                                          "assets/icons/ic_love_chat.svg")
                                                      : SvgPicture.asset(
                                                          "assets/icons/ic_quites.svg"),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Expanded(
                                                      child: Text(
                                                    controller
                                                        .bookingModel
                                                        .value
                                                        .travelPreference!
                                                        .chattiness
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: themeChange
                                                              .getThem()
                                                          ? AppThemeData.grey50
                                                          : AppThemeData
                                                              .grey900,
                                                      fontFamily:
                                                          AppThemeData.medium,
                                                    ),
                                                  )),
                                                ],
                                              ),
                                            ),
                                      controller
                                                      .bookingModel
                                                      .value
                                                      .travelPreference!
                                                      .smoking ==
                                                  null ||
                                              controller
                                                  .bookingModel
                                                  .value
                                                  .travelPreference!
                                                  .smoking!
                                                  .isEmpty
                                          ? const SizedBox()
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 5),
                                              child: Row(
                                                children: [
                                                  controller
                                                              .bookingModel
                                                              .value
                                                              .travelPreference!
                                                              .chattiness ==
                                                          "No smoking, Please"
                                                      ? SvgPicture.asset(
                                                          "assets/icons/ic_no_smoking.svg")
                                                      : SvgPicture.asset(
                                                          "assets/icons/ic_smoking.svg"),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Expanded(
                                                      child: Text(
                                                    controller
                                                        .bookingModel
                                                        .value
                                                        .travelPreference!
                                                        .smoking
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: themeChange
                                                              .getThem()
                                                          ? AppThemeData.grey50
                                                          : AppThemeData
                                                              .grey900,
                                                      fontFamily:
                                                          AppThemeData.medium,
                                                    ),
                                                  )),
                                                ],
                                              ),
                                            ),
                                      controller
                                                      .bookingModel
                                                      .value
                                                      .travelPreference!
                                                      .music ==
                                                  null ||
                                              controller
                                                  .bookingModel
                                                  .value
                                                  .travelPreference!
                                                  .music!
                                                  .isEmpty
                                          ? const SizedBox()
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 5),
                                              child: Row(
                                                children: [
                                                  controller
                                                              .bookingModel
                                                              .value
                                                              .travelPreference!
                                                              .music ==
                                                          "Silence is golden"
                                                      ? SvgPicture.asset(
                                                          "assets/icons/ic_no_music.svg")
                                                      : SvgPicture.asset(
                                                          "assets/icons/ic_music.svg"),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Expanded(
                                                      child: Text(
                                                    controller
                                                        .bookingModel
                                                        .value
                                                        .travelPreference!
                                                        .music
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: themeChange
                                                              .getThem()
                                                          ? AppThemeData.grey50
                                                          : AppThemeData
                                                              .grey900,
                                                      fontFamily:
                                                          AppThemeData.medium,
                                                    ),
                                                  )),
                                                ],
                                              ),
                                            ),
                                      controller.bookingModel.value
                                                      .travelPreference!.pets ==
                                                  null ||
                                              controller
                                                  .bookingModel
                                                  .value
                                                  .travelPreference!
                                                  .pets!
                                                  .isEmpty
                                          ? const SizedBox()
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 5),
                                              child: Row(
                                                children: [
                                                  SvgPicture.asset(
                                                      "assets/icons/pet.svg"),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Expanded(
                                                      child: Text(
                                                    controller
                                                        .bookingModel
                                                        .value
                                                        .travelPreference!
                                                        .pets
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: themeChange
                                                              .getThem()
                                                          ? AppThemeData.grey50
                                                          : AppThemeData
                                                              .grey900,
                                                      fontFamily:
                                                          AppThemeData.medium,
                                                    ),
                                                  )),
                                                ],
                                              ),
                                            ),
                                    ],
                                  )
                          ],
                        ),
                      ),
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PreferredSize(
                        preferredSize: const Size.fromHeight(4.0),
                        child: Container(
                          color: themeChange.getThem()
                              ? AppThemeData.grey700
                              : AppThemeData.grey200,
                          height: 6.0,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      controller.publisherUserModel.value.id != null &&
                              controller.bookingModel.value.status ==
                                  Constant.completed &&
                              controller.bookingUserModel.value.paymentStatus ==
                                  true
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: RoundedButtonFill(
                                      title: controller.reviewModel.value.id !=
                                              null
                                          ? "Edit Review"
                                          : "Add Review".tr,
                                      color: AppThemeData.primary300,
                                      textColor: AppThemeData.grey50,
                                      onPress: () async {
                                        Get.to(() => const ReviewScreen(),
                                                arguments: {
                                              "bookingModel":
                                                  controller.bookingModel.value,
                                              "senderUserModel":
                                                  controller.userModel.value,
                                              "reciverUserModel": controller
                                                  .publisherUserModel.value
                                            })!
                                            .then(
                                          (value) {
                                            if (value == true) {
                                              controller.getUserData();
                                              controller.getReview();
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RoundedButtonFill(
                                      title: "Tickets".tr,
                                      color: AppThemeData.secondary300,
                                      textColor: AppThemeData.grey50,
                                      onPress: () async {
                                        ShowToastDialog.showLoader(
                                            "Generating ticket...".tr);

                                        final result =
                                            await TicketService.generateTicket(
                                          bookingModel:
                                              controller.bookingModel.value,
                                          bookingUserModel:
                                              controller.bookingUserModel.value,
                                          userModel: controller.userModel.value,
                                          publisherUserModel: controller
                                              .publisherUserModel.value,
                                        );

                                        ShowToastDialog.closeLoader();

                                        if (result['success'] == true) {
                                          Get.to(() => const PdfViewerScreen(),
                                              arguments: {
                                                'pdf_url': result['pdf_url'],
                                              });
                                        } else {
                                          ShowToastDialog.showToast(
                                              result['message'] ??
                                                  'Failed to generate ticket');
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  controller.bookingModel.value.status ==
                                              Constant.onGoing ||
                                          controller
                                                  .bookingModel.value.status ==
                                              Constant.completed ||
                                          controller
                                                  .bookingModel.value.status ==
                                              Constant.canceled
                                      ? const SizedBox()
                                      : Expanded(
                                          child: RoundedButtonFill(
                                            title: "Cancel Booking".tr,
                                            color: AppThemeData.warning300,
                                            textColor: AppThemeData.grey50,
                                            onPress: () async {
                                              showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return CustomDialogBox(
                                                      title: "Cancel Ride".tr,
                                                      descriptions:
                                                          "Are you sure want to cancel ride?"
                                                              .tr,
                                                      positiveString: "OK".tr,
                                                      negativeString:
                                                          "Cancel".tr,
                                                      img: Image.asset(
                                                          'assets/icons/ic_cancel.svg',
                                                          height: 40,
                                                          width: 40),
                                                      positiveClick: () async {
                                                        ShowToastDialog
                                                            .showLoader(
                                                                "Please wait"
                                                                    .tr);
                                                        bool success =
                                                            await controller
                                                                .cancelBooking();
                                                        if (success) {
                                                          ShowToastDialog
                                                              .closeLoader();
                                                          ShowToastDialog.showToast(
                                                              "Booking Cancelled"
                                                                  .tr);
                                                          Get.back();
                                                          Get.back(
                                                              result: true);
                                                        } else {
                                                          ShowToastDialog
                                                              .closeLoader();
                                                          ShowToastDialog.showToast(
                                                              "Error cancelling booking"
                                                                  .tr);
                                                        }
                                                      },
                                                      negativeClick: () {
                                                        Get.back();
                                                      },
                                                    );
                                                  });
                                            },
                                          ),
                                        ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: RoundedButtonFill(
                                      title: "Tickets".tr,
                                      color: AppThemeData.primary300,
                                      textColor: AppThemeData.grey50,
                                      onPress: () async {
                                        ShowToastDialog.showLoader(
                                            "Generating ticket...".tr);

                                        final result =
                                            await TicketService.generateTicket(
                                          bookingModel:
                                              controller.bookingModel.value,
                                          bookingUserModel:
                                              controller.bookingUserModel.value,
                                          userModel: controller.userModel.value,
                                          publisherUserModel: controller
                                              .publisherUserModel.value,
                                        );

                                        ShowToastDialog.closeLoader();

                                        if (result['success'] == true) {
                                          Get.to(() => const PdfViewerScreen(),
                                              arguments: {
                                                'pdf_url': result['pdf_url'],
                                              });
                                        } else {
                                          ShowToastDialog.showToast(
                                              result['message'] ??
                                                  'Failed to generate ticket');
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  controller.bookingModel.value.status !=
                                          Constant.placed
                                      ? Expanded(
                                          child: Row(
                                            children: [
                                              if (controller.bookingModel.value
                                                      .status ==
                                                  Constant.onGoing)
                                                Expanded(
                                                  child: RoundedButtonFill(
                                                    title: "SOS".tr,
                                                    color:
                                                        AppThemeData.primary300,
                                                    textColor:
                                                        AppThemeData.grey50,
                                                    onPress: () async {
                                                      // ...existing SOS logic below...
                                                      ShowToastDialog
                                                          .showLoader(
                                                              "Please wait".tr);
                                                      loc.LocationData?
                                                          position =
                                                          await Constant
                                                              .getCurrentLocation();
                                                      if (position?.latitude ==
                                                          null) {
                                                        ShowToastDialog
                                                            .closeLoader();
                                                        ShowToastDialog.showToast(
                                                            "Please enable GPS to use the SOS emergency feature."
                                                                .tr);
                                                        return;
                                                      }
                                                      String customerId =
                                                          AuthUtils
                                                              .getCurrentUid();
                                                      await SosUtils.getSOS(
                                                              bookingId: controller
                                                                  .bookingModel
                                                                  .value
                                                                  .id
                                                                  .toString(),
                                                              driverId: controller
                                                                  .bookingModel
                                                                  .value
                                                                  .createdBy!,
                                                              customerId:
                                                                  customerId)
                                                          .then((value) async {
                                                        if (value != null) {
                                                          ShowToastDialog
                                                              .closeLoader();
                                                          ShowToastDialog.showToast(
                                                              "Your SOS request is already submitted."
                                                                  .tr);
                                                        } else {
                                                          SosModel sosModel =
                                                              SosModel();
                                                          sosModel.id = Constant
                                                              .getUuid();
                                                          sosModel.bookingId =
                                                              controller
                                                                  .bookingModel
                                                                  .value
                                                                  .id;
                                                          sosModel.driverId =
                                                              controller
                                                                  .bookingModel
                                                                  .value
                                                                  .createdBy;
                                                          sosModel.customerId =
                                                              customerId;
                                                          sosModel.sosLocation =
                                                              SOSLocation(
                                                                  latitude:
                                                                      position!
                                                                          .latitude!,
                                                                  longitude:
                                                                      position
                                                                          .longitude!);
                                                          sosModel.status =
                                                              "Initiated";
                                                          await SosUtils.setSOS(
                                                              sosModel);
                                                          // Send WhatsApp SOS message to all user's SOS numbers
                                                          final sosNumbers =
                                                              controller
                                                                      .userModel
                                                                      .value
                                                                      .sosWhatsAppNumbers ??
                                                                  [];
                                                          final locationText =
                                                              "https://maps.google.com/?q=${position.latitude},${position.longitude}";
                                                          final passengerName =
                                                              "${controller.userModel.value.firstName ?? ''} ${controller.userModel.value.lastName ?? ''}"
                                                                  .trim();
                                                          final startLocation =
                                                              controller
                                                                      .bookingModel
                                                                      .value
                                                                      .pickUpAddress ??
                                                                  "";
                                                          final endLocation =
                                                              controller
                                                                      .bookingModel
                                                                      .value
                                                                      .dropAddress ??
                                                                  "";
                                                          final rideDate = controller
                                                                      .bookingModel
                                                                      .value
                                                                      .departureDateTime !=
                                                                  null
                                                              ? Constant.timestampToDate(
                                                                  controller
                                                                      .bookingModel
                                                                      .value
                                                                      .departureDateTime!)
                                                              : "";
                                                          final rideTime = controller
                                                                      .bookingModel
                                                                      .value
                                                                      .departureDateTime !=
                                                                  null
                                                              ? Constant.timestampToTime(
                                                                  controller
                                                                      .bookingModel
                                                                      .value
                                                                      .departureDateTime!)
                                                              : "";
                                                          final vehicleNumber = controller
                                                                  .bookingModel
                                                                  .value
                                                                  .vehicleInformation
                                                                  ?.licensePlatNumber ??
                                                              "";
                                                          print(sosNumbers);
                                                          await WhatsAppService
                                                              .sendToMultipleRecipients(
                                                                  phoneNumbers:
                                                                      sosNumbers,
                                                                  templateName:
                                                                      "sos_alerttt",
                                                                  components: [
                                                                {
                                                                  "type":
                                                                      "body",
                                                                  "parameters":
                                                                      [
                                                                    {
                                                                      "type":
                                                                          "text",
                                                                      "text":
                                                                          passengerName
                                                                    },
                                                                    {
                                                                      "type":
                                                                          "text",
                                                                      "text":
                                                                          startLocation
                                                                    },
                                                                    {
                                                                      "type":
                                                                          "text",
                                                                      "text":
                                                                          endLocation
                                                                    },
                                                                    {
                                                                      "type":
                                                                          "text",
                                                                      "text":
                                                                          rideDate
                                                                    },
                                                                    {
                                                                      "type":
                                                                          "text",
                                                                      "text":
                                                                          rideTime
                                                                    },
                                                                    {
                                                                      "type":
                                                                          "text",
                                                                      "text":
                                                                          locationText
                                                                    },
                                                                    {
                                                                      "type":
                                                                          "text",
                                                                      "text":
                                                                          vehicleNumber
                                                                    }
                                                                  ]
                                                                }
                                                              ]);
                                                          print(
                                                              "SOS messages sent to $sosNumbers");
                                                          // Send push notification to driver with custom sound
                                                          final driverFcmToken =
                                                              controller
                                                                  .publisherUserModel
                                                                  .value
                                                                  .fcmToken;
                                                          if (driverFcmToken !=
                                                                  null &&
                                                              driverFcmToken
                                                                  .isNotEmpty) {
                                                            await SendNotification
                                                                .sendChatNotification(
                                                              token:
                                                                  driverFcmToken,
                                                              title:
                                                                  "SOS Alert!",
                                                              body:
                                                                  "Passenger triggered SOS. Tap to respond.",
                                                              payload: {
                                                                "type":
                                                                    "sos_alert",
                                                                "sound":
                                                                    "sos_43210.mp3",
                                                                "bookingId": controller
                                                                        .bookingModel
                                                                        .value
                                                                        .id ??
                                                                    "",
                                                                "location":
                                                                    locationText
                                                              },
                                                            );
                                                          }
                                                          ShowToastDialog
                                                              .closeLoader();
                                                          final Uri launchUri =
                                                              Uri(
                                                                  scheme: 'tel',
                                                                  path: '112');
                                                          if (await canLaunchUrl(
                                                              launchUri)) {
                                                            await launchUrl(
                                                                launchUri);
                                                          } else {
                                                            print(
                                                                'Could not launch dialer');
                                                          }
                                                          // ShowToastDialog.showToast(
                                                          //     "Your SOS request has been submitted to admin, sent to your emergency contacts, and driver alerted."
                                                          //         .tr);
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
                                              if (controller.bookingModel.value
                                                          .status ==
                                                      Constant.onGoing &&
                                                  controller
                                                          .bookingUserModel
                                                          .value
                                                          .paymentStatus ==
                                                      false)
                                                SizedBox(width: 20),
                                              if (controller.bookingUserModel
                                                      .value.paymentStatus ==
                                                  false)
                                                Expanded(
                                                  child: RoundedButtonFill(
                                                    title: "Pay Now".tr,
                                                    color:
                                                        AppThemeData.primary300,
                                                    textColor:
                                                        AppThemeData.grey50,
                                                    onPress: () async {
                                                      // Payment method is already selected, directly process payment
                                                      controller.paymentType
                                                              .value =
                                                          controller
                                                              .bookingUserModel
                                                              .value
                                                              .paymentType
                                                              .toString();
                                                      controller
                                                          .paymentCompleted();
                                                    },
                                                  ),
                                                ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox(),
                                ],
                              ),
                            ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ));
        });
  }

  String _formatSeatLabelsCsv(String? csv) {
    if (csv == null || csv.trim().isEmpty) return '';
    final parts =
        csv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return parts.map((p) {
      final idx = int.tryParse(p) ?? -1;
      return _seatIndexToLabel(idx);
    }).join(',');
  }

  String _seatIndexToLabel(int index) {
    const labels = ['A1', 'A2', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3'];
    if (index >= 0 && index < labels.length) return labels[index];
    return 'S$index';
  }
}
