import 'package:poolmate/model/pending_booking_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/utils/cashfree_verification_utils.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/payment_utils.dart';
import 'package:poolmate/utils/firestore/pending_booking_utils.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/home_screen/booking_success_screen.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/booking_payment_controller.dart';

/// Service to recover incomplete payments on app startup
/// If user paid but app crashed before booking was processed, this will recover it
class PaymentRecoveryService {
  /// Check for pending payments when app starts
  /// Should be called after user is logged in (from DashboardScreen or similar)
  static Future<void> checkAndRecoverPendingPayments() async {
    try {
      final currentUserId = AuthUtils.getCurrentUid();
      if (currentUserId.isEmpty) return;

      print('🔍 Checking for pending payments...');

      final pendingBookings =
          await PendingBookingUtils.getPendingBookingsForUser(currentUserId);

      if (pendingBookings.isEmpty) {
        print('✅ No pending payments found');
        return;
      }

      print('⚠️ Found ${pendingBookings.length} pending payment(s)');

      // Get payment config for Cashfree verification
      final paymentConfig = await PaymentUtils().getPayment();
      if (paymentConfig?.cashfree == null) {
        print('❌ Cashfree config not found, cannot verify payments');
        return;
      }

      for (var pendingBooking in pendingBookings) {
        await _processPendingBooking(pendingBooking, paymentConfig!.cashfree!);
      }
    } catch (e) {
      print('❌ Error checking pending payments: $e');
    }
  }

  static Future<void> _processPendingBooking(
    PendingBookingModel pendingBooking,
    dynamic cashfreeConfig,
  ) async {
    try {
      final orderId = pendingBooking.orderId;
      if (orderId == null || orderId.isEmpty) {
        // Invalid pending booking, delete it
        if (pendingBooking.id != null) {
          await PendingBookingUtils.deletePendingBooking(pendingBooking.id!);
        }
        return;
      }

      print('🔄 Verifying payment for order: $orderId');

      // Verify payment with Cashfree
      final verificationResult = await CashfreeVerificationUtils.verifyPayment(
        orderId: orderId,
        cashfreeConfig: cashfreeConfig,
      );

      print('📋 Verification result: ${verificationResult['order_status']}');

      if (verificationResult['is_paid'] == true) {
        // Payment was successful! Process the booking
        print('✅ Payment verified as PAID, processing booking...');

        ShowToastDialog.showLoader('Recovering your booking...');

        // Mark as processing to prevent duplicate processing
        await PendingBookingUtils.updateStatus(
            pendingBooking.id!, 'processing');

        // Process the booking using BookingPaymentController
        final success = await _processRecoveredBooking(pendingBooking);

        ShowToastDialog.closeLoader();

        if (success) {
          // Delete pending booking after successful processing
          await PendingBookingUtils.deletePendingBooking(pendingBooking.id!);
          ShowToastDialog.showToast(
              'Your booking has been recovered successfully!');

          // Navigate to success screen
          Get.to(() => const BookingSuccessScreen());
        } else {
          // Mark for manual review
          await PendingBookingUtils.updateStatus(
              pendingBooking.id!, 'recovery_failed');
          ShowToastDialog.showToast(
              'Failed to recover booking. Please contact support.');
        }
      } else {
        // Payment failed or expired - clean up
        final orderStatus = verificationResult['order_status'];
        if (orderStatus == 'EXPIRED' || orderStatus == 'TERMINATED') {
          print('🗑️ Payment expired/terminated, deleting pending booking');
          await PendingBookingUtils.deletePendingBooking(pendingBooking.id!);
        }
        // If ACTIVE, leave it as is - user might complete payment later
      }
    } catch (e) {
      print('❌ Error processing pending booking: $e');
    }
  }

  /// Process the recovered booking (similar to _processBooking in controller)
  static Future<bool> _processRecoveredBooking(
      PendingBookingModel pendingBooking) async {
    try {
      // For recovered bookings, we need to re-initialize the BookingPaymentController
      // with the pending booking data and call processBooking

      // This is a simplified recovery - in production, you may need to:
      // 1. Reload the original booking from Firestore
      // 2. Set up the controller with pending booking data
      // 3. Call the booking processing logic

      // For now, create a controller and set it up with pending data
      final controller = Get.put(BookingPaymentController());

      // Restore data from pending booking
      controller.bookingId.value = pendingBooking.bookingId ?? '';
      controller.totalAmount.value = pendingBooking.amount ?? 0.0;
      controller.selectedPaymentMethod.value =
          pendingBooking.paymentMethod ?? 'Cashfree';
      controller.isPaymentCompleted.value = true;

      if (pendingBooking.selectedSeatIndices != null) {
        controller.selectedSeatIndices.value =
            pendingBooking.selectedSeatIndices!;
      }

      if (pendingBooking.passengerNames != null) {
        controller.passengerNames.value = pendingBooking.passengerNames!
            .map((k, v) => MapEntry(int.parse(k), v));
      }

      if (pendingBooking.passengerGenders != null) {
        controller.passengerGenders.value = pendingBooking.passengerGenders!
            .map((k, v) => MapEntry(int.parse(k), v));
      }

      if (pendingBooking.passengerAges != null) {
        controller.passengerAges.value = pendingBooking.passengerAges!
            .map((k, v) => MapEntry(int.parse(k), v));
      }

      if (pendingBooking.stopOverData != null) {
        controller.stopOverModel.value =
            StopOverModel.fromJson(pendingBooking.stopOverData!);
      }

      // Wait for controller to load booking data
      await Future.delayed(const Duration(milliseconds: 500));

      // Call the internal processBooking method by using the public processBooking
      await controller
          .processBooking(pendingBooking.paymentMethod ?? 'Cashfree');

      return true;
    } catch (e) {
      print('❌ Error processing recovered booking: $e');
      return false;
    }
  }
}
