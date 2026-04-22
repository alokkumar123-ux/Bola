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
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'high_importance_channel',
      initialNotificationTitle: 'Location Sharing Active',
      initialNotificationContent: 'Sharing your live location in chat',
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

  String? senderId;
  String? receiverId;
  String? chatId;
  DateTime? endTime;
  String? bookingId;
  Position? currentPosition;
  StreamSubscription<Position>? positionStream;

  Future<void> performStop() async {
    positionStream?.cancel();

    // Mark as inactive in Firestore before stopping
    if (senderId != null && receiverId != null && chatId != null) {
      try {
        await FirebaseFirestore.instance
            .collection(CollectionName.chat)
            .doc(senderId)
            .collection(receiverId!)
            .doc(chatId)
            .update({'metadata.isActive': false});

        await FirebaseFirestore.instance
            .collection(CollectionName.chat)
            .doc(receiverId)
            .collection(senderId!)
            .doc(chatId)
            .update({'metadata.isActive': false});
      } catch (e) {
        print("Error deactivating location: \$e");
      }
    }

    service.invoke('locationSharingStopped');
    service.stopSelf();
  }

  service.on('stopService').listen((event) async {
    await performStop();
  });

  service.on('startSharing').listen((event) async {
    if (event != null) {
      senderId = event['senderId'];
      receiverId = event['receiverId'];
      chatId = event['chatId'];
      bookingId = event['bookingId'];

      int? durationMins = event['durationMins'];
      if (durationMins != null) {
        endTime = DateTime.now().add(Duration(minutes: durationMins));
      } else {
        endTime = null;
      }

      // Start the location stream immediately to keep GPS awake and get fast updates
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

        positionStream?.cancel();
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
  });

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (senderId == null || receiverId == null || chatId == null) return;

    // Check if time expired
    if (endTime != null && DateTime.now().isAfter(endTime!)) {
      await performStop();
      return;
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
            await performStop();
            return;
          }
        }
      } catch (e) {
        // ignore errors
      }
    }

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

    try {
      if (currentPosition == null) return;

      // We maintain the location internally in the generic metadata for the chat bubble.
      Map<String, dynamic> updateData = {
        'metadata.lat': currentPosition!.latitude,
        'metadata.lng': currentPosition!.longitude,
        'metadata.lastUpdate': Timestamp.now(),
        // Marking it as active. Use this flag to stop showing the live map when the user stops sharing.
        'metadata.isActive': true,
      };

      await FirebaseFirestore.instance
          .collection(CollectionName.chat)
          .doc(senderId)
          .collection(receiverId!)
          .doc(chatId)
          .update(updateData);

      await FirebaseFirestore.instance
          .collection(CollectionName.chat)
          .doc(receiverId)
          .collection(senderId!)
          .doc(chatId)
          .update(updateData);
    } catch (e) {
      print("Error updating background live location: \$e");
    }
  });
}
