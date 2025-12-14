import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:poolmate/app/payment/cashfreeScreen.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/payment_method_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/payment_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/wallet_utils.dart';

class BookingPaymentController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<PaymentModel> paymentModel = PaymentModel().obs;
  RxString selectedPaymentMethod = "".obs;
  RxDouble walletBalance = 0.0.obs;

  // Booking details
  RxInt numberOfSeats = 0.obs;
  RxDouble pricePerSeat = 0.0.obs;
  RxDouble totalAmount = 0.0.obs;
  String bookingId = "";
  String driverPaymentMethod = "";

  @override
  void onInit() {
    super.onInit();
    getArguments();
    getPaymentData();
    getUserWalletBalance();
  }

  void getArguments() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      numberOfSeats.value = argumentData['numberOfSeats'] ?? 0;
      pricePerSeat.value = double.parse(argumentData['pricePerSeat'] ?? '0');
      totalAmount.value = double.parse(argumentData['totalAmount'] ?? '0');
      bookingId = argumentData['bookingId'] ?? '';
      driverPaymentMethod = argumentData['driverPaymentMethod'] ?? '';
    }
  }

  Future<void> getPaymentData() async {
    await PaymentUtils().getPayment().then((value) {
      if (value != null) {
        paymentModel.value = value;
      }
    });
    isLoading.value = false;
    update();
  }

  Future<void> getUserWalletBalance() async {
    await UserUtils.getUserProfile(AuthUtils.getCurrentUid()).then((value) {
      if (value != null) {
        walletBalance.value = double.parse(value.walletAmount ?? '0');
      }
    });
    update();
  }

  Future<void> processPayment(BuildContext context) async {
    if (selectedPaymentMethod.value.isEmpty) {
      ShowToastDialog.showToast("Please select a payment method");
      return;
    }

    // Handle Cash payment
    if (selectedPaymentMethod.value == "Cash") {
      _processCashPayment();
      return;
    }

    // Handle Wallet payment
    if (selectedPaymentMethod.value == "Wallet") {
      await _processWalletPayment();
      return;
    }

    // Handle Cashfree payment
    if (selectedPaymentMethod.value == "Cashfree" ||
        selectedPaymentMethod.value == paymentModel.value.cashfree?.name) {
      await _processCashfreePayment(context);
      return;
    }
    // Add other payment methods here as needed
  }

  void _processCashPayment() {
    // For cash payment, just return success without actual payment processing
    log("Cash payment selected - returning success");
    ShowToastDialog.showToast("Cash payment selected");
    Get.back(result: {"paymentType": "Cash", "paymentSuccess": true});
  }

  Future<void> _processWalletPayment() async {
    // Check if wallet has sufficient balance
    if (walletBalance.value < totalAmount.value) {
      ShowToastDialog.showToast(
          "Insufficient wallet balance. Please top up your wallet.");
      return;
    }

    ShowToastDialog.showLoader("Processing wallet payment...");

    try {
      // Use the proper wallet deduction function that creates transaction records
      Map<String, dynamic> deductResult =
          await WalletUtils.deductFromUserWallet(
              amount: totalAmount.value.toString(),
              userId: AuthUtils.getCurrentUid(),
              description: "Ride booking payment - Booking ID: $bookingId");

      ShowToastDialog.closeLoader();

      if (deductResult['success'] == true) {
        log("Wallet payment successful - balance deducted");
        ShowToastDialog.showToast("Payment successful!");
        Get.back(result: {"paymentType": "Wallet", "paymentSuccess": true});
      } else {
        ShowToastDialog.showToast(
            deductResult['message'] ?? "Payment failed. Please try again.");
        Get.back(result: {"paymentType": "Wallet", "paymentSuccess": false});
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      log("Wallet payment error: $e");
      ShowToastDialog.showToast("Payment failed: $e");
      Get.back(result: {"paymentType": "Wallet", "paymentSuccess": false});
    }
  }

  Future<void> _processCashfreePayment(BuildContext context) async {
    try {
      // Check if Cashfree is configured and enabled
      if (paymentModel.value.cashfree == null) {
        ShowToastDialog.showToast("Cashfree payment is not configured.");
        Get.back(result: {
          "paymentType": selectedPaymentMethod.value,
          "paymentSuccess": false
        });
        return;
      }

      if (paymentModel.value.cashfree!.enable != true) {
        ShowToastDialog.showToast("Cashfree payment is not enabled.");
        Get.back(result: {
          "paymentType": selectedPaymentMethod.value,
          "paymentSuccess": false
        });
        return;
      }

      ShowToastDialog.showLoader("Creating payment session...");

      // Create payment session using the existing method
      Map<String, dynamic>? sessionData =
          await _createCashfreePaymentSession(totalAmount.value.toString());
      ShowToastDialog.closeLoader();

      if (sessionData != null && sessionData['payment_session_id'] != null) {
        // Import CashfreeScreen
        final result = await Get.to(() => CashfreeScreen(
              orderId: sessionData['order_id'].toString(),
              paymentSessionId: sessionData['payment_session_id'],
              paymentUrl: sessionData['payment_url'],
              isSandbox: sessionData['is_sandbox'] ?? true,
              onPaymentResult: (success) {},
            ));

        log("Cashfree payment result: $result");

        // Close this payment screen and return result
        if (result == true) {
          log("Payment successful - auto-proceeding with booking");
          ShowToastDialog.showToast("Payment Successful!!");
          Get.back(result: {
            "paymentType": selectedPaymentMethod.value,
            "paymentSuccess": true
          });
        } else {
          log("Payment failed or cancelled");
          ShowToastDialog.showToast("Payment cancelled or failed");
          Get.back(result: {
            "paymentType": selectedPaymentMethod.value,
            "paymentSuccess": false
          });
        }
      } else {
        ShowToastDialog.showToast(
            "Failed to create payment session. Please try again.");
        Get.back(result: {
          "paymentType": selectedPaymentMethod.value,
          "paymentSuccess": false
        });
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      log("Cashfree payment error: $e");
      ShowToastDialog.showToast("Payment failed: $e");
      Get.back(result: {
        "paymentType": selectedPaymentMethod.value,
        "paymentSuccess": false
      });
    }
  }

  Future<Map<String, dynamic>?> _createCashfreePaymentSession(
      String amount) async {
    try {
      final String orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // Get user data
      final userModel =
          await UserUtils.getUserProfile(AuthUtils.getCurrentUid());

      if (userModel == null) {
        log("User model is null");
        return null;
      }

      // Use sandbox or production based on Firebase configuration
      bool isSandbox = paymentModel.value.cashfree!.isSandbox ?? true;

      String cashfreeApiUrl = isSandbox
          ? 'https://sandbox.cashfree.com/pg/orders'
          : 'https://api.cashfree.com/pg/orders';

      log("Using Cashfree API URL: $cashfreeApiUrl");
      log("Environment: ${isSandbox ? 'SANDBOX' : 'PRODUCTION'}");

      // Choose credentials based on environment
      String clientId;
      String clientSecret;

      if (isSandbox) {
        // SANDBOX: Use hardcoded test credentials
        clientId = '22299146f982141989bf1c09f3199222';
        clientSecret = 'e5048e944dee7d5f6af2843fdb35570e6f38372b';
        log("Using SANDBOX credentials (hardcoded)");
      } else {
        // PRODUCTION: Use credentials from Firebase
        if (paymentModel.value.cashfree?.clientId == null ||
            paymentModel.value.cashfree?.clientSecret == null) {
          log("Cashfree production API keys not configured in Firebase");
          return null;
        }
        clientId = paymentModel.value.cashfree!.clientId!;
        clientSecret = paymentModel.value.cashfree!.clientSecret!;
        log("Using PRODUCTION credentials from Firebase");
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
          "order_amount": double.parse(amount),
          "order_currency": "INR",
          "order_id": orderId,
          "customer_details": {
            "customer_id": userModel.id ??
                'test_customer_${DateTime.now().millisecondsSinceEpoch}',
            "customer_name": userModel.fullName(),
            "customer_email": userModel.email ?? 'test@example.com',
            "customer_phone": userModel.phoneNumber ?? '9999999999',
          },
          "order_meta": {
            "return_url": "https://your-app.com/cashfree/success",
            "cancel_url": "https://your-app.com/cashfree/cancel",
          },
          "order_note": "Booking payment via Cashfree",
        }),
      );

      log("Cashfree Payment Session Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        log("Cashfree Payment Data: $data");

        String? paymentSessionId = data['payment_session_id'];
        String? cfOrderId = data['cf_order_id']?.toString();
        String? orderIdFromResponse = data['order_id']?.toString();

        if (paymentSessionId != null && cfOrderId != null) {
          String paymentUrl = isSandbox
              ? 'https://sandbox.cashfree.com/pg/view/order/$cfOrderId'
              : 'https://api.cashfree.com/pg/view/order/$cfOrderId';

          Map<String, dynamic> sessionData = {
            'payment_session_id': paymentSessionId,
            'order_id': orderIdFromResponse ?? orderId,
            'cf_order_id': cfOrderId,
            'payment_url': paymentUrl,
            'order_amount': data['order_amount'],
            'order_currency': data['order_currency'],
            'is_sandbox': isSandbox,
          };

          log("Generated Cashfree Session Data: $sessionData");
          return sessionData;
        } else {
          log("Missing payment_session_id or cf_order_id in response");
          return null;
        }
      } else {
        log("Failed to create Cashfree payment session: ${response.statusCode}");
        log("Error response: ${response.body}");
        return null;
      }
    } catch (e) {
      log("Error creating Cashfree payment session: $e");
      return null;
    }
  }
}
