import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/payment/cashfreeScreen.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/payment_method_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/firestore/payment_utils.dart';
import 'package:http/http.dart' as http;
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';

class SelectPaymentMethodController extends GetxController {
  Rx<PaymentModel> paymentModel = PaymentModel().obs;

  RxBool isLoading = true.obs;
  RxString selectedPaymentMethod = "".obs;
  RxString bookingId = "".obs;
  RxString type = "wallet".obs;
  RxString driverPaymentMethod = "".obs;

  Rx<TextEditingController> amountController = TextEditingController().obs;

  @override
  void onInit() {
    getPaymentData();
    getArgument();
    super.onInit();
  }

  getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      if (argumentData['amount'] != null) {
        amountController.value.text = argumentData['amount'];
      }
      if (argumentData['selectedPaymentMethod'] != null) {
        selectedPaymentMethod.value = argumentData['selectedPaymentMethod'];
      }
      if (argumentData['bookingId'] != null) {
        bookingId.value = argumentData['bookingId'];
      }
      if (argumentData['driverPaymentMethod'] != null) {
        driverPaymentMethod.value = argumentData['driverPaymentMethod'];
      }
      type.value = argumentData['type'];
    }
  }

  Rx<UserModel> userModel = UserModel().obs;

  walletTopUp() async {
    Get.back(result: {
      "amount": amountController.value.text,
      "paymentType": selectedPaymentMethod.value
    });
  }

  getPaymentData() async {
    await UserUtils.getUserProfile(AuthUtils.getCurrentUid()).then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });

    await PaymentUtils().getPayment().then((value) {
      if (value != null) {
        paymentModel.value = value;
      }
    });
    isLoading.value = false;
    update();
  }

  // Cashfree Payment Integration
  Future<void> cashfreePayment(
      {required BuildContext context, required String amount}) async {
    try {
      // Check if Cashfree is configured and enabled
      if (paymentModel.value.cashfree == null) {
        ShowToastDialog.showToast("Cashfree payment is not configured.");
        if (type.value == "bookingSelect") {
          Get.back(result: {
            "paymentType": selectedPaymentMethod.value,
            "paymentSuccess": false
          });
        }
        return;
      }

      if (paymentModel.value.cashfree!.enable != true) {
        ShowToastDialog.showToast("Cashfree payment is not enabled.");
        if (type.value == "bookingSelect") {
          Get.back(result: {
            "paymentType": selectedPaymentMethod.value,
            "paymentSuccess": false
          });
        }
        return;
      }

      ShowToastDialog.showLoader("Creating payment session...");

      // Create payment session using Cashfree API
      Map<String, dynamic>? sessionData =
          await createCashfreePaymentSession(amount: amount);
      ShowToastDialog.closeLoader();
      print("Cashfree Session Data: $sessionData");
      print("cashfree ${sessionData?['payment_session_id']}");

      if (sessionData != null && sessionData['payment_session_id'] != null) {
        // Navigate to Cashfree payment screen with WebView
        bool? result = await Get.to<bool>(() => CashfreeScreen(
              orderId: sessionData['order_id'].toString(),
              paymentSessionId: sessionData['payment_session_id'],
              paymentUrl: sessionData['payment_url'],
              isSandbox: sessionData['is_sandbox'] ?? true,
              onPaymentResult: (success) {
                // Result handled after navigation
              },
            ));

        // Handle result after navigation is complete
        print("Cashfree payment result: $result");
        if (result == true) {
          print("Payment successful for type: ${type.value}");
          ShowToastDialog.showToast("Payment Successful!!");
          if (type.value == "bookingSelect") {
            // For seat booking, return payment success with payment method
            Get.back(result: {
              "paymentType": selectedPaymentMethod.value,
              "paymentSuccess": true
            });
          } else {
            // For wallet top-up, proceed with wallet top-up
            walletTopUp();
          }
        } else {
          print("Payment failed or cancelled for type: ${type.value}, result: $result");
          ShowToastDialog.showToast("Payment cancelled or failed");
          if (type.value == "bookingSelect") {
            // For seat booking, return failure status
            Get.back(result: {
              "paymentType": selectedPaymentMethod.value,
              "paymentSuccess": false
            });
          }
        }
      } else {
        ShowToastDialog.showToast(
            "Failed to create payment session. Please try again.");
        if (type.value == "bookingSelect") {
          // For seat booking, return failure status
          Get.back(result: {
            "paymentType": selectedPaymentMethod.value,
            "paymentSuccess": false
          });
        }
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      print("Cashfree payment error: $e");
      ShowToastDialog.showToast("Payment failed: $e");
      if (type.value == "bookingSelect") {
        // For seat booking, return failure status
        Get.back(result: {
          "paymentType": selectedPaymentMethod.value,
          "paymentSuccess": false
        });
      }
    }
  }

  Future<Map<String, dynamic>?> createCashfreePaymentSession(
      {required String amount}) async {
    try {
      final String orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // Use sandbox or production based on Firebase configuration
      bool isSandbox = paymentModel.value.cashfree!.isSandbox ?? true;

      String cashfreeApiUrl = isSandbox
          ? 'https://sandbox.cashfree.com/pg/orders'
          : 'https://api.cashfree.com/pg/orders';

      print("Using Cashfree API URL: $cashfreeApiUrl");
      print("Environment: ${isSandbox ? 'SANDBOX' : 'PRODUCTION'}");

      // Choose credentials based on environment
      String clientId;
      String clientSecret;

      if (isSandbox) {
        // SANDBOX: Use hardcoded test credentials
        clientId = '22299146f982141989bf1c09f3199222';
        clientSecret = 'e5048e944dee7d5f6af2843fdb35570e6f38372b';
        print("Using SANDBOX credentials (hardcoded)");
      } else {
        // PRODUCTION: Use credentials from Firebase
        if (paymentModel.value.cashfree?.clientId == null ||
            paymentModel.value.cashfree?.clientSecret == null) {
          print("Cashfree production API keys not configured in Firebase");
          return null;
        }
        clientId = paymentModel.value.cashfree!.clientId!;
        clientSecret = paymentModel.value.cashfree!.clientSecret!;
        print("Using PRODUCTION credentials from Firebase");
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
            "customer_id": userModel.value.id ??
                'test_customer_${DateTime.now().millisecondsSinceEpoch}',
            "customer_name": userModel.value.fullName(),
            "customer_email": userModel.value.email ?? 'test@example.com',
            "customer_phone": userModel.value.phoneNumber ?? '9999999999',
          },
          "order_meta": {
            "return_url": "https://your-app.com/cashfree/success",
            "cancel_url": "https://your-app.com/cashfree/cancel",
          },
          "order_note": "Wallet top-up via Cashfree",
        }),
      );

      print("Cashfree Payment Session Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print("Cashfree Payment Data: $data");
        // Extract session information from response
        String? paymentSessionId = data['payment_session_id'];
        String? cfOrderId = data['cf_order_id']?.toString();
        String? orderIdFromResponse = data['order_id']?.toString();

        if (paymentSessionId != null && cfOrderId != null) {
          String paymentUrl = isSandbox
              ? 'https://sandbox.cashfree.com/pg/view/order/$cfOrderId'
              : 'https://api.cashfree.com/pg/view/order/$cfOrderId';

          // Return session data with payment URL
          Map<String, dynamic> sessionData = {
            'payment_session_id': paymentSessionId,
            'order_id': orderIdFromResponse ?? orderId,
            'cf_order_id': cfOrderId,
            'payment_url': paymentUrl,
            'order_amount': data['order_amount'],
            'order_currency': data['order_currency'],
            'is_sandbox': isSandbox,
          };

          print("Generated Cashfree Session Data: $sessionData");
          return sessionData;
        } else {
          print("Missing payment_session_id or cf_order_id in response");
          return null;
        }
      } else {
        print("Failed to create Cashfree payment session: ${response.statusCode}");
        print("Error response: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error creating Cashfree payment session: $e");
      return null;
    }
  }
}
