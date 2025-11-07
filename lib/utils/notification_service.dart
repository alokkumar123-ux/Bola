import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/chat/inbox_screen.dart';
import 'package:poolmate/app/help_support_screen/help_support_screen.dart';
import 'package:poolmate/utils/fire_store_utils.dart';
import 'package:poolmate/utils/preferences.dart';

Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log("BackGround Message :: ${message.messageId}");
  log("BackGround Message Data :: ${message.data}");

  // Handle background notification data
  if (message.data.isNotEmpty) {
    final String type = message.data['type'] ?? '';
    log("Background notification type: $type");
  }
}

class NotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  initInfo() async {
    log('Initializing notification service...');

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    var request = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    log('Notification permission status: ${request.authorizationStatus}');

    if (request.authorizationStatus == AuthorizationStatus.authorized ||
        request.authorizationStatus == AuthorizationStatus.provisional) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      var iosInitializationSettings = const DarwinInitializationSettings();
      final InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: iosInitializationSettings);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse: (response) async {
        log('Notification tapped with payload: ${response.payload}');
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          final String type = data['type'] ?? '';
          _handleMessageClick(type: type, isBgApp: false, data: data);
        }
      });

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'chat_notifications',
        'Chat Notifications',
        description: 'Notifications for chat messages',
        importance: Importance.high,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      log('Notification service initialized successfully');
      setupInteractedMessage();
    }
  }

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      FirebaseMessaging.onBackgroundMessage(
          (message) => firebaseMessageBackgroundHandle(message));
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("::::::::::::onMessage:::::::::::::::::");
      log('Message data: ${message.data}');
      log('Message notification: ${message.notification?.toMap()}');

      if (message.notification != null) {
        log('Displaying notification: ${message.notification!.title}');
        display(message);
      } else {
        log('No notification payload found');
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) async {
      log("::::::::::::onMessageOpenedApp:::::::::::::::::");
      if (message != null) {
        final String type = message.data['type'] ?? '';
        _handleMessageClick(type: type, isBgApp: false, data: message.data);
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final String type = message.data['type'] ?? '';
        _handleMessageClick(type: type, isBgApp: true, data: message.data);
      }
    });

    log("::::::::::::Permission authorized:::::::::::::::::");
    await FirebaseMessaging.instance.subscribeToTopic("QuicklAI");
  }

  _handleMessageClick(
      {required String type,
      required bool isBgApp,
      Map<String, dynamic>? data}) async {
    final String uid = FireStoreUtils.getCurrentUid();
    if (type == 'admin_chat' && uid.isNotEmpty) {
      await Preferences.setBoolean(Preferences.isClickOnNotification, true);
      if (isBgApp == false) {
        Get.offAll(HelpSupportScreen());
      }
    } else if (type == 'chat' && uid.isNotEmpty) {
      await Preferences.setBoolean(Preferences.isClickOnNotification, true);
      if (isBgApp == false) {
        // Navigate to inbox screen when chat notification is tapped
        Get.offAll(const InboxScreen());
      }
    }
  }

  static getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      log('Current FCM Token: $token');
      return token ?? '';
    } catch (e) {
      log('Failed to get FCM token: $e');
      // Return empty string if token retrieval fails
      return '';
    }
  }

  // Debug method to test notification
  static Future<void> testNotification() async {
    try {
      final NotificationService service = NotificationService();
      await service.flutterLocalNotificationsPlugin.show(
        999,
        'Test Notification',
        'This is a test notification to verify the setup',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_notifications',
            'Chat Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      log('Test notification sent successfully');
    } catch (e) {
      log('Error sending test notification: $e');
    }
  }

  void display(RemoteMessage message) async {
    log('Displaying notification in foreground...');
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'chat_notifications',
        'Chat Notifications',
        description: 'Notifications for chat messages',
        importance: Importance.high,
      );

      AndroidNotificationDetails notificationDetails =
          AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
              presentAlert: true, presentBadge: true, presentSound: true);

      NotificationDetails notificationDetailsBoth = NotificationDetails(
          android: notificationDetails, iOS: darwinNotificationDetails);

      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        message.notification!.title,
        message.notification!.body,
        notificationDetailsBoth,
        payload: jsonEncode(message.data),
      );

      log('Notification displayed successfully with ID: $notificationId');
    } on Exception catch (e) {
      log('Error displaying notification: $e');
    }
  }
}
