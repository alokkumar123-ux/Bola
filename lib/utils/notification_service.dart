// import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/chat/inbox_screen.dart';
import 'package:poolmate/app/help_support_screen/help_support_screen.dart';
import 'package:poolmate/services/sos_audio_service.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/preferences.dart';

/// Top-level function for handling Awesome Notifications action (tap)
/// Must be top-level for background execution
@pragma('vm:entry-point')
Future<void> awesomeOnActionReceivedMethod(
    ReceivedAction receivedAction) async {
  print('Awesome Notification action received: ${receivedAction.payload}');

  final String? type = receivedAction.payload?['type'];

  // Stop SOS audio when notification is tapped
  // if (type == 'sos_alert') {
  //   print('SOS Alert notification tapped - stopping audio');
  //   try {
  //     if (Get.isRegistered<SosAudioService>()) {
  //       final sosAudioService = Get.find<SosAudioService>();
  //       await sosAudioService.stopPlaying();
  //     }
  //   } catch (e) {
  //     print("Error stopping SOS audio on notification tap: $e");
  //   }
  // }

  final bool isBgApp =
      receivedAction.actionLifeCycle != NotificationLifeCycle.Foreground;

  Map<String, dynamic>? payload;
  if (receivedAction.payload != null) {
    payload = receivedAction.payload!.map(
      (key, value) => MapEntry(key, value),
    );
  }

  await NotificationService.handleNotificationTap(
    type: type ?? '',
    isBgApp: isBgApp,
    data: payload,
  );
}

@pragma('vm:entry-point')
Future<void> awesomeOnNotificationCreatedMethod(
    ReceivedNotification receivedNotification) async {
  print('Awesome Notification created: ${receivedNotification.id}');
}

@pragma('vm:entry-point')
Future<void> awesomeOnNotificationDisplayedMethod(
    ReceivedNotification receivedNotification) async {
  print('Awesome Notification displayed: ${receivedNotification.id}');

  // Start audio when SOS notification is displayed
  final String? type = receivedNotification.payload?['type'];
  if (type == 'sos_alert') {
    print('SOS notification displayed - starting audio');
    try {
      if (!Get.isRegistered<SosAudioService>()) {
        Get.put(SosAudioService());
      }
      final sosAudioService = Get.find<SosAudioService>();
      await sosAudioService.startPlaying();
    } catch (e) {
      print("Error starting SOS audio on notification display: $e");
    }
  }
}

@pragma('vm:entry-point')
Future<void> awesomeOnDismissActionReceivedMethod(
    ReceivedAction receivedAction) async {
  print('Awesome Notification dismissed: ${receivedAction.id}');

  // Stop SOS audio when notification is dismissed
  // final String? type = receivedAction.payload?['type'];
  // if (type == 'sos_alert') {
  //   try {
  //     if (Get.isRegistered<SosAudioService>()) {
  //       final sosAudioService = Get.find<SosAudioService>();
  //       await sosAudioService.stopPlaying();
  //       print('SOS audio stopped after notification dismissed');
  //     }
  //   } catch (e) {
  //     print('Error stopping SOS audio on dismiss: $e');
  //   }
  // }
}

/// Top-level function for handling Firebase background messages
/// Must be top-level for background execution
@pragma('vm:entry-point')
Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  print("🔔 BackGround Message :: ${message.messageId}");
  print("🔔 BackGround Message Data :: ${message.data}");
  print(
      "🔔 BackGround Notification :: ${message.notification?.title} - ${message.notification?.body}");

  // Handle background notification data
  if (message.data.isNotEmpty || message.notification != null) {
    final String type = message.data['type'] ?? '';
    print("🔔 Background notification type: $type");

    // For all notifications in background, create using Awesome Notifications
    // Android will also show system notification, but we want to ensure it shows
    try {
      final String title = message.notification?.title ??
          message.data['title'] ??
          'Notification';
      final String body = message.notification?.body ??
          message.data['body'] ??
          message.data['message'] ??
          'You have a new notification';

      // Convert message.data to Map<String, String?> for payload
      Map<String, String?> payloadMap = {};
      message.data.forEach((key, value) {
        payloadMap[key] = value?.toString();
      });

      String channelKey =
          type == 'sos_alert' ? 'sos_channel' : 'high_importance_channel';

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          category: type == 'sos_alert'
              ? NotificationCategory.Alarm
              : NotificationCategory.Message,
          wakeUpScreen: true,
          fullScreenIntent: type == 'sos_alert',
          criticalAlert: type == 'sos_alert',
          payload: payloadMap,
        ),
      );
      print("✅ Background notification created successfully");
    } catch (e) {
      print("❌ Error creating background notification: $e");
    }
  }
}

class NotificationService {
  initInfo() async {
    print('Initializing notification service...');

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
      criticalAlert: true, // Request critical alert permission for SOS
      provisional: false,
      sound: true,
    );

    print('Notification permission status: ${request.authorizationStatus}');

    if (request.authorizationStatus == AuthorizationStatus.authorized ||
        request.authorizationStatus == AuthorizationStatus.provisional) {
      print('Notification service initialized successfully');
      await setupInteractedMessage();
    }
  }

  Future<void> setupInteractedMessage() async {
    // Check for initial message (app opened from terminated state via notification)
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print(
          "App opened from terminated state with message: ${initialMessage.data}");
      final String type = initialMessage.data['type'] ?? '';
      await handleNotificationTap(
          type: type, isBgApp: true, data: initialMessage.data);
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("::::::::::::onMessage (FOREGROUND):::::::::::::::::");
      print('Message data: ${message.data}');
      print('Message notification: ${message.notification?.toMap()}');
      print('Has notification object: ${message.notification != null}');

      // Check for SOS alert and start playing audio
      final String type = message.data['type'] ?? '';
      if (type == 'sos_alert') {
        print(
            "SOS Alert received in foreground - starting continuous audio playback");
        try {
          // Initialize SOS audio service if not already initialized
          if (!Get.isRegistered<SosAudioService>()) {
            Get.put(SosAudioService());
          }
          final sosAudioService = Get.find<SosAudioService>();
          await sosAudioService.startPlaying();
        } catch (e) {
          print("Error starting SOS audio: $e");
        }

        // Display SOS notification using Awesome Notifications
        await _displaySosNotification(message);
      } else {
        // Display ALL notifications when app is in foreground
        // FCM doesn't show notifications automatically in foreground, so we must display them
        print(
            'Displaying notification in foreground: ${message.notification?.title ?? "No title"}');
        await display(message);
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) async {
      if (message != null) {
        final String type = message.data['type'] ?? '';
        await handleNotificationTap(
            type: type, isBgApp: false, data: message.data);
      }
    });

    // Subscribe to topic with timeout to prevent blocking when service is unavailable
    try {
      await FirebaseMessaging.instance
          .subscribeToTopic("QuicklAI")
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    } catch (e) {}
  }

  Future<void> _displaySosNotification(RemoteMessage message) async {
    try {
      final String title = message.notification?.title ?? 'SOS Alert!';
      final String body = message.notification?.body ??
          'Passenger triggered SOS. Tap to respond.';

      // Convert message.data to Map<String, String?> for payload
      Map<String, String?> payloadMap = {};
      message.data.forEach((key, value) {
        payloadMap[key] = value?.toString();
      });

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'sos_channel',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          payload: payloadMap,
        ),
      );

      print('SOS Notification displayed using Awesome Notifications');
    } catch (e) {
      print('Error displaying SOS notification: $e');
    }
  }

  static Future<void> handleNotificationTap(
      {required String type,
      required bool isBgApp,
      Map<String, dynamic>? data}) async {
    final String uid = AuthUtils.getCurrentUid();

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
    } else if (type == 'ride_alert' && uid.isNotEmpty) {
      await Preferences.setBoolean(Preferences.isClickOnNotification, true);
      if (isBgApp == false) {
        // Navigate to search screen when ride alert is tapped
        // You can pass the booking ID from data if needed
        print('Ride alert notification tapped - navigating to search');
        // Get.offAll() with search or booking details if needed
      }
    }
  }

  static getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print('Current FCM Token: $token');
      return token ?? '';
    } catch (e) {
      print('Failed to get FCM token: $e');
      return '';
    }
  }

  static Future<void> testNotification() async {
    // Test SOS notification
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'sos_channel',
          title: 'Test SOS Alert!',
          body: 'This is a test SOS notification.',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          payload: {'type': 'sos_alert'},
        ),
      );
      print('Test notification created');
    } catch (e) {
      print('Error creating test notification: $e');
    }
  }

  Future<void> display(RemoteMessage message) async {
    try {
      final String type = message.data['type'] ?? '';

      // Get title and body from notification object or try to get from data
      String title = message.notification?.title ??
          message.data['title'] ??
          'Notification';
      String body = message.notification?.body ??
          message.data['body'] ??
          message.data['message'] ??
          'You have a new notification';

      print(
          'Displaying notification - Type: $type, Title: $title, Body: $body');

      // Use high_importance_channel to match FCM channel_id
      String channelKey = 'high_importance_channel';
      if (type == 'sos_alert') {
        channelKey = 'sos_channel';
      } else if (type == 'ride_alert') {
        channelKey = 'ride_alert_channel';
      }

      // Convert message.data to Map<String, String?> for payload
      Map<String, String?> payloadMap = {};
      message.data.forEach((key, value) {
        payloadMap[key] = value?.toString();
      });

      // Ensure we have a valid notification ID
      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          category: type == 'sos_alert'
              ? NotificationCategory.Alarm
              : NotificationCategory.Message,
          wakeUpScreen: true,
          fullScreenIntent: type == 'sos_alert',
          criticalAlert: type == 'sos_alert',
          payload: payloadMap,
        ),
      );

      print(
          '✅ Notification displayed successfully using Awesome Notifications (ID: $notificationId)');
    } catch (e, stackTrace) {
      print('❌ Error displaying notification with Awesome Notifications: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Schedule a local notification at a specific time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      // Ensure time is in the future
      if (scheduledTime.isBefore(DateTime.now())) {
        print('❌ Cannot schedule notification in the past: $scheduledTime');
        return;
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'high_importance_channel',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledTime,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
      print(
          '⏰ Notification scheduled successfully for $scheduledTime (ID: $id)');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  /// Cancel a specific scheduled notification
  static Future<void> cancelNotification(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
      print('🗑️ Notification $id cancelled');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }
}
