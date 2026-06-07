import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationServiceManager {
  static final LocationServiceManager instance = LocationServiceManager._internal();

  factory LocationServiceManager() {
    return instance;
  }

  LocationServiceManager._internal();

  /// Starts the background location tracking service if permissions are granted
  Future<bool> startTracking({
    required String senderId,
    required String receiverId,
    required String chatId,
    String? bookingId,
    int? durationMins,
  }) async {
    if (Platform.isIOS) {
      // Background location handled via geolocator directly on iOS
      return false;
    }

    bool hasPermissions = await _checkPermissions();
    if (!hasPermissions) {
      return false;
    }

    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();

    if (!isRunning) {
      await service.startService();
    }

    service.invoke('startSharing', {
      'senderId': senderId,
      'receiverId': receiverId,
      'chatId': chatId,
      'bookingId': bookingId,
      'durationMins': durationMins,
    });

    return true;
  }

  /// Stops the background tracking service completely
  Future<void> stopTracking() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    
    if (isRunning) {
      service.invoke('stopService');
    }
  }

  /// Check if all required location permissions are granted
  Future<bool> _checkPermissions() async {
    var bgStatus = await Permission.locationAlways.status;
    if (bgStatus.isGranted) {
      return true;
    }
    
    var fineStatus = await Permission.location.status;
    return fineStatus.isGranted;
  }
}
