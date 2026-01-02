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
        print("----->${senderUserModel.value.id.toString()}");
        print("----->${receiverUserModel.value.id.toString()}");
        if (documentSnapshot.docs[i]['receiverId'] ==
            senderUserModel.value.id.toString()) {
          AuthUtils.fireStore
              .collection(CollectionName.chat)
              .doc(documentSnapshot.docs[i]['senderId'])
              .collection(documentSnapshot.docs[i]['receiverId'])
              .doc(documentSnapshot.docs[i]['chatID'])
              .update({'seen': true}).catchError((error) {
            print("Failed : $error");
          });

          AuthUtils.fireStore
              .collection(CollectionName.chat)
              .doc(documentSnapshot.docs[i]['receiverId'])
              .collection(documentSnapshot.docs[i]['senderId'])
              .doc(documentSnapshot.docs[i]['chatID'])
              .update({'seen': true}).catchError((error) {
            print("Failed : $error");
          });

          AuthUtils.fireStore
              .collection(CollectionName.chat)
              .doc(documentSnapshot.docs[i]['senderId'])
              .collection("inbox")
              .doc(documentSnapshot.docs[i]['receiverId'])
              .update({
            'seen': true,
            'unreadCount': 0,
          }).catchError((error) {
            print("Failed to add: $error");
          });

          AuthUtils.fireStore
              .collection(CollectionName.chat)
              .doc(documentSnapshot.docs[i]['receiverId'])
              .collection("inbox")
              .doc(documentSnapshot.docs[i]['senderId'])
              .update({
            'seen': true,
            'unreadCount': 0,
          }).catchError((error) {
            print("Failed to add: $error");
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
      print('Receiver FCM Token: ${receiverUserModel.value.fcmToken}');
    }
    await UserUtils.getUserProfile(AuthUtils.getCurrentUid()).then((value) {
      senderUserModel.value = value!;
      print('Sender FCM Token: ${senderUserModel.value.fcmToken}');
    });
    changeStatus();
    isLoading.value = false;
  }

  sendMessage(String msg) async {
    messageTextEditorController.value.clear();

    // Reuse the static method to avoid code duplication
    await sendMessageStatic(
      senderUser: senderUserModel.value,
      receiverUser: receiverUserModel.value,
      message: msg,
      sendNotification: true,
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  /// Static method to send a chat message from any controller
  /// This allows reusing the chat logic without instantiating ChatController
  static Future<void> sendMessageStatic({
    required UserModel senderUser,
    required UserModel receiverUser,
    required String message,
    bool sendNotification = true,
  }) async {
    try {
      // Get current unread count for the receiver
      int currentUnreadCount = 0;
      try {
        DocumentSnapshot inboxDoc = await AuthUtils.fireStore
            .collection(CollectionName.chat)
            .doc(receiverUser.id.toString())
            .collection("inbox")
            .doc(senderUser.id.toString())
            .get();
        if (inboxDoc.exists) {
          Map<String, dynamic>? data = inboxDoc.data() as Map<String, dynamic>?;
          currentUnreadCount = data?['unreadCount'] ?? 0;
        }
      } catch (e) {
        log('Error getting current unread count: $e');
      }

      // Create inbox model for receiver (unread)
      InboxModel receiverInboxModel = InboxModel(
          archive: false,
          lastMessage: message,
          mediaUrl: "",
          receiverId: receiverUser.id.toString(),
          seen: false,
          senderId: senderUser.id.toString(),
          timestamp: Timestamp.now(),
          type: "text",
          unreadCount: currentUnreadCount + 1);

      // Create inbox model for sender (read)
      InboxModel senderInboxModel = InboxModel(
          archive: false,
          lastMessage: message,
          mediaUrl: "",
          receiverId: receiverUser.id.toString(),
          seen: true,
          senderId: senderUser.id.toString(),
          timestamp: Timestamp.now(),
          type: "text",
          unreadCount: 0);

      // Update sender's inbox
      await AuthUtils.fireStore
          .collection(CollectionName.chat)
          .doc(senderUser.id.toString())
          .collection("inbox")
          .doc(receiverUser.id.toString())
          .set(senderInboxModel.toJson());

      // Update receiver's inbox
      await AuthUtils.fireStore
          .collection(CollectionName.chat)
          .doc(receiverUser.id.toString())
          .collection("inbox")
          .doc(senderUser.id.toString())
          .set(receiverInboxModel.toJson());

      // Create and save chat message
      ChatModel chatModel = ChatModel(
          type: "text",
          timestamp: Timestamp.now(),
          senderId: senderUser.id.toString(),
          seen: false,
          receiverId: receiverUser.id.toString(),
          mediaUrl: "",
          chatID: Constant.getUuid(),
          message: message);

      // Save to sender's conversation
      await AuthUtils.fireStore
          .collection(CollectionName.chat)
          .doc(senderUser.id.toString())
          .collection(receiverUser.id.toString())
          .doc(chatModel.chatID)
          .set(chatModel.toJson());

      // Save to receiver's conversation
      await AuthUtils.fireStore
          .collection(CollectionName.chat)
          .doc(receiverUser.id.toString())
          .collection(senderUser.id.toString())
          .doc(chatModel.chatID)
          .set(chatModel.toJson());

      // Send push notification if enabled
      if (sendNotification &&
          receiverUser.fcmToken != null &&
          receiverUser.fcmToken!.isNotEmpty) {
        Map<String, dynamic> payload = <String, dynamic>{
          "type": "chat",
          "senderId": senderUser.id.toString(),
          "receiverId": receiverUser.id.toString(),
        };
        await SendNotification.sendChatNotification(
            token: receiverUser.fcmToken.toString(),
            title: "New message from ${senderUser.fullName()}",
            body: message,
            payload: payload);
      }

      print("✅ Chat message sent successfully to ${receiverUser.fullName()}");
    } catch (e) {
      print("❌ Error sending chat message: $e");
      rethrow;
    }
  }
}
