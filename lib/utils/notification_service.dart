// import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/chat/inbox_screen.dart';
import 'package:poolmate/app/help_support_screen/help_support_screen.dart';
import 'package:poolmate/services/sos_audio_service.dart';
import 'package:poolmate/utils/fire_store_utils.dart';
import 'package:poolmate/utils/preferences.dart';

/// Top-level function for handling Awesome Notifications action (tap)
/// Must be top-level for background execution
@pragma('vm:entry-point')
Future<void> awesomeOnActionReceivedMethod(
    ReceivedAction receivedAction) async {
  log('Awesome Notification action received: ${receivedAction.payload}');

  final String? type = receivedAction.payload?['type'];

  // Stop SOS audio when notification is tapped
  if (type == 'sos_alert') {
    log('SOS Alert notification tapped - stopping audio');
    try {
      if (Get.isRegistered<SosAudioService>()) {
        final sosAudioService = Get.find<SosAudioService>();
        await sosAudioService.stopPlaying();
      }
    } catch (e) {
      log("Error stopping SOS audio on notification tap: $e");
    }
  }

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
  log('Awesome Notification created: ${receivedNotification.id}');
}

@pragma('vm:entry-point')
Future<void> awesomeOnNotificationDisplayedMethod(
    ReceivedNotification receivedNotification) async {
  log('Awesome Notification displayed: ${receivedNotification.id}');
  
  // Start audio when SOS notification is displayed
  final String? type = receivedNotification.payload?['type'];
  if (type == 'sos_alert') {
    log('SOS notification displayed - starting audio');
    try {
      if (!Get.isRegistered<SosAudioService>()) {
        Get.put(SosAudioService());
      }
      final sosAudioService = Get.find<SosAudioService>();
      await sosAudioService.startPlaying();
    } catch (e) {
      log("Error starting SOS audio on notification display: $e");
    }
  }
}

@pragma('vm:entry-point')
Future<void> awesomeOnDismissActionReceivedMethod(
    ReceivedAction receivedAction) async {
  log('Awesome Notification dismissed: ${receivedAction.id}');
  
  // Stop SOS audio when notification is dismissed
  final String? type = receivedAction.payload?['type'];
  if (type == 'sos_alert') {
    try {
      if (Get.isRegistered<SosAudioService>()) {
        final sosAudioService = Get.find<SosAudioService>();
        await sosAudioService.stopPlaying();
        log('SOS audio stopped after notification dismissed');
      }
    } catch (e) {
      log('Error stopping SOS audio on dismiss: $e');
    }
  }
}

/// Top-level function for handling Firebase background messages
/// Must be top-level for background execution
@pragma('vm:entry-point')
Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log("🔔 BackGround Message :: ${message.messageId}");
  log("🔔 BackGround Message Data :: ${message.data}");
  log("🔔 BackGround Notification :: ${message.notification?.title} - ${message.notification?.body}");

  // Handle background notification data
  if (message.data.isNotEmpty || message.notification != null) {
    final String type = message.data['type'] ?? '';
    log("🔔 Background notification type: $type");

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

      String channelKey = type == 'sos_alert' ? 'sos_channel' : 'high_importance_channel';

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
      log("✅ Background notification created successfully");
    } catch (e) {
      log("❌ Error creating background notification: $e");
    }
  }
}

class NotificationService {
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
      criticalAlert: true, // Request critical alert permission for SOS
      provisional: false,
      sound: true,
    );

    log('Notification permission status: ${request.authorizationStatus}');

    if (request.authorizationStatus == AuthorizationStatus.authorized ||
        request.authorizationStatus == AuthorizationStatus.provisional) {
      log('Notification service initialized successfully');
      await setupInteractedMessage();
    }
  }

  Future<void> setupInteractedMessage() async {
    // Check for initial message (app opened from terminated state via notification)
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      log("App opened from terminated state with message: ${initialMessage.data}");
      final String type = initialMessage.data['type'] ?? '';
      await handleNotificationTap(type: type, isBgApp: true, data: initialMessage.data);
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      log("::::::::::::onMessage (FOREGROUND):::::::::::::::::");
      log('Message data: ${message.data}');
      log('Message notification: ${message.notification?.toMap()}');
      log('Has notification object: ${message.notification != null}');

      // Check for SOS alert and start playing audio
      final String type = message.data['type'] ?? '';
      if (type == 'sos_alert') {
        log("SOS Alert received in foreground - starting continuous audio playback");
        try {
          // Initialize SOS audio service if not already initialized
          if (!Get.isRegistered<SosAudioService>()) {
            Get.put(SosAudioService());
          }
          final sosAudioService = Get.find<SosAudioService>();
          await sosAudioService.startPlaying();
        } catch (e) {
          log("Error starting SOS audio: $e");
        }

        // Display SOS notification using Awesome Notifications
        await _displaySosNotification(message);
      } else {
        // Display ALL notifications when app is in foreground
        // FCM doesn't show notifications automatically in foreground, so we must display them
        log('Displaying notification in foreground: ${message.notification?.title ?? "No title"}');
        await display(message);
      }
    });
    
    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) async {
      log("::::::::::::onMessageOpenedApp:::::::::::::::::");
      if (message != null) {
        final String type = message.data['type'] ?? '';
        await handleNotificationTap(type: type, isBgApp: false, data: message.data);
      }
    });

    log("::::::::::::Permission authorized:::::::::::::::::");
    await FirebaseMessaging.instance.subscribeToTopic("QuicklAI");
  }

  Future<void> _displaySosNotification(RemoteMessage message) async {
    try {
      final String title = message.notification?.title ?? 'SOS Alert!';
      final String body = message.notification?.body ?? 'Passenger triggered SOS. Tap to respond.';

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

      log('SOS Notification displayed using Awesome Notifications');
    } catch (e) {
      log('Error displaying SOS notification: $e');
    }
  }

  static Future<void> handleNotificationTap(
      {required String type,
      required bool isBgApp,
      Map<String, dynamic>? data}) async {
    final String uid = FireStoreUtils.getCurrentUid();

    // Handle SOS alert - stop audio once driver acknowledges
    if (type == 'sos_alert') {
      log("SOS Alert notification handled - stopping audio");
      try {
        if (Get.isRegistered<SosAudioService>()) {
          final sosAudioService = Get.find<SosAudioService>();
          await sosAudioService.stopPlaying();
        }
      } catch (e) {
        log("Error stopping SOS audio on notification tap: $e");
      }
    } else if (type == 'admin_chat' && uid.isNotEmpty) {
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
      log('Test notification created');
    } catch (e) {
      log('Error creating test notification: $e');
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

      log('Displaying notification - Type: $type, Title: $title, Body: $body');

      // Use high_importance_channel to match FCM channel_id
      String channelKey = 'high_importance_channel';
      if (type == 'sos_alert') {
        channelKey = 'sos_channel';
      }

      // Convert message.data to Map<String, String?> for payload
      Map<String, String?> payloadMap = {};
      message.data.forEach((key, value) {
        payloadMap[key] = value?.toString();
      });

      // Ensure we have a valid notification ID
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

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

      log('✅ Notification displayed successfully using Awesome Notifications (ID: $notificationId)');
    } catch (e, stackTrace) {
      log('❌ Error displaying notification with Awesome Notifications: $e');
      log('Stack trace: $stackTrace');
    }
  }
}
