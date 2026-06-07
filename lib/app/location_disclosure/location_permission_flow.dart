import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionFlow {
  static Future<void> checkAndRequestPermissions(BuildContext context, {required VoidCallback onComplete}) async {
    await _requestPermissionsSequence(onComplete);
  }

  static Future<void> _requestPermissionsSequence(VoidCallback onComplete) async {
    // 1. Request notification permission (Android 13+)
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    // 2. Request Foreground Location (Fine)
    var fineStatus = await Permission.location.status;
    if (!fineStatus.isGranted) {
      fineStatus = await Permission.location.request();
    }

    // 3. If Foreground is granted, request Background Location
    if (fineStatus.isGranted || fineStatus.isLimited) {
      var bgStatus = await Permission.locationAlways.status;
      if (!bgStatus.isGranted) {
        // Show a quick dialog explaining the "Allow all the time" requirement for OS dialog
        await Get.dialog(
          AlertDialog(
            title: const Text('Background Location Needed'),
            content: const Text(
                'To track your ride and keep you safe when the app is minimized, please select "Allow all the time" in the next screen.'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Continue'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
        bgStatus = await Permission.locationAlways.request();
      }
      
      if (bgStatus.isPermanentlyDenied) {
        await _showSettingsDialog();
      }
    } else if (fineStatus.isPermanentlyDenied) {
      await _showSettingsDialog();
    }

    // Finally, complete the flow
    onComplete();
  }

  static Future<void> _showSettingsDialog() async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Location Access Denied'),
        content: const Text(
            'Bola requires location access to function properly. Please enable it in Settings -> Permissions -> Location.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
