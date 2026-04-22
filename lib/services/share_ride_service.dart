import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/widgets/ride_share_poster.dart';

/// Service responsible for generating a shareable ride poster image and
/// composing the share payload (image + text link).
///
/// Usage:
///   await ShareRideService.shareRide(context, booking, stopOver);
class ShareRideService {
  ShareRideService._(); // private constructor — static-only service

  static const String _baseDomain = 'https://bolaletsgo.com';

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates a poster PNG and shares it along with the deep link.
  ///
  /// [bookingModel] — the ride to share.
  /// [stopOverModel] — provides display addresses (from / to).
  static Future<void> shareRide(
    BuildContext context,
    BookingModel bookingModel,
    StopOverModel stopOverModel, {
    String? distance,
    int? availableSeats,
  }) async {
    final rideId = bookingModel.id;
    if (rideId == null || rideId.isEmpty) {
      debugPrint('ShareRideService: rideId is null — cannot share');
      return;
    }

    try {
      // 1. Derive human-readable fields ─────────────────────────────────────
      final from =
          stopOverModel.startAddress?.split(',').first ??
          bookingModel.pickUpAddress?.split(',').first ??
          'Location';

      final to =
          stopOverModel.endAddress?.split(',').first ??
          bookingModel.dropAddress?.split(',').first ??
          'Location';

      final price = Constant.amountShow(
        amount: (stopOverModel.price ?? bookingModel.pricePerSeat ?? '0').toString(),
      );

      final dt = bookingModel.departureDateTime?.toDate();
      final date = dt != null ? "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}" : '';
      final time = dt != null ? "${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}" : '';

      // 2. Generate deep link ───────────────────────────────────────────────
      final deepLink = '$_baseDomain/ride/$rideId';

      // 3. Capture poster widget to PNG bytes ──────────────────────────────
      final screenshotController = ScreenshotController();

      final pngBytes = await screenshotController.captureFromLongWidget(
        RideSharePosterWidget(
          fromLocation: from,
          toLocation: to,
          price: price,
          date: date,
          time: time,
          distance: distance,
          availableSeats: availableSeats,
        ),
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 100),
      );

      // 4. Save PNG to temp file ────────────────────────────────────────────
      final tempDir = await getTemporaryDirectory();
      final imagePath = '${tempDir.path}/ride_share_$rideId.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      // 5. Compose share text ──────────────────────────────────────────────
      String extraInfo = '';
      if (distance != null && distance.isNotEmpty && distance != "N/A") {
        extraInfo += '📍 Distance $distance\n';
      }
      if (availableSeats != null) {
        extraInfo += '💺 $availableSeats Seats Left\n';
      }

      final shareText = '''🚗 Ride Available on Bola!

$from → $to
💰 Fare $price
📅 $date at $time
$extraInfo
Book now: $deepLink''';

      // 6. Share via native share sheet ────────────────────────────────────
      await Share.shareXFiles(
        [XFile(imagePath, mimeType: 'image/png')],
        subject: 'Share Ride — Bola',
        text: shareText,
      );

      // 7. Clean up temp file (fire-and-forget) ────────────────────────────
      _deleteTempFile(imageFile);
    } catch (e) {
      debugPrint('ShareRideService: error — $e');
      // Graceful fallback: share text link only (no poster)
      final deepLink = '$_baseDomain/ride/$rideId';
      final fallbackText = 'Check out this ride on Bola!\n\n$deepLink';
      try {
        await Share.share(fallbackText);
      } catch (_) {
        // Last resort — silent fail
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Deletes the temp file after sharing (fire-and-forget).
  static void _deleteTempFile(File file) {
    Future.delayed(const Duration(seconds: 5), () {
      try {
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    });
  }
}
