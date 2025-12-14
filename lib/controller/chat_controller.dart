import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/chat/model/chat_model.dart';
import 'package:poolmate/app/chat/model/inbox_model.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/send_notification.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';

class ChatController extends GetxController {
  final messageTextEditorController = TextEditingController().obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  changeStatus() async {
    await AuthUtils.fireStore
        .collection(CollectionName.chat)
        .doc(senderUserModel.value.id.toString())
        .collection(receiverUserModel.value.id.toString())
        .where("seen", isEqualTo: false)
        .get()
        .then((documentSnapshot) {
      for (int i = 0; i < documentSnapshot.docs.length; i++) {
        log("----->${senderUserModel.value.id.toString()}");
        log("----->${receiverUserModel.value.id.toString()}");
        if (documentSnapshot.docs[i]['receiverId'] ==
            senderUserModel.value.id.toString()) {
          AuthUtils.fireStore
              .collection(CollectionName.chat)
              .doc(documentSnapshot.docs[i]['senderId'])
              .collection(documentSnapshot.docs[i]['receiverId'])
              .doc(documentSnapshot.docs[i]['chatID'])
              .update({'seen': true}).catchError((error) {
            log("Failed : $error");
          });

          AuthUtils.fireStore
              .collection(CollectionName.chat)
              .doc(documentSnapshot.docs[i]['receiverId'])
              .collection(documentSnapshot.docs[i]['senderId'])
              .doc(documentSnapshot.docs[i]['chatID'])
              .update({'seen': true}).catchError((error) {
            log("Failed : $error");
          });

          AuthUtils.fireStore
              .collection(CollectionName.chat)
              .doc(documentSnapshot.docs[i]['senderId'])
              .collection("inbox")
              .doc(documentSnapshot.docs[i]['receiverId'])
              .update({
            'seen': true,
          }).catchError((error) {
            log("Failed to add: $error");
          });

          AuthUtils.fireStore
              .collection(CollectionName.chat)
              .doc(documentSnapshot.docs[i]['receiverId'])
              .collection("inbox")
              .doc(documentSnapshot.docs[i]['senderId'])
              .update({
            'seen': true,
          }).catchError((error) {
            log("Failed to add: $error");
          });
        }
      }
    });
  }

  RxBool isLoading = true.obs;
  Rx<UserModel> receiverUserModel = UserModel().obs;
  Rx<UserModel> senderUserModel = UserModel().obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      receiverUserModel.value = argumentData['receiverModel'];
      log('Receiver FCM Token: ${receiverUserModel.value.fcmToken}');
    }
    await UserUtils.getUserProfile(AuthUtils.getCurrentUid()).then((value) {
      senderUserModel.value = value!;
      log('Sender FCM Token: ${senderUserModel.value.fcmToken}');
    });
    changeStatus();
    isLoading.value = false;
  }

  sendMessage(String msg) async {
    messageTextEditorController.value.clear();
    InboxModel inboxModel = InboxModel(
        archive: false,
        lastMessage: msg,
        mediaUrl: "",
        receiverId: receiverUserModel.value.id.toString(),
        seen: false,
        senderId: senderUserModel.value.id.toString(),
        timestamp: Timestamp.now(),
        type: "text");

    InboxModel senderInboxModel = InboxModel(
        archive: false,
        lastMessage: msg,
        mediaUrl: "",
        receiverId: receiverUserModel.value.id.toString(),
        seen: true,
        senderId: senderUserModel.value.id.toString(),
        timestamp: Timestamp.now(),
        type: "text");

    await AuthUtils.fireStore
        .collection(CollectionName.chat)
        .doc(senderUserModel.value.id.toString())
        .collection("inbox")
        .doc(receiverUserModel.value.id.toString())
        .set(senderInboxModel.toJson());

    await AuthUtils.fireStore
        .collection(CollectionName.chat)
        .doc(receiverUserModel.value.id.toString())
        .collection("inbox")
        .doc(senderUserModel.value.id.toString())
        .set(inboxModel.toJson());

    ChatModel chatModel = ChatModel(
        type: "text",
        timestamp: Timestamp.now(),
        senderId: senderUserModel.value.id.toString(),
        seen: false,
        receiverId: receiverUserModel.value.id.toString(),
        mediaUrl: "",
        chatID: Constant.getUuid(),
        message: msg);

    await AuthUtils.fireStore
        .collection(CollectionName.chat)
        .doc(senderUserModel.value.id.toString())
        .collection(receiverUserModel.value.id.toString())
        .doc(chatModel.chatID)
        .set(chatModel.toJson());
    await AuthUtils.fireStore
        .collection(CollectionName.chat)
        .doc(receiverUserModel.value.id.toString())
        .collection(senderUserModel.value.id.toString())
        .doc(chatModel.chatID)
        .set(chatModel.toJson());

    Map<String, dynamic> playLoad = <String, dynamic>{
      "type": "chat",
      "senderId": senderUserModel.value.id.toString(),
      "receiverId": receiverUserModel.value.id.toString(),
    };

    if (receiverUserModel.value.fcmToken != null &&
        receiverUserModel.value.fcmToken!.isNotEmpty) {
      log("Sending notification to token: ${receiverUserModel.value.fcmToken}");
      log("Notification payload: $playLoad");
      await SendNotification.sendChatNotification(
          token: receiverUserModel.value.fcmToken.toString(),
          title: "New message from ${senderUserModel.value.fullName()}",
          body: msg,
          payload: playLoad);
    } else {
      log("No FCM token found for receiver: ${receiverUserModel.value.id}");
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}
