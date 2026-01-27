import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:poolmate/app/dashboard_screen.dart';
import 'package:poolmate/app/home_screen/booking_success_screen.dart';
import 'package:poolmate/app/myride/myride_screen.dart';
import 'package:poolmate/app/payment/cashfreeScreen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/send_notification.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/map/geometry.dart';
import 'package:poolmate/model/payment_method_model.dart';
import 'package:poolmate/model/pending_booking_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/services/whatsapp_service.dart';
import 'package:poolmate/utils/cashfree_verification_utils.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/booking_utils.dart';
import 'package:poolmate/utils/firestore/payment_utils.dart';
import 'package:poolmate/utils/firestore/pending_booking_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/wallet_utils.dart';
import 'package:poolmate/utils/notification_service.dart';
import 'package:poolmate/app/profile_screen/profile_screen.dart';
import 'package:poolmate/app/wallet_screen/wallet_screen.dart';

class BookingPaymentController extends GetxController {
  RxBool isLoading = true.obs;

  /// Remote payment configuration from Firestore (`payment` document).
  Rx<PaymentModel> paymentModel = PaymentModel().obs;

  /// Current user (passenger) profile (used for wallet balance + Cashfree customer details).
  Rx<UserModel> userModel = UserModel().obs;

  /// Booking (optional; used mainly for wallet transaction description).
  Rx<BookingModel> bookingModel = BookingModel().obs;

  // Arguments
  RxString bookingId = "".obs;
  RxString driverPaymentMethod = "".obs;

  // Amount summary (displayed on `BookingPaymentScreen`)
  RxInt numberOfSeats = 0.obs;
  RxDouble pricePerSeat = 0.0.obs;
  RxDouble totalAmount = 0.0.obs;

  // Wallet display / validation
  RxDouble walletBalance = 0.0.obs;

  // Selection (expected values: "Wallet" | "Cashfree")
  RxBool isPaymentCompleted = false.obs;
  RxString selectedPaymentMethod = "".obs;

  // Booking data needed for processing
  RxList<int> selectedSeatIndices = <int>[].obs;
  RxMap<int, String?> passengerNames = <int, String?>{}.obs;
  RxMap<int, String?> passengerGenders = <int, String?>{}.obs; // Male/Female
  RxMap<int, int?> passengerAges = <int, int?>{}.obs;
  Rx<StopOverModel> stopOverModel = StopOverModel().obs;

  @override
  void onInit() {
    _readArguments();
    _loadData();
    super.onInit();
  }

  void _readArguments() {
    final args = Get.arguments;
    if (args == null) return;

    numberOfSeats.value =
        int.tryParse(args["numberOfSeats"]?.toString() ?? "") ??
            (args["numberOfSeats"] is int ? args["numberOfSeats"] as int : 0);

    pricePerSeat.value =
        double.tryParse(args["pricePerSeat"]?.toString() ?? "") ?? 0.0;
    totalAmount.value =
        double.tryParse(args["totalAmount"]?.toString() ?? "") ?? 0.0;

    bookingId.value = args["bookingId"]?.toString() ?? "";
    driverPaymentMethod.value = args["driverPaymentMethod"]?.toString() ?? "";

    // Read booking-specific data
    if (args["selectedSeatIndices"] != null) {
      if (args["selectedSeatIndices"] is List) {
        selectedSeatIndices.value =
            (args["selectedSeatIndices"] as List).map((e) => e as int).toList();
      }
    }

    if (args["passengerNames"] != null) {
      if (args["passengerNames"] is Map) {
        final Map<dynamic, dynamic> names = args["passengerNames"];
        passengerNames.value = names.map(
          (key, value) => MapEntry(
            key is int ? key : int.parse(key.toString()),
            value as String?,
          ),
        );
      }
    }

    if (args["stopOverModel"] != null &&
        args["stopOverModel"] is StopOverModel) {
      stopOverModel.value = args["stopOverModel"] as StopOverModel;
    }
  }

  Future<void> _loadData() async {
    try {
      isLoading.value = true;
      update();

      // 1) Current user
      final currentUser =
          await UserUtils.getUserProfile(AuthUtils.getCurrentUid());
      if (currentUser != null) {
        userModel.value = currentUser;
        walletBalance.value =
            double.tryParse(currentUser.walletAmount?.toString() ?? "0") ?? 0.0;
      }

      // 2) Payment config
      final payment = await PaymentUtils().getPayment();
      if (payment != null) {
        paymentModel.value = payment;
      }

      // 3) Booking (optional)
      if (bookingId.value.isNotEmpty) {
        final booking =
            await BookingUtils.getMyBookingByUserId(bookingId.value);
        if (booking != null) {
          bookingModel.value = booking;
        }
      }
    } catch (e) {
      // Keep screen usable even if some data fails
      ShowToastDialog.showToast("Failed to load payment data: $e");
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> processPayment(BuildContext context) async {
    if (selectedPaymentMethod.value.isEmpty) return;

    // Enforce wallet sufficiency (UI also disables selection but keep a hard check).
    if (selectedPaymentMethod.value == "Wallet" &&
        walletBalance.value < totalAmount.value) {
      ShowToastDialog.showToast("Insufficient wallet balance".tr);
      return;
    }

    if (selectedPaymentMethod.value == "Wallet") {
      await _processWalletPayment();
      return;
    }

    if (selectedPaymentMethod.value == "Cashfree") {
      await _processCashfreePayment(context);
      return;
    }

    ShowToastDialog.showToast("Please select payment method".tr);
  }

  Future<void> _processWalletPayment() async {
    try {
      ShowToastDialog.showLoader("Processing payment...");

      final description = (bookingModel.value.pickUpAddress != null ||
              bookingModel.value.dropAddress != null)
          ? "Ride booking payment - ${bookingModel.value.pickUpAddress ?? 'Pickup'} to ${bookingModel.value.dropAddress ?? 'Drop'}"
          : "Ride booking payment";

      final result = await WalletUtils.deductFromUserWallet(
        amount: totalAmount.value.toString(),
        userId: AuthUtils.getCurrentUid(),
        description: description,
      );

      ShowToastDialog.closeLoader();

      if (result["success"] == true) {
        // Update local balance for UI (if user comes back).
        final newBalance = result["newBalance"];
        if (newBalance is num) {
          walletBalance.value = newBalance.toDouble();
        }

        // Process booking and redirect to MyRideScreen
        selectedPaymentMethod.value = "Wallet";
        isPaymentCompleted.value = true;
        bool success = await _processBooking();
        if (success) {
          ShowToastDialog.closeLoader();
          Get.until((route) => route.isFirst);
          Get.to(() => const BookingSuccessScreen());
        }
      } else {
        ShowToastDialog.showToast(
            result["message"]?.toString() ?? "Payment failed");
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Payment failed: $e");
    } finally {
      update();
    }
  }

  // Current pending booking ID for cleanup on failure
  String? _currentPendingBookingId;

  Future<void> _processCashfreePayment(BuildContext context) async {
    try {
      // Validate config
      if (paymentModel.value.cashfree == null ||
          paymentModel.value.cashfree!.enable != true) {
        ShowToastDialog.showToast("Cashfree payment is not available.");
        return;
      }

      ShowToastDialog.showLoader("Creating payment session...");
      final sessionData = await _createCashfreePaymentSession(
          amount: totalAmount.value.toString());
      ShowToastDialog.closeLoader();

      if (sessionData == null || sessionData["payment_session_id"] == null) {
        ShowToastDialog.showToast(
            "Failed to create payment session. Please try again.");
        return;
      }

      final String orderId = sessionData["order_id"].toString();
      print("sessionData: $sessionData");

      // ✅ STEP 1: Create pending booking BEFORE opening SDK
      ShowToastDialog.showLoader("Preparing payment...");
      final pendingBookingId = await _createPendingBooking(orderId);
      ShowToastDialog.closeLoader();

      if (pendingBookingId == null) {
        ShowToastDialog.showToast(
            "Failed to prepare payment. Please try again.");
        return;
      }
      _currentPendingBookingId = pendingBookingId;

      print("Navigating to CashfreeScreen...");
      await Get.to<bool>(() => CashfreeScreen(
            orderId: orderId,
            paymentSessionId: sessionData["payment_session_id"],
            paymentUrl: sessionData["payment_url"],
            isSandbox: sessionData["is_sandbox"] ?? true,
            onPaymentResult: (bool sdkPaymentSuccess) async {
              if (sdkPaymentSuccess) {
                // ✅ STEP 2: Verify payment via GET API before processing
                ShowToastDialog.showLoader("Verifying payment...");
                final verificationResult =
                    await _verifyPaymentWithCashfree(orderId);
                ShowToastDialog.closeLoader();

                if (verificationResult['is_paid'] == true) {
                  ShowToastDialog.showToast("Payment Verified!");

                  // ✅ STEP 3: Process booking only after server verification
                  selectedPaymentMethod.value = "Cashfree";
                  isPaymentCompleted.value = true;
                  bool bookingSuccess = await _processBooking();

                  if (bookingSuccess) {
                    // ✅ STEP 4: Delete pending booking after successful processing
                    await _deletePendingBooking(orderId);
                    ShowToastDialog.closeLoader();
                    Get.until((route) => route.isFirst);
                    Get.to(() => const BookingSuccessScreen());
                  }
                } else {
                  // Payment verification failed - SDK said success but server says no
                  ShowToastDialog.showToast(
                      "Payment verification failed. Please contact support.");
                  await PendingBookingUtils.updateStatus(
                      pendingBookingId, 'verification_failed');
                }
              } else {
                // Payment was cancelled or failed - clean up pending booking
                ShowToastDialog.showToast("Payment cancelled or failed");
                await _deletePendingBooking(orderId);
              }
            },
          ));
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Payment failed: $e");
      // Clean up pending booking on error
      if (_currentPendingBookingId != null) {
        await PendingBookingUtils.deletePendingBooking(
            _currentPendingBookingId!);
      }
      Get.back(result: {
        "paymentType": "Cashfree",
        "paymentSuccess": false,
      });
    }
  }

  /// Create a pending booking record before payment initiation
  Future<String?> _createPendingBooking(String orderId) async {
    try {
      final pendingBooking = PendingBookingModel(
        userId: AuthUtils.getCurrentUid(),
        orderId: orderId,
        bookingId: bookingModel.value.id,
        amount: totalAmount.value,
        status: 'pending',
        createdAt: Timestamp.now(),
        selectedSeatIndices: selectedSeatIndices.toList(),
        passengerNames: passengerNames.map((k, v) => MapEntry(k.toString(), v)),
        passengerGenders:
            passengerGenders.map((k, v) => MapEntry(k.toString(), v)),
        passengerAges: passengerAges.map((k, v) => MapEntry(k.toString(), v)),
        stopOverData: stopOverModel.value.toJson(),
        pricePerSeat: getCorrectPrice(),
        paymentMethod: 'Cashfree',
      );

      return await PendingBookingUtils.createPendingBooking(pendingBooking);
    } catch (e) {
      print('Error creating pending booking: $e');
      return null;
    }
  }

  /// Verify payment with Cashfree GET /pg/orders API
  Future<Map<String, dynamic>> _verifyPaymentWithCashfree(
      String orderId) async {
    try {
      return await CashfreeVerificationUtils.verifyPayment(
        orderId: orderId,
        cashfreeConfig: paymentModel.value.cashfree!,
      );
    } catch (e) {
      print('Error verifying payment: $e');
      return {'success': false, 'is_paid': false, 'message': e.toString()};
    }
  }

  /// Delete pending booking after successful processing or failure
  Future<void> _deletePendingBooking(String orderId) async {
    try {
      await PendingBookingUtils.deletePendingBookingByOrderId(orderId);
      _currentPendingBookingId = null;
    } catch (e) {
      print('Error deleting pending booking: $e');
    }
  }

  Future<Map<String, dynamic>?> _createCashfreePaymentSession(
      {required String amount}) async {
    try {
      final String orderId = DateTime.now().millisecondsSinceEpoch.toString();

      final bool isSandbox = paymentModel.value.cashfree!.isSandbox ?? true;

      final String cashfreeApiUrl = isSandbox
          ? 'https://sandbox.cashfree.com/pg/orders'
          : 'https://api.cashfree.com/pg/orders';

      // Choose credentials based on environment
      late final String clientId;
      late final String clientSecret;

      if (isSandbox) {
        // SANDBOX: use hardcoded test credentials (as in SelectPaymentMethodController)
        clientId = '22299146f982141989bf1c09f3199222';
        clientSecret = 'e5048e944dee7d5f6af2843fdb35570e6f38372b';
      } else {
        if (paymentModel.value.cashfree?.clientId == null ||
            paymentModel.value.cashfree?.clientSecret == null) {
          return null;
        }
        clientId = paymentModel.value.cashfree!.clientId!;
        clientSecret = paymentModel.value.cashfree!.clientSecret!;
      }

      final response = await http.post(
        Uri.parse(cashfreeApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Client-Id': clientId,
          'X-Client-Secret': clientSecret,
          'x-api-version': '2023-08-01',
        },
        body: jsonEncode({
          "order_amount": double.tryParse(amount) ?? 0.0,
          "order_currency": "INR",
          "order_id": orderId,
          "customer_details": {
            "customer_id": userModel.value.id ??
                'customer_${DateTime.now().millisecondsSinceEpoch}',
            "customer_name": userModel.value.fullName(),
            "customer_email": userModel.value.email ?? 'test@example.com',
            "customer_phone": userModel.value.phoneNumber ?? '9999999999',
          },
          "order_meta": {},
          "order_note": "Ride booking payment via Cashfree",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String? paymentSessionId = data['payment_session_id'];
        final String? cfOrderId = data['cf_order_id']?.toString();
        final String? orderIdFromResponse = data['order_id']?.toString();

        if (paymentSessionId == null || cfOrderId == null) return null;

        final String paymentUrl = isSandbox
            ? 'https://sandbox.cashfree.com/pg/view/order/$cfOrderId'
            : 'https://api.cashfree.com/pg/view/order/$cfOrderId';

        return {
          'payment_session_id': paymentSessionId,
          'order_id': orderIdFromResponse ?? orderId,
          'cf_order_id': cfOrderId,
          'payment_url': paymentUrl,
          'order_amount': data['order_amount'],
          'order_currency': data['order_currency'],
          'is_sandbox': isSandbox,
        };
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // Complete booking processing method
  Future<void> processBooking(String paymentMethod) async {
    selectedPaymentMethod.value = paymentMethod;
    bool success = await _processBooking();
    if (success) {
      Get.offAll(() => DashBoardScreen());
      print("navigated to motherboard");
    }
  }

  // Internal booking processing method
  // Calculate correct price based on route
  double getCorrectPrice() {
    // First check if it's a full route
    if (_isFullRouteBooking()) {
      return double.tryParse(bookingModel.value.pricePerSeat ?? '0') ?? 0.0;
    }

    // Check if this stopOverModel matches any of the preset stopovers in stopOverList
    final stopOverList = bookingModel.value.stopOverList;
    if (stopOverList != null && stopOverList.isNotEmpty) {
      final stopOverStartLat = stopOverModel.value.startLocation?.lat;
      final stopOverStartLng = stopOverModel.value.startLocation?.lng;
      final stopOverEndLat = stopOverModel.value.endLocation?.lat;
      final stopOverEndLng = stopOverModel.value.endLocation?.lng;

      if (stopOverStartLat != null &&
          stopOverStartLng != null &&
          stopOverEndLat != null &&
          stopOverEndLng != null) {
        // Find matching preset stopover
        for (var presetStopOver in stopOverList) {
          final presetStartLat = presetStopOver.startLocation?.lat;
          final presetStartLng = presetStopOver.startLocation?.lng;
          final presetEndLat = presetStopOver.endLocation?.lat;
          final presetEndLng = presetStopOver.endLocation?.lng;

          if (presetStartLat != null &&
              presetStartLng != null &&
              presetEndLat != null &&
              presetEndLng != null) {
            // Check if locations match (within small tolerance)
            bool startMatches =
                (presetStartLat - stopOverStartLat).abs() < 0.001 &&
                    (presetStartLng - stopOverStartLng).abs() < 0.001;
            bool endMatches = (presetEndLat - stopOverEndLat).abs() < 0.001 &&
                (presetEndLng - stopOverEndLng).abs() < 0.001;

            if (startMatches && endMatches) {
              // Found matching preset stopover, use its price (not recommendedPrice)
              return double.tryParse(presetStopOver.price ?? '0') ?? 0.0;
            }
          }
        }
      }
    }

    // No matching preset found, use the calculated stopOverModel price
    return double.tryParse(stopOverModel.value.price ?? '0') ?? 0.0;
  }

  bool _isFullRouteBooking() {
    // Get the main booking pickup and drop locations
    final bookingPickupLat =
        bookingModel.value.pickupLocation?.geometry?.location?.lat;
    final bookingPickupLng =
        bookingModel.value.pickupLocation?.geometry?.location?.lng;
    final bookingDropLat =
        bookingModel.value.dropLocation?.geometry?.location?.lat;
    final bookingDropLng =
        bookingModel.value.dropLocation?.geometry?.location?.lng;

    // Get the stopOver start and end locations
    final stopOverStartLat = stopOverModel.value.startLocation?.lat;
    final stopOverStartLng = stopOverModel.value.startLocation?.lng;
    final stopOverEndLat = stopOverModel.value.endLocation?.lat;
    final stopOverEndLng = stopOverModel.value.endLocation?.lng;

    // If any location is null, default to using stopOverModel price
    if (bookingPickupLat == null ||
        bookingPickupLng == null ||
        bookingDropLat == null ||
        bookingDropLng == null ||
        stopOverStartLat == null ||
        stopOverStartLng == null ||
        stopOverEndLat == null ||
        stopOverEndLng == null) {
      return false;
    }

    // Check if stopOver start matches booking pickup (within small tolerance for floating point)
    bool startMatches = (bookingPickupLat - stopOverStartLat).abs() < 0.001 &&
        (bookingPickupLng - stopOverStartLng).abs() < 0.001;

    // Check if stopOver end matches booking drop (within small tolerance)
    bool endMatches = (bookingDropLat - stopOverEndLat).abs() < 0.001 &&
        (bookingDropLng - stopOverEndLng).abs() < 0.001;

    // It's a full route if both start and end match
    return startMatches && endMatches;
  }

  Future<bool> _processBooking() async {
    if (selectedSeatIndices.isEmpty) {
      ShowToastDialog.showToast("Please select at least one seat");
      return false;
    }

    if (selectedPaymentMethod.value.isEmpty) {
      ShowToastDialog.showToast("Please select payment method");
      return false;
    }

    isLoading.value = true;

    try {
      // Get current user
      UserModel? currentUser =
          await UserUtils.getUserProfile(AuthUtils.getCurrentUid());
      if (currentUser == null) {
        ShowToastDialog.showToast("User not found");
        return false;
      }

      // Check if ride requires verification and user is not verified
      if (bookingModel.value.onlyVerifiedPassenger == true) {
        if (currentUser.aadharVerified != true) {
          isLoading.value = false;
          _showVerificationRequiredDialog();
          return false;
        }
      }

      // Check women only requirement
      if (bookingModel.value.womenOnly == true) {
        if (currentUser.gender?.toLowerCase() != 'female' &&
            currentUser.gender?.toLowerCase() != 'woman') {
          isLoading.value = false;
          ShowToastDialog.showToast("This ride is only for women");
          return false;
        }
      }

      // Get publisher user
      UserModel? publisherUser = await UserUtils.getUserProfile(
          bookingModel.value.createdBy.toString());
      if (publisherUser == null) {
        ShowToastDialog.showToast("Driver not found");
        return false;
      }

      // Initialize lists if null
      if (bookingModel.value.bookedUserId == null) {
        bookingModel.value.bookedUserId = [];
      }

      // Add user to booked list
      bookingModel.value.bookedUserId!.add(AuthUtils.getCurrentUid());

      // Update the bookedSeat field to store the actual seat numbers
      String currentBookedSeats = bookingModel.value.bookedSeat ?? "";
      List<String> bookedSeatsList =
          currentBookedSeats.isEmpty ? [] : currentBookedSeats.split(',');

      // Add newly selected seats
      bookedSeatsList
          .addAll(selectedSeatIndices.map((index) => index.toString()));

      // Update booked seats in booking model
      bookingModel.value.bookedSeat = bookedSeatsList.join(',');

      // Create booking user model
      BookedUserModel bookingUserModel = BookedUserModel();
      bookingUserModel.id = AuthUtils.getCurrentUid();
      // Generate PNR number for this booking
      bookingUserModel.pnrNumber = Constant.generatePNR();
      // Generate 6-digit OTP for trip verification
      final String otp =
          (100000 + (DateTime.now().microsecondsSinceEpoch % 900000))
              .toString()
              .substring(0, 6);
      bookingUserModel.otp = otp;
      // Store the actual seat numbers that were booked
      bookingUserModel.bookedSeat =
          selectedSeatIndices.map((index) => index.toString()).join(',');
      // Set payment status based on payment method
      // True for wallet and successful online payments (like Cashfree), false for cash
      bookingUserModel.paymentStatus =
          selectedPaymentMethod.value.toLowerCase() == 'wallet' ||
              selectedPaymentMethod.value.toLowerCase() == 'cashfree' ||
              selectedPaymentMethod.value.toLowerCase() == 'razorpay' ||
              selectedPaymentMethod.value.toLowerCase() == 'stripe' ||
              selectedPaymentMethod.value.toLowerCase() == 'paypal' ||
              selectedPaymentMethod.value.toLowerCase() == 'paystack' ||
              selectedPaymentMethod.value.toLowerCase() == 'flutterwave' ||
              selectedPaymentMethod.value.toLowerCase() == 'payfast' ||
              selectedPaymentMethod.value.toLowerCase() == 'paytm' ||
              selectedPaymentMethod.value.toLowerCase() == 'xendit' ||
              selectedPaymentMethod.value.toLowerCase() == 'orangepay' ||
              selectedPaymentMethod.value.toLowerCase() == 'midtrans' ||
              selectedPaymentMethod.value.toLowerCase() == 'mercadopago';
      bookingUserModel.paymentType = selectedPaymentMethod.value;
      bookingUserModel.stopOver = stopOverModel.value;
      bookingUserModel.createdAt = Timestamp.now();
      // Convert CityModel to Location for BookedUserModel
      if (bookingModel.value.pickupLocation != null &&
          bookingModel.value.pickupLocation!.geometry?.location != null) {
        bookingUserModel.pickupLocation = Location(
          lat: bookingModel.value.pickupLocation!.geometry!.location!.lat,
          lng: bookingModel.value.pickupLocation!.geometry!.location!.lng,
        );
      }
      if (bookingModel.value.dropLocation != null &&
          bookingModel.value.dropLocation!.geometry?.location != null) {
        bookingUserModel.dropLocation = Location(
          lat: bookingModel.value.dropLocation!.geometry!.location!.lat,
          lng: bookingModel.value.dropLocation!.geometry!.location!.lng,
        );
      }
      bookingUserModel.adminCommission = Constant.adminCommission;
      bookingUserModel.taxList = Constant.taxList;

      // Calculate subtotal
      double pricePerSeat = getCorrectPrice();
      double totalAmount = pricePerSeat * selectedSeatIndices.length;
      bookingUserModel.subTotal = totalAmount.toString();

      // Store passenger names (convert Map<int, String?> to Map<String, String?> for Firestore)
      if (passengerNames.isNotEmpty) {
        bookingUserModel.passengerNames =
            passengerNames.map((key, value) => MapEntry(key.toString(), value));
      }

      // Store passenger genders
      if (passengerGenders.isNotEmpty) {
        bookingUserModel.passengerGenders = passengerGenders
            .map((key, value) => MapEntry(key.toString(), value));
      }

      // Store passenger ages
      if (passengerAges.isNotEmpty) {
        bookingUserModel.passengerAges =
            passengerAges.map((key, value) => MapEntry(key.toString(), value));
      }

      // Process payment if wallet is selected
      // NOTE: Only process wallet payment if it wasn't already processed in BookingPaymentScreen
      // The _isPaymentCompleted flag indicates payment was already done
      Map<String, dynamic>? paymentResult;
      if ((selectedPaymentMethod.value.toLowerCase() == 'wallet' ||
              selectedPaymentMethod.value.toLowerCase() == 'my wallet') &&
          !isPaymentCompleted.value) {
        // Payment not yet processed, deduct from wallet now
        ShowToastDialog.showLoader("Processing payment...");

        paymentResult = await WalletUtils.deductFromUserWallet(
            amount: totalAmount.toString(),
            userId: AuthUtils.getCurrentUid(),
            description:
                "Ride booking payment - ${bookingModel.value.pickUpAddress ?? 'Pickup'} to ${bookingModel.value.dropAddress ?? 'Drop'}");

        ShowToastDialog.closeLoader();

        if (paymentResult['success'] != true) {
          isLoading.value = false;

          if (paymentResult['code'] == 'INSUFFICIENT_BALANCE') {
            _showInsufficientBalanceDialog(
                required: totalAmount,
                available: paymentResult['availableBalance'] ?? 0.0);
          } else {
            ShowToastDialog.showToast(
                paymentResult['message'] ?? 'Payment failed');
          }
          return false;
        }
      }

      // Only transfer to driver and record commission if wallet payment was used
      // if (selectedPaymentMethod.value.toLowerCase() == 'wallet' ||
      //     selectedPaymentMethod.value.toLowerCase() == 'my wallet') {
      // Payment successful, now transfer money to driver after commission
      ShowToastDialog.showLoader("Transferring payment to driver...");

      // Calculate admin commission (from your Firebase settings: 10%)
      double adminCommissionRate =
          double.tryParse(Constant.adminCommission?.amount ?? '10') ?? 10.0;
      double adminCommissionAmount = (totalAmount * adminCommissionRate) / 100;
      double driverAmount = totalAmount - adminCommissionAmount;

      // Transfer money to driver's wallet
      Map<String, dynamic> driverPaymentResult =
          await WalletUtils.addToDriverWallet(
              amount: driverAmount.toString(),
              driverId: bookingModel.value.createdBy.toString(),
              bookingId: bookingModel.value.id ?? '',
              description:
                  "Ride booking payment received - ${bookingModel.value.pickUpAddress ?? 'Pickup'} to ${bookingModel.value.dropAddress ?? 'Drop'} (After $adminCommissionRate% commission)");

      // Record admin commission
      await WalletUtils.recordAdminCommission(
        amount: adminCommissionAmount.toString(),
        bookingId: bookingModel.value.id ?? '',
        description:
            "Platform commission ($adminCommissionRate%) from ride booking",
        passengerId: AuthUtils.getCurrentUid(),
        driverId: bookingModel.value.createdBy.toString(),
      );

      ShowToastDialog.closeLoader();

      if (driverPaymentResult['success'] == true) {
        ShowToastDialog.showToast(
            "Payment successful! ₹${totalAmount.toStringAsFixed(2)} paid. Driver receives ₹${driverAmount.toStringAsFixed(2)} (₹${adminCommissionAmount.toStringAsFixed(2)} platform fee)");
      } else {
        // If driver payment fails, we should ideally refund the passenger
        ShowToastDialog.showToast(
            "Payment deducted but transfer to driver failed. Contact support.");
      }
      // }

      ShowToastDialog.showLoader("Processing booking...");

      // Move seats from tempSeatSelection to bookedSeat in Firebase
      String updatedBookedSeats = "";
      if (bookingModel.value.id != null) {
        final docRef = FirebaseFirestore.instance
            .collection('booking')
            .doc(bookingModel.value.id);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);

          if (snapshot.exists) {
            final data = snapshot.data();

            // Get current temp seats
            final currentTempSeats =
                List<int>.from(data?['tempSeatSelection'] ?? []);

            // Get current booked seats
            final currentBookedSeatsString = data?['bookedSeat'] ?? "0";
            List<String> currentBookedSeatsList =
                currentBookedSeatsString.isEmpty ||
                        currentBookedSeatsString == "0"
                    ? []
                    : currentBookedSeatsString.toString().split(',');

            // Add newly selected seats to booked seats
            currentBookedSeatsList
                .addAll(selectedSeatIndices.map((index) => index.toString()));

            // Remove booked seats from temp selection
            currentTempSeats
                .removeWhere((seat) => selectedSeatIndices.contains(seat));

            // Store the updated value to sync with local model
            updatedBookedSeats = currentBookedSeatsList.join(',');

            // Update both fields in the same transaction
            transaction.update(docRef, {
              'tempSeatSelection': currentTempSeats,
              'bookedSeat': updatedBookedSeats,
              'bookedUserId': bookingModel.value.bookedUserId,
            });
          }
        });

        // Sync local model with the value written to Firestore
        // This prevents race condition where setBooking overwrites transaction
        bookingModel.value.bookedSeat = updatedBookedSeats;
      }

      // Save user booking
      await BookingUtils.setUserBooking(bookingModel.value, bookingUserModel);

      // Send notification to driver
      if (publisherUser.fcmToken != null) {
        await SendNotification.sendOneNotification(
          type: Constant.booking_confirmed,
          token: publisherUser.fcmToken.toString(),
          payload: {},
        );
      }

      // Send notification to passenger (user who booked) confirming their booking
      if (currentUser.fcmToken != null && currentUser.fcmToken!.isNotEmpty) {
        await SendNotification.sendOneNotification(
          type: Constant.booking_confirmed_by_passager,
          token: currentUser.fcmToken.toString(),
          payload: {},
        );
      }

      // Send WhatsApp notifications
      // To passenger: booking confirmed
      if (currentUser.phoneNumber != null) {
        await WhatsAppService.sendRiderBookingConfirmed(
            phoneNumber: currentUser.phoneNumber!,
            rideDetails: [
              {
                "type": "body",
                "parameters": [
                  {
                    "type": "text",
                    "text": bookingModel
                            .value.vehicleInformation?.licensePlatNumber ??
                        ''
                  },
                  {
                    "type": "text",
                    "text": bookingUserModel.pickupLocation ?? ''
                  },
                  {"type": "text", "text": bookingUserModel.dropLocation ?? ''},
                  {
                    "type": "text",
                    "text": Constant.dateCustomizationShow(
                            bookingModel.value.departureDateTime!.toDate()) ??
                        ''
                  },
                  {
                    "type": "text",
                    "text": DateFormat('hh:mm aa').format(
                            bookingModel.value.departureDateTime!.toDate()) ??
                        ''
                  },
                ]
              }
            ]);
      }

      // To driver: seat booked
      if (publisherUser.phoneNumber != null) {
        await WhatsAppService.sendDriverSeatBook(
          phoneNumber: publisherUser.phoneNumber!,
        );
      }

      // Update main booking
      await BookingUtils.setBooking(bookingModel.value);

      // Schedule local reminder for passenger (30 mins before ride)
      if (bookingModel.value.departureDateTime != null) {
        DateTime rideTime = bookingModel.value.departureDateTime!.toDate();
        DateTime scheduleTime = rideTime.subtract(const Duration(minutes: 30));

        // Generate a unique ID for notification based on booking ID hash + user ID hash (to avoid collision)
        int notificationId =
            (bookingModel.value.id.toString() + AuthUtils.getCurrentUid())
                .hashCode;

        await NotificationService.scheduleNotification(
          id: notificationId,
          title: '🚗 Ride Starting Soon!',
          body: 'Your ride from ${bookingModel.value.pickUpAddress} to '
              '${bookingModel.value.dropAddress} is about to start at '
              '${DateFormat('hh:mm a').format(rideTime)}.\n\n'
              'Please be ready and contact the driver 📞.\n\n'
              'Please remember the following points while riding:\n\n'
              '1. 🔢 Ensure the Vehicle number matches before boarding.\n'
              '2. 🔐 Share your OTP with the driver at the time of boarding.\n'
              '3. 📍 Always keep your mobile location ON during the trip.\n'
              '4. 🆘 Make sure your SOS number is updated in the app and use it in case of any emergency.\n'
              '5. ⭐ After the trip, please leave a review for the driver. Also, please share a review for the app on the Google Play Store.\n\n'
              'Happy journey 🛣️\n'
              'Bola – let’s move together 🤝',
          scheduledTime: scheduleTime,
        );
      }

      ShowToastDialog.closeLoader();

      // Show success message
      // Toast removed to prevent overlay conflict with navigation
      // ShowToastDialog.showToast("Booking confirmed successfully!");

      // Do not navigate here, let caller handle navigation
      // Get.back(result: true);
      return true;
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error processing booking: ${e.toString()}");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Show verification required dialog
  void _showVerificationRequiredDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Verification Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This ride requires verified passengers only.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Please verify yourself first by uploading your documents to book this ride.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              Get.to(() => const ProfileScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Verify Now',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Show insufficient balance dialog
  void _showInsufficientBalanceDialog({
    required double required,
    required double available,
  }) {
    double shortfall = required - available;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Insufficient Balance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You don\'t have enough balance in your wallet to book this ride.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Required amount:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '₹${required.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available balance:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '₹${available.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Need to add:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        '₹${shortfall.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Navigate to wallet screen to add money
              Get.to(() => const WalletScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Add Money',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
