import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:poolmate/app/chat/model/chat_model.dart';
import 'package:poolmate/app/review/review_screen.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/chat_controller.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/utils/network_image_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<ChatController>(
      init: ChatController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.getThem()
              ? AppThemeData.grey800
              : AppThemeData.grey100,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: themeChange.getThem()
                ? AppThemeData.grey900
                : AppThemeData.grey50,
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
            titleSpacing: 0,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: NetworkImageWidget(
                    imageUrl: controller.receiverUserModel.value.profilePic
                        .toString(),
                    height: Responsive.width(10, context),
                    width: Responsive.width(10, context),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.receiverUserModel.value.fullName().toString(),
                      style: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey100
                              : AppThemeData.grey800,
                          fontFamily: AppThemeData.semiBold,
                          fontSize: 14),
                    ),
                    Text(
                      controller.receiverUserModel.value.email.toString(),
                      style: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey100
                              : AppThemeData.grey800,
                          fontFamily: AppThemeData.medium,
                          fontSize: 12),
                    )
                  ],
                )
              ],
            ),
          ),
          body: SafeArea(
            child: controller.isLoading.value
                ? Center(child: Constant.loader())
                : Column(
                    children: [
                      Expanded(
                        child: PaginateFirestore(
                          scrollDirection: Axis.vertical,
                          query: FirebaseFirestore.instance
                              .collection(CollectionName.chat)
                              .doc(controller.senderUserModel.value.id)
                              .collection(controller.receiverUserModel.value.id
                                  .toString())
                              .orderBy("timestamp", descending: true),
                          itemBuilderType: PaginateBuilderType.listView,
                          isLive: true,
                          physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          shrinkWrap: true,
                          reverse: true,
                          onEmpty: Constant.showEmptyView(
                              message: "No conversion found".tr,
                              isDarkMode: themeChange.getThem()),
                          onError: (error) {
                            return ErrorWidget(error);
                          },
                          itemBuilder: (context, documentSnapshots, index) {
                            ChatModel chatModel = ChatModel.fromJson(
                                documentSnapshots[index].data()
                                    as Map<String, dynamic>);
                            return Container(
                                padding: const EdgeInsets.only(
                                    left: 14, right: 14, top: 06, bottom: 06),
                                child: chatBubbles(
                                    context,
                                    chatModel.senderId ==
                                            controller.senderUserModel.value.id
                                        ? true
                                        : false,
                                    chatModel,
                                    themeChange));
                          },
                        ),
                      ),
                      Container(
                        color: themeChange.getThem()
                            ? AppThemeData.grey900
                            : AppThemeData.grey50,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  keyboardType: TextInputType.text,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  controller: controller
                                      .messageTextEditorController.value,
                                  textAlign: TextAlign.start,
                                  maxLines: 1,
                                  textInputAction: TextInputAction.done,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey300
                                          : AppThemeData.grey600,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppThemeData.medium),
                                  decoration: InputDecoration(
                                      errorStyle:
                                          const TextStyle(color: Colors.red),
                                      isDense: true,
                                      filled: true,
                                      enabled: true,
                                      fillColor: themeChange.getThem()
                                          ? AppThemeData.grey800
                                          : AppThemeData.grey100,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16, horizontal: 10),
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
                                      hintText: "Type Message".tr,
                                      hintStyle: TextStyle(
                                          fontSize: 14,
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey600
                                              : AppThemeData.grey700,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppThemeData.medium)),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              InkWell(
                                  onTap: () {
                                    _showLocationDurationBottomSheet(
                                        context, controller, themeChange);
                                  },
                                  child: Obx(() => Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: controller.isSharingLiveLocation.value
                                            ? AppThemeData.primary300
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        controller.isSharingLiveLocation.value
                                            ? Icons.location_on
                                            : Icons.location_on_outlined,
                                        color: controller.isSharingLiveLocation.value
                                            ? Colors.white
                                            : AppThemeData.primary300,
                                        size: 26,
                                      )))),
                              const SizedBox(
                                width: 10,
                              ),
                              InkWell(
                                  onTap: () {
                                    if (controller.messageTextEditorController
                                        .value.text.isNotEmpty) {
                                      controller.sendMessage(controller
                                          .messageTextEditorController
                                          .value
                                          .text
                                          .trim());
                                    } else {
                                      ShowToastDialog.showToast(
                                          "Please enter message".tr);
                                    }
                                  },
                                  child: SvgPicture.asset(
                                      "assets/icons/ic_chat_send.svg"))
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _showLocationDurationBottomSheet(BuildContext context,
      ChatController controller, DarkThemeProvider themeChange) {
    if (controller.isSharingLiveLocation.value) {
      // If already sharing, just ask to stop
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Stop Sharing Location".tr),
              content:
                  Text("Do you want to stop sharing your live location?".tr),
              actions: [
                TextButton(
                    onPressed: () => Get.back(), child: Text("Cancel".tr)),
                TextButton(
                    onPressed: () {
                      controller.stopLiveLocationSharing();
                      Get.back();
                    },
                    child: Text(
                      "Stop".tr,
                      style: const TextStyle(color: Colors.red),
                    )),
              ],
            );
          });
      return;
    }


    showModalBottomSheet(
        context: context,
        backgroundColor:
            themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey50,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Share Live Location".tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: AppThemeData.bold,
                    color: themeChange.getThem()
                        ? AppThemeData.grey100
                        : AppThemeData.grey900,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.touch_app_outlined,
                      color: AppThemeData.primary300),
                  title: Text("Until manually stopped",
                      style: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey100
                              : AppThemeData.grey900)),
                  onTap: () {
                    Get.back();
                    controller.startLiveLocationSharing(2);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.directions_car_outlined,
                      color: AppThemeData.primary300),
                  title: Text("During ride",
                      style: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey100
                              : AppThemeData.grey900)),
                  onTap: () {
                    Get.back();
                    controller.startLiveLocationSharing(3);
                  },
                ),
              ],
            ),
          );
        });
  }

  chatBubbles(
      BuildContext context, bool isMe, ChatModel chatModel, themeChange) {
    if (chatModel.type == "live_location") {
      return _buildLocationBubble(context, isMe, chatModel, themeChange);
    }
    if (chatModel.type == "ride_location") {
      return _buildRideLocationBubble(context, isMe, chatModel, themeChange);
    }
    return isMe
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                            bottomLeft: Radius.circular(10)),
                        color: AppThemeData.primary300,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Text(
                          chatModel.message.toString(),
                          style: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey900
                                  : AppThemeData.grey50,
                              fontFamily: AppThemeData.regular,
                              fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      chatModel.timestamp != null
                          ? Constant.timestampToDateTime(chatModel.timestamp!)
                          : 'Unknown time',
                      style: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey300
                              : AppThemeData.grey600,
                          fontFamily: AppThemeData.regular,
                          fontSize: 12),
                    )
                  ],
                ),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10)),
                        color: AppThemeData.grey200,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chatModel.message.toString(),
                              style: TextStyle(
                                  color: themeChange.getThem()
                                      ? AppThemeData.grey100
                                      : AppThemeData.grey800,
                                  fontFamily: AppThemeData.regular,
                                  fontSize: 14),
                            ),
                            // Show Review button for ride_cancelled messages
                            if (chatModel.type == 'ride_cancelled')
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: RoundedButtonFill(
                                  title: "Review Publisher".tr,
                                  width: 35,
                                  height: 4,
                                  color: AppThemeData.primary300,
                                  textColor: AppThemeData.grey50,
                                  onPress: () async {
                                    // Get controller to access sender and receiver info
                                    final controller =
                                        Get.find<ChatController>();

                                    // Get booking ID from metadata
                                    String? bookingId =
                                        chatModel.metadata?['bookingId'];

                                    if (bookingId == null) {
                                      ShowToastDialog.showToast(
                                          "Booking information not available"
                                              .tr);
                                      return;
                                    }

                                    // Show loading
                                    ShowToastDialog.showLoader(
                                        "Please wait".tr);

                                    // Fetch the booking model
                                    try {
                                      final bookingDoc = await FirebaseFirestore
                                          .instance
                                          .collection('booking')
                                          .doc(bookingId)
                                          .get();

                                      ShowToastDialog.closeLoader();

                                      if (!bookingDoc.exists) {
                                        ShowToastDialog.showToast(
                                            "Booking not found".tr);
                                        return;
                                      }

                                      final bookingData = bookingDoc.data();
                                      if (bookingData == null) {
                                        ShowToastDialog.showToast(
                                            "Booking data not available".tr);
                                        return;
                                      }

                                      // Convert to BookingModel
                                      BookingModel bookingModel =
                                          BookingModel.fromJson(bookingData);

                                      // Navigate to review screen with all required data
                                      Get.to(() => const ReviewScreen(),
                                          arguments: {
                                            "bookingModel": bookingModel,
                                            "senderUserModel": controller
                                                .senderUserModel.value,
                                            "reciverUserModel": controller
                                                .receiverUserModel.value,
                                          });
                                    } catch (e) {
                                      ShowToastDialog.closeLoader();
                                      ShowToastDialog.showToast(
                                          "Error loading booking: $e".tr);
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      chatModel.timestamp != null
                          ? Constant.timestampToDateTime(chatModel.timestamp!)
                          : 'Unknown time',
                      style: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey300
                              : AppThemeData.grey600,
                          fontFamily: AppThemeData.regular,
                          fontSize: 12),
                    )
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildLocationBubble(BuildContext context, bool isMe,
      ChatModel chatModel, DarkThemeProvider themeChange) {
    bool isActive = chatModel.metadata?['isActive'] ?? false;
    double lat = chatModel.metadata?['lat'] ?? 0.0;
    double lng = chatModel.metadata?['lng'] ?? 0.0;

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color:
                      isActive ? AppThemeData.primary300 : AppThemeData.grey300,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    if (lat != 0.0 && lng != 0.0)
                      LiveAutoUpdatingMap(
                        currentLat: lat,
                        currentLng: lng,
                        zoom: 15,
                        markers: {
                          Marker(
                            markerId: const MarkerId('live_location'),
                            position: LatLng(lat, lng),
                          )
                        },
                      ),
                    if (lat == 0.0)
                      const Center(child: CircularProgressIndicator()),
                    if (!isActive)
                      Container(
                        color: Colors.black45,
                        child: Center(
                          child: Text(
                            "Live Location Ended".tr,
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: AppThemeData.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    if (isActive)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 10),
                              SizedBox(width: 4),
                              Text("LIVE",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                chatModel.timestamp != null
                    ? Constant.timestampToDateTime(chatModel.timestamp!)
                    : 'Unknown time',
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey300
                        : AppThemeData.grey600,
                    fontFamily: AppThemeData.regular,
                    fontSize: 12),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideLocationBubble(BuildContext context, bool isMe,
      ChatModel chatModel, DarkThemeProvider themeChange) {
    final meta = chatModel.metadata ?? {};

    final String startAddress = meta['startAddress'] ?? '';
    final double startLat = (meta['startLat'] ?? 0.0).toDouble();
    final double startLng = (meta['startLng'] ?? 0.0).toDouble();

    final String endAddress = meta['endAddress'] ?? '';
    final double endLat = (meta['endLat'] ?? 0.0).toDouble();
    final double endLng = (meta['endLng'] ?? 0.0).toDouble();

    final double currentLat = (meta['currentLat'] ?? 0.0).toDouble();
    final double currentLng = (meta['currentLng'] ?? 0.0).toDouble();

    final String senderName = meta['senderName'] ?? 'Someone';
    final String bookingId = (meta['bookingId'] ?? '').toString();
    final String updatedAt = chatModel.timestamp != null
        ? Constant.timestampToDateTime(chatModel.timestamp!)
        : 'Unknown time';

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.78,
                decoration: BoxDecoration(
                  color: themeChange.getThem()
                      ? AppThemeData.grey800
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: themeChange.getThem()
                        ? AppThemeData.grey700
                        : AppThemeData.grey200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppThemeData.primary300.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car,
                              color: AppThemeData.primary300, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isMe
                                  ? 'You shared a ride'.tr
                                  : '$senderName shared a ride',
                              style: TextStyle(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey100
                                    : AppThemeData.grey900,
                                fontFamily: AppThemeData.semiBold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Route Info
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          // Start
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.radio_button_checked,
                                  color: Colors.orange, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('PICKUP'.tr,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey400
                                                : AppThemeData.grey500,
                                            fontFamily: AppThemeData.bold)),
                                    Text(
                                        startAddress.isEmpty
                                            ? 'Unknown'.tr
                                            : startAddress,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey100
                                                : AppThemeData.grey900,
                                            fontFamily: AppThemeData.medium),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Connecting line
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 7, top: 4, bottom: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                  width: 2,
                                  height: 16,
                                  color: themeChange.getThem()
                                      ? AppThemeData.grey700
                                      : AppThemeData.grey300),
                            ),
                          ),
                          // Dropoff
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.green, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('DROPOFF'.tr,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey400
                                                : AppThemeData.grey500,
                                            fontFamily: AppThemeData.bold)),
                                    Text(
                                        endAddress.isEmpty
                                            ? 'Unknown'.tr
                                            : endAddress,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey100
                                                : AppThemeData.grey900,
                                            fontFamily: AppThemeData.medium),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Divider(
                        height: 1,
                        color: themeChange.getThem()
                            ? AppThemeData.grey700
                            : AppThemeData.grey200),

                    // View Map Button
                    InkWell(
                      onTap: () {
                        _showRideRouteDetailsSheet(
                          context: context,
                          themeChange: themeChange,
                          senderName: senderName,
                          startAddress: startAddress,
                          startLat: startLat,
                          startLng: startLng,
                          currentLat: currentLat,
                          currentLng: currentLng,
                          endAddress: endAddress,
                          endLat: endLat,
                          endLng: endLng,
                          updatedAt: updatedAt,
                          bookingId: bookingId,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined,
                                size: 18, color: AppThemeData.primary300),
                            const SizedBox(width: 8),
                            Text('View Live Map'.tr,
                                style: TextStyle(
                                    color: AppThemeData.primary300,
                                    fontFamily: AppThemeData.semiBold,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),

                    // Stop sharing button (only if isMe and currently sharing this specific ride)
                    if (isMe && meta['isActive'] == true)
                      Column(
                        children: [
                          Divider(
                              height: 1,
                              color: themeChange.getThem()
                                  ? AppThemeData.grey700
                                  : AppThemeData.grey200),
                          InkWell(
                            onTap: () {
                              final controller = Get.find<ChatController>();
                              controller.stopLiveLocationSharing();
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.05),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.stop_circle_outlined,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text('Stop Sharing'.tr,
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontFamily: AppThemeData.semiBold,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                updatedAt,
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey300
                        : AppThemeData.grey600,
                    fontFamily: AppThemeData.regular,
                    fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isValidCoordinate(double lat, double lng) {
    return lat != 0.0 && lng != 0.0;
  }

  List<LatLng> _buildRoutePoints({
    required double startLat,
    required double startLng,
    required double currentLat,
    required double currentLng,
    required double endLat,
    required double endLng,
  }) {
    final List<LatLng> points = [];
    if (_isValidCoordinate(startLat, startLng)) {
      points.add(LatLng(startLat, startLng));
    }
    if (_isValidCoordinate(currentLat, currentLng)) {
      points.add(LatLng(currentLat, currentLng));
    }
    if (_isValidCoordinate(endLat, endLng)) {
      points.add(LatLng(endLat, endLng));
    }
    return points;
  }

  double _calculateRouteDistanceKm(List<LatLng> points) {
    if (points.length < 2) return 0;
    double meters = 0;
    for (int i = 0; i < points.length - 1; i++) {
      meters += Geolocator.distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return meters / 1000;
  }

  Future<void> _openFullRouteInMaps({
    required double startLat,
    required double startLng,
    required double currentLat,
    required double currentLng,
    required double endLat,
    required double endLng,
  }) async {
    final bool hasStart = _isValidCoordinate(startLat, startLng);
    final bool hasCurrent = _isValidCoordinate(currentLat, currentLng);
    final bool hasEnd = _isValidCoordinate(endLat, endLng);

    Uri uri;

    if (hasStart && hasEnd) {
      final query = <String, String>{
        'api': '1',
        'origin': '$startLat,$startLng',
        'destination': '$endLat,$endLng',
        'travelmode': 'driving',
      };
      if (hasCurrent) {
        query['waypoints'] = '$currentLat,$currentLng';
      }
      uri = Uri.https('www.google.com', '/maps/dir/', query);
    } else if (hasCurrent) {
      uri = Uri.parse('https://maps.google.com/?q=$currentLat,$currentLng');
    } else if (hasEnd) {
      uri = Uri.parse('https://maps.google.com/?q=$endLat,$endLng');
    } else if (hasStart) {
      uri = Uri.parse('https://maps.google.com/?q=$startLat,$startLng');
    } else {
      ShowToastDialog.showToast('No route location available'.tr);
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    ShowToastDialog.showToast('Could not open maps'.tr);
  }

  void _showRideRouteDetailsSheet({
    required BuildContext context,
    required DarkThemeProvider themeChange,
    required String senderName,
    required String startAddress,
    required double startLat,
    required double startLng,
    required double currentLat,
    required double currentLng,
    required String endAddress,
    required double endLat,
    required double endLng,
    required String updatedAt,
    required String bookingId,
  }) {
    final bool hasCurrent = _isValidCoordinate(currentLat, currentLng);
    final List<LatLng> routePoints = _buildRoutePoints(
      startLat: startLat,
      startLng: startLng,
      currentLat: currentLat,
      currentLng: currentLng,
      endLat: endLat,
      endLng: endLng,
    );
    final double approxDistanceKm = _calculateRouteDistanceKm(routePoints);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.74,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: themeChange.getThem()
                    ? AppThemeData.grey900
                    : AppThemeData.grey50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    height: 4,
                    width: 46,
                    decoration: BoxDecoration(
                      color: themeChange.getThem()
                          ? AppThemeData.grey600
                          : AppThemeData.grey300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      children: [
                        Text(
                          'Full route details'.tr,
                          style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey100
                                : AppThemeData.grey900,
                            fontFamily: AppThemeData.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$senderName shared this route',
                          style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey300
                                : AppThemeData.grey700,
                            fontFamily: AppThemeData.medium,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _detailChip(
                              themeChange: themeChange,
                              icon: Icons.route,
                              label: approxDistanceKm > 0
                                  ? 'Approx ${approxDistanceKm.toStringAsFixed(1)} km'
                                  : 'Route distance unavailable'.tr,
                            ),
                            _detailChip(
                              themeChange: themeChange,
                              icon: Icons.schedule,
                              label: updatedAt,
                            ),
                            if (bookingId.isNotEmpty)
                              _detailChip(
                                themeChange: themeChange,
                                icon: Icons.confirmation_number_outlined,
                                label:
                                    'Ride #${Constant.orderIdwithoutHash(orderId: bookingId)}',
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (routePoints.isNotEmpty)
                          SizedBox(
                            height: 270,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: routePoints[routePoints.length ~/ 2],
                                  zoom: 11.5,
                                ),
                                markers: {
                                  if (_isValidCoordinate(startLat, startLng))
                                    Marker(
                                      markerId:
                                          const MarkerId('route_start_full'),
                                      position: LatLng(startLat, startLng),
                                      icon:
                                          BitmapDescriptor.defaultMarkerWithHue(
                                              BitmapDescriptor.hueOrange),
                                      infoWindow:
                                          const InfoWindow(title: 'Start'),
                                    ),
                                  if (_isValidCoordinate(
                                      currentLat, currentLng))
                                    Marker(
                                      markerId:
                                          const MarkerId('route_current_full'),
                                      position: LatLng(currentLat, currentLng),
                                      icon:
                                          BitmapDescriptor.defaultMarkerWithHue(
                                              BitmapDescriptor.hueAzure),
                                      infoWindow:
                                          const InfoWindow(title: 'Current'),
                                    ),
                                  if (_isValidCoordinate(endLat, endLng))
                                    Marker(
                                      markerId:
                                          const MarkerId('route_end_full'),
                                      position: LatLng(endLat, endLng),
                                      icon:
                                          BitmapDescriptor.defaultMarkerWithHue(
                                              BitmapDescriptor.hueGreen),
                                      infoWindow:
                                          const InfoWindow(title: 'End'),
                                    ),
                                },
                                polylines: routePoints.length >= 2
                                    ? {
                                        Polyline(
                                          polylineId: const PolylineId(
                                              'full_route_line'),
                                          points: routePoints,
                                          width: 5,
                                          color: AppThemeData.primary300,
                                          geodesic: true,
                                        ),
                                      }
                                    : {},
                                zoomControlsEnabled: false,
                                myLocationButtonEnabled: false,
                                mapToolbarEnabled: true,
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey800
                                  : AppThemeData.grey100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'Route preview is unavailable'.tr,
                                style: TextStyle(
                                  color: themeChange.getThem()
                                      ? AppThemeData.grey300
                                      : AppThemeData.grey700,
                                  fontFamily: AppThemeData.medium,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        _routePointTile(
                          themeChange: themeChange,
                          icon: Icons.trip_origin,
                          iconColor: Colors.orange,
                          title: 'START'.tr,
                          subtitle: startAddress.isEmpty
                              ? 'Unknown'.tr
                              : startAddress,
                          coords: _isValidCoordinate(startLat, startLng)
                              ? '$startLat, $startLng'
                              : null,
                        ),
                        if (hasCurrent)
                          _routePointTile(
                            themeChange: themeChange,
                            icon: Icons.my_location,
                            iconColor: Colors.lightBlueAccent,
                            title: 'CURRENT LOCATION'.tr,
                            subtitle:
                                '${currentLat.toStringAsFixed(6)}, ${currentLng.toStringAsFixed(6)}',
                            coords: '$currentLat, $currentLng',
                          ),
                        _routePointTile(
                          themeChange: themeChange,
                          icon: Icons.location_on,
                          iconColor: Colors.green,
                          title: 'END'.tr,
                          subtitle:
                              endAddress.isEmpty ? 'Unknown'.tr : endAddress,
                          coords: _isValidCoordinate(endLat, endLng)
                              ? '$endLat, $endLng'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _openFullRouteInMaps(
                              startLat: startLat,
                              startLng: startLng,
                              currentLat: currentLat,
                              currentLng: currentLng,
                              endLat: endLat,
                              endLng: endLng,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemeData.primary300,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.map_outlined),
                            label: Text(
                              'Open full route in maps'.tr,
                              style: const TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailChip({
    required DarkThemeProvider themeChange,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:
            themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppThemeData.primary300),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: themeChange.getThem()
                  ? AppThemeData.grey200
                  : AppThemeData.grey800,
              fontFamily: AppThemeData.medium,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _routePointTile({
    required DarkThemeProvider themeChange,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? coords,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey300
                        : AppThemeData.grey700,
                    fontFamily: AppThemeData.medium,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey100
                        : AppThemeData.grey900,
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 14,
                  ),
                ),
                if (coords != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    coords,
                    style: TextStyle(
                      color: themeChange.getThem()
                          ? AppThemeData.grey400
                          : AppThemeData.grey600,
                      fontFamily: AppThemeData.regular,
                      fontSize: 12,
                    ),
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LiveAutoUpdatingMap extends StatefulWidget {
  final double currentLat;
  final double currentLng;
  final double zoom;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const LiveAutoUpdatingMap({
    Key? key,
    required this.currentLat,
    required this.currentLng,
    this.zoom = 14,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
  }) : super(key: key);

  @override
  State<LiveAutoUpdatingMap> createState() => _LiveAutoUpdatingMapState();
}

class _LiveAutoUpdatingMapState extends State<LiveAutoUpdatingMap> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant LiveAutoUpdatingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLat != widget.currentLat ||
        oldWidget.currentLng != widget.currentLng) {
      _controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(widget.currentLat, widget.currentLng)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.currentLat, widget.currentLng),
        zoom: widget.zoom,
      ),
      markers: widget.markers,
      polylines: widget.polylines,
      zoomControlsEnabled: false,
      scrollGesturesEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _controller = controller;
      },
    );
  }
}
