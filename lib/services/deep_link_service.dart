import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_links/app_links.dart';

import 'package:poolmate/app/home_screen/ride_details.dart';
import 'package:poolmate/app/myride/published_details_screen.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';

/// Central service for handling incoming deep links of the form:
///   https://bolaletsgo.com/ride/{rideId}
///
/// Usage:
///   1. Call [DeepLinkService.instance.initialize()] once from main / MyApp.
///   2. After a successful login, call [DeepLinkService.handlePendingLink()]
///      to redirect the user to any ride that was pending authentication.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Stores the rideId that was received before the user logged in.
  /// Cleared automatically after navigation succeeds.
  static String? pendingRideId;

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Must be called once when the app starts (e.g. inside [MyApp.initState]).
  Future<void> initialize() async {
    // Handle the initial URI that launched the app (cold start / warm start).
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 DeepLinkService: initial URI = $initialUri');
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('🔗 DeepLinkService: error reading initial URI — $e');
    }

    // Listen for subsequent links while the app is running (foreground).
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('🔗 DeepLinkService: foreground URI = $uri');
        _handleUri(uri);
      },
      onError: (err) {
        debugPrint('🔗 DeepLinkService: stream error — $err');
      },
    );
  }

  /// Disposes the stream subscription (call from app dispose if needed).
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  /// After a successful login, call this to navigate to any pending ride.
  /// Returns true if a pending ride was navigated.
  static Future<bool> handlePendingLink() async {
    if (pendingRideId == null) return false;
    final rideId = pendingRideId!;
    pendingRideId = null; // clear before navigating to avoid loops
    await navigateToRide(rideId);
    return true;
  }

  /// Fetches the [BookingModel] for [rideId] from Firestore and opens the
  /// appropriate screen:
  ///   • If the current user is the **publisher** of the ride →
  ///       [PublishedDetailsScreen] (their ride-management view).
  ///   • Otherwise → [RidePage] (the passenger seat-booking view).
  static Future<void> navigateToRide(String rideId) async {
    ShowToastDialog.showLoader('Loading ride...');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('booking')
          .doc(rideId)
          .get();

      if (!doc.exists || doc.data() == null) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Ride not found or no longer available.');
        return;
      }

      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] = doc.id;
      final booking = BookingModel.fromJson(data);

      ShowToastDialog.closeLoader();

      final currentUid = AuthUtils.getCurrentUid();
      final isPublisher =
          currentUid.isNotEmpty && booking.createdBy == currentUid;

      if (isPublisher) {
        // ── Publisher opened their own ride link ────────────────────────
        // Route to the ride-management screen, not the booking UI.
        debugPrint(
            '🔗 DeepLinkService: publisher opened own ride — routing to PublishedDetailsScreen');
        Future.delayed(const Duration(milliseconds: 300), () {
          ShowToastDialog.showToast('🚗 This is your ride! Showing your ride details.');
        });
        Get.to(
          () => const PublishedDetailsScreen(),
          arguments: {'bookingModel': booking},
          transition: Transition.rightToLeftWithFade,
        );
      } else {
        // ── Passenger (or guest) ────────────────────────────────────────
        final stopOver = _buildStopOverFromBooking(booking);
        Get.to(
          () => RidePage(bookingModel: booking, stopOverModel: stopOver),
          transition: Transition.rightToLeftWithFade,
        );
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Failed to load ride. Please try again.');
      debugPrint('🔗 DeepLinkService: navigateToRide error — $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Parses the URI and dispatches to the correct handler.
  void _handleUri(Uri uri) {
    // Only handle: https://bolaletsgo.com/ride/{rideId}
    if (uri.host != 'bolaletsgo.com') return;

    final segments = uri.pathSegments; // ['ride', '123']
    if (segments.length >= 2 && segments[0] == 'ride') {
      final rideId = segments[1];
      debugPrint('🔗 DeepLinkService: extracted rideId = $rideId');
      _handleRideLink(rideId);
    }
  }

  /// Routes the user based on their authentication state.
  void _handleRideLink(String rideId) {
    final isLoggedIn = AuthUtils.getCurrentUid().isNotEmpty;

    if (isLoggedIn) {
      // CASE 1: App installed + logged in → open ride immediately.
      navigateToRide(rideId);
    } else {
      // CASE 2 / 3: Not logged in → store rideId, show login.
      // After login completes, [handlePendingLink] will navigate.
      pendingRideId = rideId;
      debugPrint(
          '🔗 DeepLinkService: user not logged in — storing pending rideId');
      // Don't push LoginScreen here — the splash / onboarding flow handles it.
    }
  }

  /// Constructs a [StopOverModel] directly from a [BookingModel]'s stored
  /// fields so we can open [RidePage] without re-running the search pipeline.
  static StopOverModel _buildStopOverFromBooking(BookingModel booking) {
    return StopOverModel(
      startAddress: booking.pickUpAddress,
      endAddress: booking.dropAddress,
      // Use the booking's own price — no stopover surcharge.
      price: booking.pricePerSeat,
    );
  }
}
