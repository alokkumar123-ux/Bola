import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/chat/model/chat_model.dart';
import 'package:poolmate/app/chat/model/inbox_model.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/send_notification.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ChatController extends GetxController {
  final messageTextEditorController = TextEditingController().obs;

  @override
  void onInit() {
    getArgument();
    _checkActiveLocationShare();
    super.onInit();
  }

  RxBool isSharingLocation = false.obs;
  RxBool isSharingLiveLocation = false.obs;
  String? activeLocationChatId;

  _checkActiveLocationShare() async {
    bool isRunning = await FlutterBackgroundService().isRunning();
    if (isRunning) {
      isSharingLocation.value = true;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      isSharingLiveLocation.value = prefs.getBool('isSharingLiveLocation') ?? false;
    }

    FlutterBackgroundService().on('locationSharingStopped').listen((event) async {
      isSharingLocation.value = false;
      isSharingLiveLocation.value = false;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('isSharingLiveLocation', false);
    });

    FlutterBackgroundService().on('locationPermissionRequired').listen((event) async {
      isSharingLocation.value = false;
      isSharingLiveLocation.value = false;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('isSharingLiveLocation', false);
      ShowToastDialog.showToast(
          "Please enable 'Allow all the time' location permission to continue live sharing."
              .tr);
    });
  }

  static Future<bool> requestBackgroundLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ShowToastDialog.showToast(
          "Location services are disabled, please enable them.".tr);
      return false;
    }

    // Request foreground permission first
    PermissionStatus status = await Permission.location.request();
    if (!status.isGranted) {
      ShowToastDialog.showToast(
          "Location permission is required for live tracking.".tr);
      return false;
    }

    // Now request background permission (Allow all the time)
    PermissionStatus alwaysStatus = await Permission.locationAlways.status;
    if (!alwaysStatus.isGranted) {
      // Show dialog explaining why background location is needed
      bool? proceed = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Background Location Required".tr),
          content: Text(
              "To share your live location continually on the map even when the app is minimized, you need to select 'Allow all the time' in the settings."
                  .tr),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text("Cancel".tr),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text("Continue".tr),
            ),
          ],
        ),
      );

      if (proceed != true) return false;

      alwaysStatus = await Permission.locationAlways.request();
      if (!alwaysStatus.isGranted) {
        ShowToastDialog.showToast(
            "Please enable 'Allow all the time' in Settings to share live location."
                .tr);
        await openAppSettings();
        return false;
      }
    }

    // Double-check with geolocator API because background service also relies on it.
    final geoPermission = await Geolocator.checkPermission();
    if (geoPermission != LocationPermission.always) {
      ShowToastDialog.showToast(
          "Live sharing in background requires 'Allow all the time' location permission."
              .tr);
      await openAppSettings();
      return false;
    }

    // Request notification permission (required for foreground service on Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Give the app a split second to return to the active foreground state after system dialogs close, avoiding service startup failures on Android 14+
    await Future.delayed(const Duration(milliseconds: 500));
    
    return true;
  }

  void startLiveLocationSharing(int durationType) async {
    bool hasPermission = await requestBackgroundLocationPermissions();
    if (!hasPermission) return;

    // durationType: 1=15 min, 2=Manually, 3=During ride
    int? durationMins;
    String? bookingId;

    if (durationType == 1) durationMins = 15;
    if (durationType == 3) {
      ShowToastDialog.showLoader("Checking ongoing ride...".tr);
      // Find latest active booking for this user
      var createdBookingsFuture = AuthUtils.fireStore
          .collection('booking')
          .where('createdBy', isEqualTo: senderUserModel.value.id.toString())
          .where('status', isEqualTo: Constant.onGoing)
          .limit(1)
          .get();

      var passengerBookingsFuture = AuthUtils.fireStore
          .collection('booking')
          .where('bookedUserId',
              arrayContains: senderUserModel.value.id.toString())
          .where('status', isEqualTo: Constant.onGoing)
          .limit(1)
          .get();

      var responses =
          await Future.wait([createdBookingsFuture, passengerBookingsFuture]);
      var createdBookings = responses[0];
      var passengerBookings = responses[1];

      ShowToastDialog.closeLoader();

      if (createdBookings.docs.isNotEmpty) {
        bookingId = createdBookings.docs.first.id;
      } else if (passengerBookings.docs.isNotEmpty) {
        bookingId = passengerBookings.docs.first.id;
      } else {
        ShowToastDialog.showToast("You do not have any ongoing ride".tr);
        return;
      }
    }

    ShowToastDialog.showLoader("Starting live location...".tr);

    Position? initialPos;
    try {
      // Prefer a fresh GPS fix for a more accurate first point.
      initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      try {
        initialPos = await Geolocator.getLastKnownPosition();
      } catch (e) {
        print("Warning: Could not get fallback location: $e");
      }
    }

    ShowToastDialog.closeLoader();

    ChatModel locationMsg = ChatModel(
        type: "live_location",
        timestamp: Timestamp.now(),
        senderId: senderUserModel.value.id.toString(),
        receiverId: receiverUserModel.value.id.toString(),
        seen: false,
        mediaUrl: "",
        chatID: Constant.getUuid(),
        message: "Live Location",
        metadata: {
          'isActive': true,
          'lat': initialPos?.latitude ?? 0.0,
          'lng': initialPos?.longitude ?? 0.0,
          'lastUpdate': Timestamp.now()
        });

    // Save to sender
    await AuthUtils.fireStore
        .collection(CollectionName.chat)
        .doc(senderUserModel.value.id.toString())
        .collection(receiverUserModel.value.id.toString())
        .doc(locationMsg.chatID)
        .set(locationMsg.toJson());

    // Save to receiver
    await AuthUtils.fireStore
        .collection(CollectionName.chat)
        .doc(receiverUserModel.value.id.toString())
        .collection(senderUserModel.value.id.toString())
        .doc(locationMsg.chatID)
        .set(locationMsg.toJson());

    isSharingLocation.value = true;
    isSharingLiveLocation.value = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isSharingLiveLocation', true);
    activeLocationChatId = locationMsg.chatID;

    await FlutterBackgroundService().startService();
    // Give the background isolate enough time to fully boot the flutter engine and attach event listeners on first run
    await Future.delayed(const Duration(milliseconds: 2500));

    final serviceRunning = await FlutterBackgroundService().isRunning();
    if (!serviceRunning) {
      isSharingLocation.value = false;
      ShowToastDialog.showToast(
          "Unable to start background location service. Please check battery optimization and try again."
              .tr);
      return;
    }

    FlutterBackgroundService().invoke('startSharing', {
      'senderId': senderUserModel.value.id.toString(),
      'receiverId': receiverUserModel.value.id.toString(),
      'chatId': locationMsg.chatID,
      'durationMins': durationMins,
      'bookingId': bookingId,
    });
  }

  void stopLiveLocationSharing() async {
    isSharingLocation.value = false;
    isSharingLiveLocation.value = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isSharingLiveLocation', false);
    FlutterBackgroundService().invoke('stopService');
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

  /// Send a ride location snapshot card in chat.
  /// Shows start, end and current locations for the given [bookingModel].
  /// The card is sent from [senderUser] to [receiverUser].
  static Future<void> sendRideLocationCard({
    required UserModel senderUser,
    required UserModel receiverUser,
    required BookingModel bookingModel,
    bool showLoader = true,
    bool showSuccessToast = true,
    bool startContinuousSharing = false,
  }) async {
    try {
      if (showLoader) {
        ShowToastDialog.showLoader("Getting location...".tr);
      }

      // Try to get current device position
      double currentLat = 0.0;
      double currentLng = 0.0;
      double currentAccuracyMeters = 0.0;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            Position? pos;

            // Prefer a fresh and accurate GPS fix first.
            try {
              pos = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.best,
                timeLimit: const Duration(seconds: 12),
              );
            } catch (_) {
              // Fallback handled below.
            }

            // Fallback to last known only when relatively recent.
            pos ??= await Geolocator.getLastKnownPosition();
            if (pos != null && pos.timestamp != null) {
              final age = DateTime.now().difference(pos.timestamp!);
              if (age.inMinutes > 10) {
                pos = null;
              }
            }

            if (pos != null) {
              currentLat = pos.latitude;
              currentLng = pos.longitude;
              currentAccuracyMeters = pos.accuracy;
            }
          }
        }
      } catch (e) {
        print("Could not get current position: $e");
      }

      if (showLoader) {
        ShowToastDialog.closeLoader();
      }

      // Build metadata with all three locations
      final metadata = <String, dynamic>{
        // Start (pickup)
        'startAddress': bookingModel.pickUpAddress ?? '',
        'startLat': bookingModel.pickupLocation?.geometry?.location?.lat ?? 0.0,
        'startLng': bookingModel.pickupLocation?.geometry?.location?.lng ?? 0.0,
        // End (drop)
        'endAddress': bookingModel.dropAddress ?? '',
        'endLat': bookingModel.dropLocation?.geometry?.location?.lat ?? 0.0,
        'endLng': bookingModel.dropLocation?.geometry?.location?.lng ?? 0.0,
        // Current
        'currentLat': currentLat,
        'currentLng': currentLng,
        'currentAccuracyMeters': currentAccuracyMeters,
        'currentCapturedAt': Timestamp.now(),
        // Sender name for display
        'senderName': senderUser.fullName(),
        'bookingId': bookingModel.id ?? '',
        'isActive': startContinuousSharing,
      };

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
        log('Error getting unread count: $e');
      }

      const String previewMsg = '📍 Shared ride location';

      InboxModel receiverInboxModel = InboxModel(
          archive: false,
          lastMessage: previewMsg,
          mediaUrl: '',
          receiverId: receiverUser.id.toString(),
          seen: false,
          senderId: senderUser.id.toString(),
          timestamp: Timestamp.now(),
          type: 'ride_location',
          unreadCount: currentUnreadCount + 1);

      InboxModel senderInboxModel = InboxModel(
          archive: false,
          lastMessage: previewMsg,
          mediaUrl: '',
          receiverId: receiverUser.id.toString(),
          seen: true,
          senderId: senderUser.id.toString(),
          timestamp: Timestamp.now(),
          type: 'ride_location',
          unreadCount: 0);

      await AuthUtils.fireStore
          .collection(CollectionName.chat)
          .doc(senderUser.id.toString())
          .collection("inbox")
          .doc(receiverUser.id.toString())
          .set(senderInboxModel.toJson());

      await AuthUtils.fireStore
          .collection(CollectionName.chat)
          .doc(receiverUser.id.toString())
          .collection("inbox")
          .doc(senderUser.id.toString())
          .set(receiverInboxModel.toJson());

      ChatModel chatModel = ChatModel(
          type: 'ride_location',
          timestamp: Timestamp.now(),
          senderId: senderUser.id.toString(),
          seen: false,
          receiverId: receiverUser.id.toString(),
          mediaUrl: '',
          chatID: Constant.getUuid(),
          message: previewMsg,
          metadata: metadata);

      await AuthUtils.fireStore
          .collection(CollectionName.chat)
          .doc(senderUser.id.toString())
          .collection(receiverUser.id.toString())
          .doc(chatModel.chatID)
          .set(chatModel.toJson());

      await AuthUtils.fireStore
          .collection(CollectionName.chat)
          .doc(receiverUser.id.toString())
          .collection(senderUser.id.toString())
          .doc(chatModel.chatID)
          .set(chatModel.toJson());

      if (startContinuousSharing) {
        FlutterBackgroundService().invoke('startSharing', {
          'senderId': senderUser.id.toString(),
          'receiverId': receiverUser.id.toString(),
          'chatId': chatModel.chatID,
          'bookingId': bookingModel.id,
        });
      }

      // Push notification
      if (receiverUser.fcmToken != null && receiverUser.fcmToken!.isNotEmpty) {
        await SendNotification.sendChatNotification(
            token: receiverUser.fcmToken.toString(),
            title: "${senderUser.fullName()} shared ride location",
            body: previewMsg,
            payload: {
              "type": "chat",
              "senderId": senderUser.id.toString(),
              "receiverId": receiverUser.id.toString(),
            });
      }

      if (showSuccessToast) {
        ShowToastDialog.showToast("Ride location shared!".tr);
      }
      print("✅ Ride location card sent to ${receiverUser.fullName()}");
    } catch (e) {
      if (showLoader) {
        ShowToastDialog.closeLoader();
      }
      print("❌ Error sending ride location card: $e");
      rethrow;
    }
  }
}
