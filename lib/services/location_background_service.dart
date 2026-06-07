import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/firebase_options.dart';

Future<void> initializeBackgroundLocationService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      // IMPORTANT: autoStart MUST be false.
      // Setting true causes startForegroundService() to be called on every
      // app launch. On Android 12+ (and MIUI devices) if startForeground()
      // is not called within ~5 s the OS throws
      // ForegroundServiceDidNotStartInTimeException and kills the app.
      // The service is started on-demand via startService() only when the
      // user actively begins a live-location share.
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'high_importance_channel',
      initialNotificationTitle: 'Bola Background Tracking Active',
      initialNotificationContent: 'Tracking live location for your safety',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  List<Map<String, dynamic>> activeShares = [];
  Position? currentPosition;
  StreamSubscription<Position>? positionStream;

  Future<void> performStop() async {
    positionStream?.cancel();

    // Mark as inactive in Firestore before stopping
    for (var share in activeShares) {
      final senderId = share['senderId'];
      final receiverId = share['receiverId'];
      final chatId = share['chatId'];
      if (senderId != null && receiverId != null && chatId != null) {
        try {
          await FirebaseFirestore.instance
              .collection(CollectionName.chat)
              .doc(senderId)
              .collection(receiverId)
              .doc(chatId)
              .update({'metadata.isActive': false});

          await FirebaseFirestore.instance
              .collection(CollectionName.chat)
              .doc(receiverId)
              .collection(senderId)
              .doc(chatId)
              .update({'metadata.isActive': false});
        } catch (e) {
          print("Error deactivating location: $e");
        }
      }
    }

    activeShares.clear();
    service.invoke('locationSharingStopped');
    service.stopSelf();
  }

  service.on('stopService').listen((event) async {
    await performStop();
  });

  service.on('startSharing').listen((event) async {
    if (event != null) {
      int? durationMins = event['durationMins'];
      DateTime? endTime = durationMins != null 
          ? DateTime.now().add(Duration(minutes: durationMins)) 
          : null;

      activeShares.add({
        'senderId': event['senderId'],
        'receiverId': event['receiverId'],
        'chatId': event['chatId'],
        'bookingId': event['bookingId'],
        'endTime': endTime,
      });

      // Start the location stream immediately to keep GPS awake and get fast updates
      if (positionStream == null) {
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          LocationPermission permission = await Geolocator.checkPermission();
          if (!serviceEnabled || permission != LocationPermission.always) {
            service.invoke('locationPermissionRequired');
            await performStop();
            return;
          }

          // Get a fresh fix first for better initial accuracy.
          try {
            currentPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.best,
              timeLimit: const Duration(seconds: 12),
            );
          } catch (_) {
            currentPosition = await Geolocator.getLastKnownPosition();
          }

          positionStream = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 0,
            ),
          ).listen((Position position) {
            currentPosition = position;
          });
        } catch (e) {
          print("Error initializing location stream: $e");
        }
      }
    }
  });

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (activeShares.isEmpty) return;

    // Keep enforcing background permission while running.
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (!serviceEnabled || permission != LocationPermission.always) {
        service.invoke('locationPermissionRequired');
        await performStop();
        return;
      }
    } catch (_) {}

    if (currentPosition == null) return;

    List<Map<String, dynamic>> sharesToRemove = [];

    for (var share in activeShares) {
      final senderId = share['senderId'];
      final receiverId = share['receiverId'];
      final chatId = share['chatId'];
      final bookingId = share['bookingId'];
      final DateTime? endTime = share['endTime'];

      if (senderId == null || receiverId == null || chatId == null) {
        sharesToRemove.add(share);
        continue;
      }

      // Check if time expired
      if (endTime != null && DateTime.now().isAfter(endTime)) {
        sharesToRemove.add(share);
        continue;
      }

      // Check if ride completed if binding to ride
      if (bookingId != null) {
        try {
          DocumentSnapshot bookingDoc = await FirebaseFirestore.instance
              .collection('booking')
              .doc(bookingId)
              .get();
          if (bookingDoc.exists) {
            String status = bookingDoc.get('status');
            if (status == 'completed' || status == 'cancelled') {
              sharesToRemove.add(share);
              continue;
            }
          }
        } catch (e) {
          // ignore errors
        }
      }

      try {
        // We maintain the location internally in the generic metadata for the chat bubble.
        Map<String, dynamic> updateData = {
          'metadata.lat': currentPosition!.latitude,
          'metadata.lng': currentPosition!.longitude,
          'metadata.currentLat': currentPosition!.latitude,
          'metadata.currentLng': currentPosition!.longitude,
          'metadata.lastUpdate': Timestamp.now(),
          'metadata.currentCapturedAt': Timestamp.now(),
          // Marking it as active. Use this flag to stop showing the live map when the user stops sharing.
          'metadata.isActive': true,
        };

        await FirebaseFirestore.instance
            .collection(CollectionName.chat)
            .doc(senderId)
            .collection(receiverId)
            .doc(chatId)
            .update(updateData);

        await FirebaseFirestore.instance
            .collection(CollectionName.chat)
            .doc(receiverId)
            .collection(senderId)
            .doc(chatId)
            .update(updateData);
      } catch (e) {
        print("Error updating background live location: $e");
      }
    }

    if (sharesToRemove.isNotEmpty) {
      // Mark as inactive in Firestore before removing
      for (var share in sharesToRemove) {
        final senderId = share['senderId'];
        final receiverId = share['receiverId'];
        final chatId = share['chatId'];
        if (senderId != null && receiverId != null && chatId != null) {
          try {
            await FirebaseFirestore.instance
                .collection(CollectionName.chat)
                .doc(senderId)
                .collection(receiverId)
                .doc(chatId)
                .update({'metadata.isActive': false});

            await FirebaseFirestore.instance
                .collection(CollectionName.chat)
                .doc(receiverId)
                .collection(senderId)
                .doc(chatId)
                .update({'metadata.isActive': false});
          } catch (e) {
            print("Error deactivating location: $e");
          }
        }
        activeShares.remove(share);
      }

      // If no active shares left, stop the service completely
      if (activeShares.isEmpty) {
         await performStop();
      }
    }
  });
}
