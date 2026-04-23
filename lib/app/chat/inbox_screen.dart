import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/chat/chat_screen.dart';
import 'package:poolmate/app/chat/model/inbox_model.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/chat_controller.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/inbox_controller.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/utils/network_image_widget.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({
    super.key,
    this.shareRideLocation = false,
    this.bookingModel,
  });

  final bool shareRideLocation;
  final BookingModel? bookingModel;

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<InboxController>(
      init: InboxController(),
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
            automaticallyImplyLeading: shareRideLocation,
            leading: shareRideLocation
                ? IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  )
                : null,
            title: Text(
              shareRideLocation ? "Select Contact".tr : "Inbox".tr,
              style: TextStyle(
                  color: themeChange.getThem()
                      ? AppThemeData.grey100
                      : AppThemeData.grey800,
                  fontFamily: AppThemeData.bold,
                  fontSize: 18),
            ),
            actions: shareRideLocation
                ? [
                    TextButton(
                      onPressed: controller.selectedShareUserIds.isEmpty
                          ? null
                          : controller.clearShareSelection,
                      child: Text(
                        "Clear".tr,
                        style: TextStyle(
                          color: controller.selectedShareUserIds.isEmpty
                              ? (themeChange.getThem()
                                  ? AppThemeData.grey500
                                  : AppThemeData.grey400)
                              : AppThemeData.primary300,
                          fontFamily: AppThemeData.medium,
                        ),
                      ),
                    ),
                  ]
                : null,
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
          bottomNavigationBar: shareRideLocation
              ? SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: themeChange.getThem()
                          ? AppThemeData.grey900
                          : AppThemeData.grey50,
                      border: Border(
                        top: BorderSide(
                          color: themeChange.getThem()
                              ? AppThemeData.grey700
                              : AppThemeData.grey200,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: controller.selectedShareUserIds.isEmpty
                            ? null
                            : () => _sendRideLocationToSelectedContact(
                                  controller: controller,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeData.primary300,
                          disabledBackgroundColor: themeChange.getThem()
                              ? AppThemeData.grey700
                              : AppThemeData.grey300,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          "Send (${controller.selectedShareUserIds.length})".tr,
                          style: const TextStyle(
                            fontFamily: AppThemeData.semiBold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          body: SafeArea(
            child: controller.isLoading.value
                ? Center(child: Constant.loader())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                        child: TextField(
                          controller: controller.searchController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.search,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+ -]')),
                          ],
                          onChanged: controller.onSearchChanged,
                          decoration: InputDecoration(
                            hintText: "Search by mobile number".tr,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: controller.searchText.value.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      controller.searchController.clear();
                                      controller.onSearchChanged('');
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                            filled: true,
                            fillColor: themeChange.getThem()
                                ? AppThemeData.grey900
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey700
                                    : AppThemeData.grey200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey700
                                    : AppThemeData.grey200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: AppThemeData.primary300, width: 1.2),
                            ),
                          ),
                        ),
                      ),
                      if (shareRideLocation)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey900
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey700
                                    : AppThemeData.grey200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: AppThemeData.primary300,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    controller.selectedShareUserIds.isEmpty
                                        ? "Select contacts, then tap Send".tr
                                        : "${controller.selectedShareUserIds.length} contact(s) selected"
                                            .tr,
                                    style: TextStyle(
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey200
                                          : AppThemeData.grey700,
                                      fontSize: 13,
                                      fontFamily: AppThemeData.medium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        child: controller.searchText.value.trim().isNotEmpty
                            ? _buildSearchResults(
                                controller, themeChange, context)
                            : PaginateFirestore(
                                scrollDirection: Axis.vertical,
                                query: FirebaseFirestore.instance
                                    .collection(CollectionName.chat)
                                    .doc(controller.senderUserModel.value.id)
                                    .collection("inbox")
                                    .orderBy("timestamp", descending: true),
                                itemBuilderType: PaginateBuilderType.listView,
                                isLive: true,
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                shrinkWrap: true,
                                onEmpty: Constant.showEmptyView(
                                    message: "No conversion found".tr,
                                    isDarkMode: themeChange.getThem()),
                                onError: (error) {
                                  return ErrorWidget(error);
                                },
                                itemBuilder:
                                    (context, documentSnapshots, index) {
                                  InboxModel inboxModel = InboxModel.fromJson(
                                      documentSnapshots[index].data()
                                          as Map<String, dynamic>);
                                  final receiverId =
                                      controller.senderUserModel.value.id ==
                                              inboxModel.senderId.toString()
                                          ? inboxModel.receiverId.toString()
                                          : inboxModel.senderId.toString();
                                  final isSelected = shareRideLocation &&
                                      controller.isShareSelected(receiverId);
                                  return Container(
                                      key: ValueKey('inbox_$receiverId'),
                                      padding: const EdgeInsets.only(
                                          left: 14,
                                          right: 14,
                                          top: 06,
                                          bottom: 06),
                                      child: InkWell(
                                        onTap: () async {
                                          if (shareRideLocation) {
                                            controller.toggleShareSelection(
                                                receiverId);
                                          } else {
                                            await _handleUserSelection(
                                              controller: controller,
                                              receiverId: receiverId,
                                            );
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 5),
                                          child: FutureBuilder<UserModel?>(
                                              future: controller
                                                  .getUserProfileFuture(
                                                      receiverId),
                                              builder: (context, snapshot) {
                                                switch (
                                                    snapshot.connectionState) {
                                                  case ConnectionState.waiting:
                                                    return _buildInboxLoadingTile(
                                                      themeChange,
                                                      inboxModel,
                                                      isSelected,
                                                    );
                                                  case ConnectionState.done:
                                                    if (snapshot.hasError) {
                                                      return Text(snapshot.error
                                                          .toString());
                                                    } else if (snapshot.data ==
                                                        null) {
                                                      return Row(
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        60),
                                                            child:
                                                                NetworkImageWidget(
                                                              imageUrl: "",
                                                              height: Responsive
                                                                  .width(12,
                                                                      context),
                                                              width: Responsive
                                                                  .width(12,
                                                                      context),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          Text(
                                                                        "User Deleted",
                                                                        style: TextStyle(
                                                                            color: themeChange.getThem()
                                                                                ? AppThemeData.grey100
                                                                                : AppThemeData.grey800,
                                                                            fontFamily: AppThemeData.bold,
                                                                            fontSize: 16),
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      Constant.timestampToDateChat(
                                                                          inboxModel
                                                                              .timestamp!),
                                                                      style: TextStyle(
                                                                          color: themeChange.getThem()
                                                                              ? AppThemeData
                                                                                  .grey100
                                                                              : AppThemeData
                                                                                  .grey800,
                                                                          fontFamily: AppThemeData
                                                                              .regular,
                                                                          fontSize:
                                                                              12),
                                                                    )
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    } else {
                                                      UserModel? userModel =
                                                          snapshot.data;
                                                      return AnimatedContainer(
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    140),
                                                        curve: Curves.easeOut,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isSelected
                                                              ? AppThemeData
                                                                  .primary300
                                                                  .withOpacity(
                                                                      0.10)
                                                              : Colors
                                                                  .transparent,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? AppThemeData
                                                                    .primary300
                                                                : Colors
                                                                    .transparent,
                                                            width: 1,
                                                          ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 6),
                                                        child: Row(
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          60),
                                                              child:
                                                                  NetworkImageWidget(
                                                                imageUrl: userModel!
                                                                    .profilePic
                                                                    .toString(),
                                                                height: Responsive
                                                                    .width(12,
                                                                        context),
                                                                width: Responsive
                                                                    .width(12,
                                                                        context),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child:
                                                                            Text(
                                                                          userModel
                                                                              .fullName()
                                                                              .toString(),
                                                                          style: TextStyle(
                                                                              color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
                                                                              fontFamily: AppThemeData.bold,
                                                                              fontSize: 16),
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        Constant.timestampToDateChat(
                                                                            inboxModel.timestamp!),
                                                                        style: TextStyle(
                                                                            color: themeChange.getThem()
                                                                                ? AppThemeData.grey100
                                                                                : AppThemeData.grey800,
                                                                            fontFamily: AppThemeData.regular,
                                                                            fontSize: 12),
                                                                      )
                                                                    ],
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child:
                                                                            Text(
                                                                          userModel
                                                                              .email
                                                                              .toString(),
                                                                          style: TextStyle(
                                                                              color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
                                                                              fontFamily: AppThemeData.medium,
                                                                              fontSize: 14),
                                                                        ),
                                                                      ),
                                                                      if (!shareRideLocation)
                                                                        inboxModel.seen == true ||
                                                                                (inboxModel.unreadCount ?? 0) == 0
                                                                            ? const SizedBox()
                                                                            : SizedBox(
                                                                                width: 20,
                                                                                height: 20,
                                                                                child: ClipOval(
                                                                                  child: Container(
                                                                                    decoration: BoxDecoration(color: AppThemeData.primary300),
                                                                                    child: Center(
                                                                                      child: Text(
                                                                                        '${inboxModel.unreadCount ?? 0}',
                                                                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                      if (shareRideLocation)
                                                                        Checkbox(
                                                                          value:
                                                                              isSelected,
                                                                          activeColor:
                                                                              AppThemeData.primary300,
                                                                          shape:
                                                                              RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(5),
                                                                          ),
                                                                          onChanged:
                                                                              (_) {
                                                                            controller.toggleShareSelection(receiverId);
                                                                          },
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }
                                                  default:
                                                    return Text('Error'.tr);
                                                }
                                              }),
                                        ),
                                      ));
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(InboxController controller,
      DarkThemeProvider themeChange, BuildContext context) {
    final hasDigitInput =
        controller.searchText.value.replaceAll(RegExp(r'[^0-9]'), '').length >=
            3;

    if (!hasDigitInput) {
      return Center(
        child: Text(
          "Type at least 3 digits to search".tr,
          style: TextStyle(
            color: themeChange.getThem()
                ? AppThemeData.grey300
                : AppThemeData.grey600,
            fontFamily: AppThemeData.medium,
          ),
        ),
      );
    }

    if (controller.isSearching.value) {
      return Center(child: Constant.loader());
    }

    if (controller.searchResults.isEmpty) {
      return Constant.showEmptyView(
          message: "No users found with this number".tr,
          isDarkMode: themeChange.getThem());
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      itemCount: controller.searchResults.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color:
            themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200,
      ),
      itemBuilder: (context, index) {
        final user = controller.searchResults[index];
        final isSelected = shareRideLocation &&
            controller.isShareSelected(user.id?.toString());
        return InkWell(
          onTap: () {
            if (shareRideLocation) {
              controller.toggleShareSelection(user.id?.toString());
            } else {
              _handleUserSelection(
                controller: controller,
                selectedUser: user,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppThemeData.primary300.withOpacity(0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? AppThemeData.primary300 : Colors.transparent,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: NetworkImageWidget(
                      imageUrl: user.profilePic.toString(),
                      height: Responsive.width(12, context),
                      width: Responsive.width(12, context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName().toString().trim().isEmpty
                              ? "Unknown User".tr
                              : user.fullName().toString(),
                          style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey100
                                : AppThemeData.grey800,
                            fontFamily: AppThemeData.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user.countryCode ?? ''} ${user.phoneNumber ?? ''}'
                              .trim(),
                          style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey300
                                : AppThemeData.grey600,
                            fontFamily: AppThemeData.medium,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!shareRideLocation)
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: themeChange.getThem()
                          ? AppThemeData.grey300
                          : AppThemeData.grey700,
                    ),
                  if (shareRideLocation)
                    Checkbox(
                      value: isSelected,
                      activeColor: AppThemeData.primary300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: (_) {
                        controller.toggleShareSelection(user.id?.toString());
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInboxLoadingTile(
    DarkThemeProvider themeChange,
    InboxModel inboxModel,
    bool isSelected,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? AppThemeData.primary300.withOpacity(0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppThemeData.primary300 : Colors.transparent,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: themeChange.getThem()
                  ? AppThemeData.grey700
                  : AppThemeData.grey200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: themeChange.getThem()
                              ? AppThemeData.grey700
                              : AppThemeData.grey200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Constant.timestampToDateChat(inboxModel.timestamp!),
                      style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey300
                            : AppThemeData.grey600,
                        fontFamily: AppThemeData.regular,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 140,
                  decoration: BoxDecoration(
                    color: themeChange.getThem()
                        ? AppThemeData.grey700
                        : AppThemeData.grey200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUserSelection({
    required InboxController controller,
    UserModel? selectedUser,
    String? receiverId,
  }) async {
    try {
      UserModel? receiverUser = selectedUser;

      if (receiverUser == null && receiverId != null) {
        ShowToastDialog.showLoader("Please wait".tr);
        receiverUser = await controller.getUserProfileFuture(receiverId);
        ShowToastDialog.closeLoader();
      }

      if (receiverUser == null) {
        ShowToastDialog.showToast(
            "User deleted. you are not able to see chat".tr);
        return;
      }

      if (shareRideLocation) {
        controller.toggleShareSelection(receiverUser.id?.toString());
        return;
      }

      Get.to(const ChatScreen(), arguments: {"receiverModel": receiverUser});
    } catch (e) {
      ShowToastDialog.closeLoader();
      if (shareRideLocation) {
        ShowToastDialog.showToast("Failed to share location: $e".tr);
      } else {
        ShowToastDialog.showToast("Unable to open chat".tr);
      }
    }
  }

  Future<void> _sendRideLocationToSelectedContact({
    required InboxController controller,
  }) async {
    final selectedIds = controller.selectedShareUserIds.toList();
    if (selectedIds.isEmpty) {
      ShowToastDialog.showToast("Please select at least one contact".tr);
      return;
    }

    if (bookingModel == null) {
      ShowToastDialog.showToast("Ride details not found".tr);
      return;
    }

    if (controller.senderUserModel.value.id == null) {
      ShowToastDialog.showToast("Could not load your profile".tr);
      return;
    }

    try {
      bool hasPermission = await ChatController.requestBackgroundLocationPermissions();
      if (!hasPermission) return;

      ShowToastDialog.showLoader("Sending...".tr);

      // Start the background service so it is ready before we invoke startSharing
      await FlutterBackgroundService().startService();
      await Future.delayed(const Duration(milliseconds: 2500));

      int successCount = 0;
      int failedCount = 0;

      for (final selectedId in selectedIds) {
        final receiverUser = await controller.getUserProfileFuture(selectedId);

        if (receiverUser == null) {
          failedCount++;
          continue;
        }

        try {
          await ChatController.sendRideLocationCard(
            senderUser: controller.senderUserModel.value,
            receiverUser: receiverUser,
            bookingModel: bookingModel!,
            showLoader: false,
            showSuccessToast: false,
            startContinuousSharing: true,
          );
          successCount++;
        } catch (_) {
          failedCount++;
        }
      }

      ShowToastDialog.closeLoader();

      if (successCount == 0) {
        ShowToastDialog.showToast("Failed to share location".tr);
        return;
      }

      if (failedCount == 0) {
        ShowToastDialog.showToast(
            "Location shared with $successCount contact(s)".tr);
      } else {
        ShowToastDialog.showToast(
            "Shared with $successCount, failed for $failedCount".tr);
      }

      controller.clearShareSelection();
      Get.back();
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to share location: $e".tr);
    }
  }
}
