import 'package:flutter/material.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/chat/chat_screen.dart';
import 'package:poolmate/app/chat/model/inbox_model.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/inbox_controller.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/utils/network_image_widget.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

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
            automaticallyImplyLeading: false,
            title: Text(
              "Inbox".tr,
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
          body: SafeArea(
            child: controller.isLoading.value
                ? Center(child: Constant.loader())
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
                    itemBuilder: (context, documentSnapshots, index) {
                      InboxModel inboxModel = InboxModel.fromJson(
                          documentSnapshots[index].data()
                              as Map<String, dynamic>);
                      return Container(
                          padding: const EdgeInsets.only(
                              left: 14, right: 14, top: 06, bottom: 06),
                          child: InkWell(
                            onTap: () async {
                              ShowToastDialog.showLoader("Please wait".tr);
                              await UserUtils.getUserProfile(
                                      controller.senderUserModel.value.id ==
                                              inboxModel.senderId.toString()
                                          ? inboxModel.receiverId.toString()
                                          : inboxModel.senderId.toString())
                                  .then((value) {
                                ShowToastDialog.closeLoader();
                                if (value == null) {
                                  ShowToastDialog.showToast(
                                      "User deleted. you are not able to see chat");
                                } else {
                                  UserModel userModel = value;
                                  Get.to(const ChatScreen(),
                                      arguments: {"receiverModel": userModel});
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 5),
                              child: FutureBuilder<UserModel?>(
                                  future: UserUtils.getUserProfile(
                                      controller.senderUserModel.value.id ==
                                              inboxModel.senderId.toString()
                                          ? inboxModel.receiverId.toString()
                                          : inboxModel.senderId.toString()),
                                  builder: (context, snapshot) {
                                    switch (snapshot.connectionState) {
                                      case ConnectionState.waiting:
                                        return const SizedBox();
                                      case ConnectionState.done:
                                        if (snapshot.hasError) {
                                          return Text(
                                              snapshot.error.toString());
                                        } else if (snapshot.data == null) {
                                          return Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(60),
                                                child: NetworkImageWidget(
                                                  imageUrl: "",
                                                  height: Responsive.width(
                                                      12, context),
                                                  width: Responsive.width(
                                                      12, context),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            "User Deleted",
                                                            style: TextStyle(
                                                                color: themeChange.getThem()
                                                                    ? AppThemeData
                                                                        .grey100
                                                                    : AppThemeData
                                                                        .grey800,
                                                                fontFamily:
                                                                    AppThemeData
                                                                        .bold,
                                                                fontSize: 16),
                                                          ),
                                                        ),
                                                        Text(
                                                          Constant
                                                              .timestampToDateChat(
                                                                  inboxModel
                                                                      .timestamp!),
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
                                                              fontSize: 12),
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        } else {
                                          UserModel? userModel = snapshot.data;
                                          return Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(60),
                                                child: NetworkImageWidget(
                                                  imageUrl: userModel!
                                                      .profilePic
                                                      .toString(),
                                                  height: Responsive.width(
                                                      12, context),
                                                  width: Responsive.width(
                                                      12, context),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            userModel
                                                                .fullName()
                                                                .toString(),
                                                            style: TextStyle(
                                                                color: themeChange.getThem()
                                                                    ? AppThemeData
                                                                        .grey100
                                                                    : AppThemeData
                                                                        .grey800,
                                                                fontFamily:
                                                                    AppThemeData
                                                                        .bold,
                                                                fontSize: 16),
                                                          ),
                                                        ),
                                                        Text(
                                                          Constant
                                                              .timestampToDateChat(
                                                                  inboxModel
                                                                      .timestamp!),
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
                                                              fontSize: 12),
                                                        )
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            userModel.email
                                                                .toString(),
                                                            style: TextStyle(
                                                                color: themeChange.getThem()
                                                                    ? AppThemeData
                                                                        .grey100
                                                                    : AppThemeData
                                                                        .grey800,
                                                                fontFamily:
                                                                    AppThemeData
                                                                        .medium,
                                                                fontSize: 14),
                                                          ),
                                                        ),
                                                        inboxModel.seen ==
                                                                    true ||
                                                                (inboxModel.unreadCount ??
                                                                        0) ==
                                                                    0
                                                            ? const SizedBox()
                                                            : SizedBox(
                                                                width: 20,
                                                                height: 20,
                                                                child: ClipOval(
                                                                  child:
                                                                      Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                            color:
                                                                                AppThemeData.primary300),
                                                                    child:
                                                                        Center(
                                                                      child:
                                                                          Text(
                                                                        '${inboxModel.unreadCount ?? 0}',
                                                                        style: TextStyle(
                                                                            color: Colors
                                                                                .white,
                                                                            fontSize:
                                                                                12,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
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
        );
      },
    );
  }
}
