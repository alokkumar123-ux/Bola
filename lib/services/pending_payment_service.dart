import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/send_notification.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/services/cashfree_verification_service.dart';
import 'package:poolmate/services/whatsapp_service.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/booking_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/preferences.dart';
import 'package:poolmate/model/map/geometry.dart';

/// Service to manage pending payments for crash recovery
/// Saves payment details before Cashfree SDK call and recovers on app restart
class PendingPaymentService {
  static const String _pendingPaymentKey = 'pending_cashfree_payment';
  static const String _pendingTopupKey = 'pending_cashfree_topup';

  /// Save pending payment data before initiating Cashfree payment
  static Future<void> savePendingPayment({
    required String orderId,
    required String bookingId,
    required StopOverModel stopOver,
    required String numberOfSeats,
    required String subTotal,
    required String paymentType,
    required Location pickupLocation,
    required Location dropLocation,
  }) async {
    try {
      Map<String, dynamic> pendingData = {
        'orderId': orderId,
        'bookingId': bookingId,
        'stopOver': jsonEncode(stopOver.toJson()),
        'numberOfSeats': numberOfSeats,
        'subTotal': subTotal,
        'paymentType': paymentType,
        'pickupLocation': jsonEncode(pickupLocation.toJson()),
        'dropLocation': jsonEncode(dropLocation.toJson()),
        'userId': AuthUtils.getCurrentUid(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      String jsonData = jsonEncode(pendingData);
      await Preferences.setString(_pendingPaymentKey, jsonData);
      print("💾 Saved pending payment for order: $orderId");
    } catch (e) {
      print("❌ Error saving pending payment: $e");
    }
  }

  /// Save pending wallet top-up before initiating Cashfree payment
  static Future<void> savePendingTopup({
    required String orderId,
    required String amount,
  }) async {
    try {
      Map<String, dynamic> pendingData = {
        'orderId': orderId,
        'amount': amount,
        'userId': AuthUtils.getCurrentUid(),
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'topup',
      };

      String jsonData = jsonEncode(pendingData);
      await Preferences.setString(_pendingTopupKey, jsonData);
      print("💾 Saved pending top-up for order: $orderId, amount: $amount");
    } catch (e) {
      print("❌ Error saving pending top-up: $e");
    }
  }

  /// Get pending payment data if exists
  static Future<PendingPaymentData?> getPendingPayment() async {
    try {
      String? jsonData = Preferences.getString(_pendingPaymentKey);
      if (jsonData.isEmpty) {
        return null;
      }

      Map<String, dynamic> data = jsonDecode(jsonData);

      // Verify the pending payment belongs to current user
      String? storedUserId = data['userId'];
      String currentUserId = AuthUtils.getCurrentUid();

      if (storedUserId != currentUserId) {
        print("⚠️ Pending payment belongs to different user, clearing");
        await clearPendingPayment();
        return null;
      }

      return PendingPaymentData.fromJson(data);
    } catch (e) {
      print("❌ Error getting pending payment: $e");
      return null;
    }
  }

  /// Get pending top-up data if exists
  static Future<PendingTopupData?> getPendingTopup() async {
    try {
      String? jsonData = Preferences.getString(_pendingTopupKey);
      if (jsonData.isEmpty) {
        return null;
      }

      Map<String, dynamic> data = jsonDecode(jsonData);

      // Verify the pending top-up belongs to current user
      String? storedUserId = data['userId'];
      String currentUserId = AuthUtils.getCurrentUid();

      if (storedUserId != currentUserId) {
        print("⚠️ Pending top-up belongs to different user, clearing");
        await clearPendingTopup();
        return null;
      }

      return PendingTopupData.fromJson(data);
    } catch (e) {
      print("❌ Error getting pending top-up: $e");
      return null;
    }
  }

  /// Clear pending payment data
  static Future<void> clearPendingPayment() async {
    try {
      await Preferences.clearKeyData(_pendingPaymentKey);
      print("🧹 Cleared pending payment");
    } catch (e) {
      print("❌ Error clearing pending payment: $e");
    }
  }

  /// Clear pending top-up data
  static Future<void> clearPendingTopup() async {
    try {
      await Preferences.clearKeyData(_pendingTopupKey);
      print("🧹 Cleared pending top-up");
    } catch (e) {
      print("❌ Error clearing pending top-up: $e");
    }
  }

  /// Check for pending payments on app startup and recover if needed
  /// Returns true if a pending payment was recovered and booking created
  static Future<bool> checkAndRecoverPendingPayments() async {
    try {
      print("🔍 Checking for pending payments...");

      PendingPaymentData? pendingPayment = await getPendingPayment();
      if (pendingPayment == null) {
        print("✅ No pending payments found");
        return false;
      }

      print("⚠️ Found pending payment for order: ${pendingPayment.orderId}");

      // Check how old the pending payment is (max 24 hours)
      DateTime createdAt = DateTime.parse(pendingPayment.createdAt);
      Duration age = DateTime.now().difference(createdAt);
      if (age.inHours > 24) {
        print("⏰ Pending payment is too old (${age.inHours}h), clearing");
        await clearPendingPayment();
        return false;
      }

      // Verify payment status with Cashfree API
      CashfreePaymentResult result =
          await CashfreeVerificationService.verifyPayment(
              pendingPayment.orderId);

      if (result.isVerified) {
        print("✅ Payment verified, checking if booking exists...");

        // Check if booking was already created
        bool bookingExists = await _checkIfBookingExists(
          pendingPayment.bookingId,
          pendingPayment.userId,
        );

        if (bookingExists) {
          print("✅ Booking already exists, clearing pending payment");
          await clearPendingPayment();
          return false;
        }

        print("🚀 Creating booking from recovered payment...");

        // Create the booking
        bool bookingCreated = await _createBookingFromPendingPayment(
          pendingPayment,
          result,
        );

        if (bookingCreated) {
          await clearPendingPayment();
          ShowToastDialog.showToast(
              "Your previous payment was successful! Booking has been created.");
          return true;
        } else {
          print("❌ Failed to create booking from recovered payment");
          return false;
        }
      } else if (result.isPending) {
        print("⏳ Payment is still pending, will check again later");
        // Don't clear, will retry on next app open
        return false;
      } else {
        print("❌ Payment failed or expired: ${result.errorMessage}");
        await clearPendingPayment();
        return false;
      }
    } catch (e) {
      print("❌ Error recovering pending payment: $e");
      return false;
    }
  }

  /// Check for pending top-ups on app startup and recover if needed
  /// Returns the verified top-up amount if recovered, null otherwise
  static Future<double?> checkAndRecoverPendingTopups() async {
    try {
      print("🔍 Checking for pending top-ups...");

      PendingTopupData? pendingTopup = await getPendingTopup();
      if (pendingTopup == null) {
        print("✅ No pending top-ups found");
        return null;
      }

      print(
          "⚠️ Found pending top-up for order: ${pendingTopup.orderId}, amount: ${pendingTopup.amount}");

      // Check how old the pending top-up is (max 24 hours)
      DateTime createdAt = DateTime.parse(pendingTopup.createdAt);
      Duration age = DateTime.now().difference(createdAt);
      if (age.inHours > 24) {
        print("⏰ Pending top-up is too old (${age.inHours}h), clearing");
        await clearPendingTopup();
        return null;
      }

      // Verify payment status with Cashfree API
      CashfreePaymentResult result =
          await CashfreeVerificationService.verifyPayment(pendingTopup.orderId);

      if (result.isVerified) {
        print("✅ Top-up payment verified, crediting wallet...");

        double amount = double.tryParse(pendingTopup.amount) ?? 0;
        if (amount > 0) {
          // Credit the wallet
          await _creditWalletFromTopup(
              pendingTopup.userId, amount, pendingTopup.orderId);
          await clearPendingTopup();
          ShowToastDialog.showToast(
              "Your previous top-up of ${Constant.amountShow(amount: pendingTopup.amount)} was successful!");
          return amount;
        }
      } else if (result.isPending) {
        print("⏳ Top-up payment is still pending, will check again later");
        // Don't clear, will retry on next app open
        return null;
      } else {
        print("❌ Top-up payment failed or expired: ${result.errorMessage}");
        await clearPendingTopup();
        return null;
      }
    } catch (e) {
      print("❌ Error recovering pending top-up: $e");
    }
    return null;
  }

  /// Credit wallet from recovered top-up
  static Future<void> _creditWalletFromTopup(
      String userId, double amount, String orderId) async {
    try {
      // Get current user
      UserModel? user = await UserUtils.getUserProfile(userId);
      if (user == null) {
        print("❌ User not found for wallet credit");
        return;
      }

      // Calculate new balance
      double currentBalance = double.tryParse(user.walletAmount ?? "0") ?? 0;
      double newBalance = currentBalance + amount;

      // Update wallet balance
      await AuthUtils.fireStore
          .collection(CollectionName.users)
          .doc(userId)
          .update({'walletAmount': newBalance.toString()});

      // Record wallet transaction
      await AuthUtils.fireStore
          .collection(CollectionName.users)
          .doc(userId)
          .collection('wallet_transactions')
          .add({
        'amount': amount,
        'type': 'credit',
        'description': 'Wallet top-up via Cashfree (recovered)',
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'balanceAfter': newBalance,
      });

      print("✅ Wallet credited with ₹$amount, new balance: ₹$newBalance");
    } catch (e) {
      print("❌ Error crediting wallet: $e");
    }
  }

  /// Check if booking was already created for this user
  static Future<bool> _checkIfBookingExists(
      String bookingId, String userId) async {
    try {
      DocumentSnapshot doc = await AuthUtils.fireStore
          .collection(CollectionName.booking)
          .doc(bookingId)
          .collection("bookedUser")
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      print("❌ Error checking booking existence: $e");
      return false;
    }
  }

  /// Create booking from pending payment data
  static Future<bool> _createBookingFromPendingPayment(
    PendingPaymentData pendingPayment,
    CashfreePaymentResult paymentResult,
  ) async {
    try {
      // Get booking model
      BookingModel? bookingModel =
          await BookingUtils.getMyBookingByUserId(pendingPayment.bookingId);
      if (bookingModel == null) {
        print("❌ Booking not found: ${pendingPayment.bookingId}");
        return false;
      }

      // Get user models
      UserModel? currentUser =
          await UserUtils.getUserProfile(pendingPayment.userId);
      UserModel? driverUser =
          await UserUtils.getUserProfile(bookingModel.createdBy!);

      if (currentUser == null) {
        print("❌ Current user not found");
        return false;
      }

      // Update booking with user ID
      if (!bookingModel.bookedUserId!.contains(pendingPayment.userId)) {
        bookingModel.bookedUserId!.add(pendingPayment.userId);
      }
      int totalSeats = int.tryParse(bookingModel.totalSeat ?? "4") ?? 4;
      int seatsNeeded = int.tryParse(pendingPayment.numberOfSeats) ?? 1;

      bookingModel.bookedSeat = BookingUtils.allocateSeats(
        bookingModel.bookedSeat,
        seatsNeeded,
        totalSeats,
      );

      // Create booked user model
      BookedUserModel bookingUserModel = BookedUserModel();
      bookingUserModel.id = pendingPayment.userId;
      bookingUserModel.bookedSeat = pendingPayment.numberOfSeats;
      bookingUserModel.paymentStatus = true; // Payment is verified
      bookingUserModel.paymentType = pendingPayment.paymentType;
      bookingUserModel.stopOver = pendingPayment.stopOver;
      bookingUserModel.createdAt = Timestamp.now();
      bookingUserModel.pickupLocation = pendingPayment.pickupLocation;
      bookingUserModel.dropLocation = pendingPayment.dropLocation;
      bookingUserModel.adminCommission = Constant.adminCommission;
      bookingUserModel.taxList = Constant.taxList;
      bookingUserModel.subTotal = pendingPayment.subTotal;

      // Add Cashfree payment details
      bookingUserModel.cashfreeOrderId = paymentResult.orderId;
      bookingUserModel.cashfreePaymentId = paymentResult.cfPaymentId;
      bookingUserModel.bankReference = paymentResult.bankReference;
      bookingUserModel.paymentVerified = true;
      bookingUserModel.paymentVerifiedAt = Timestamp.now();

      // Save booking
      await BookingUtils.setUserBooking(bookingModel, bookingUserModel);

      // Send notifications
      if (driverUser != null && driverUser.fcmToken != null) {
        await SendNotification.sendOneNotification(
          type: Constant.booking_confirmed,
          token: driverUser.fcmToken!,
          payload: {},
        );
      }

      if (currentUser.fcmToken != null) {
        await SendNotification.sendOneNotification(
          type: Constant.booking_confirmed,
          token: currentUser.fcmToken!,
          payload: {},
        );
      }

      // Send WhatsApp notifications
      if (currentUser.phoneNumber != null) {
        await WhatsAppService.sendRiderBookingConfirmed(
          phoneNumber: currentUser.phoneNumber!,
        );
      }

      if (driverUser != null && driverUser.phoneNumber != null) {
        await WhatsAppService.sendDriverSeatBook(
          phoneNumber: driverUser.phoneNumber!,
        );
      }

      await BookingUtils.setBooking(bookingModel);

      print("✅ Booking created from recovered payment!");
      return true;
    } catch (e) {
      print("❌ Error creating booking from pending payment: $e");
      return false;
    }
  }
}

/// Data class for pending payment
class PendingPaymentData {
  final String orderId;
  final String bookingId;
  final StopOverModel stopOver;
  final String numberOfSeats;
  final String subTotal;
  final String paymentType;
  final Location pickupLocation;
  final Location dropLocation;
  final String userId;
  final String createdAt;

  PendingPaymentData({
    required this.orderId,
    required this.bookingId,
    required this.stopOver,
    required this.numberOfSeats,
    required this.subTotal,
    required this.paymentType,
    required this.pickupLocation,
    required this.dropLocation,
    required this.userId,
    required this.createdAt,
  });

  factory PendingPaymentData.fromJson(Map<String, dynamic> json) {
    return PendingPaymentData(
      orderId: json['orderId'],
      bookingId: json['bookingId'],
      stopOver: StopOverModel.fromJson(jsonDecode(json['stopOver'])),
      numberOfSeats: json['numberOfSeats'],
      subTotal: json['subTotal'],
      paymentType: json['paymentType'],
      pickupLocation: Location.fromJson(jsonDecode(json['pickupLocation'])),
      dropLocation: Location.fromJson(jsonDecode(json['dropLocation'])),
      userId: json['userId'],
      createdAt: json['createdAt'],
    );
  }
}

/// Data class for pending wallet top-up
class PendingTopupData {
  final String orderId;
  final String amount;
  final String userId;
  final String createdAt;

  PendingTopupData({
    required this.orderId,
    required this.amount,
    required this.userId,
    required this.createdAt,
  });

  factory PendingTopupData.fromJson(Map<String, dynamic> json) {
    return PendingTopupData(
      orderId: json['orderId'],
      amount: json['amount'],
      userId: json['userId'],
      createdAt: json['createdAt'],
    );
  }
}
