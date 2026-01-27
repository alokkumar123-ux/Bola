import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/home_screen/booking_success_screen.dart';
import 'package:poolmate/app/payment/cashfreeScreen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/send_notification.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/payment_method_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/services/cashfree_verification_service.dart';
import 'package:poolmate/services/pending_payment_service.dart';
import 'package:poolmate/services/whatsapp_service.dart';
import 'package:poolmate/utils/firestore/payment_utils.dart';
import 'package:http/http.dart' as http;
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/booking_utils.dart';
import 'package:poolmate/model/map/geometry.dart';

class SelectPaymentMethodController extends GetxController {
  Rx<PaymentModel> paymentModel = PaymentModel().obs;

  RxBool isLoading = true.obs;
  RxString selectedPaymentMethod = "".obs;
  RxString bookingId = "".obs;
  RxString type = "wallet".obs;
  RxString driverPaymentMethod = "".obs;

  // Additional data needed for automatic booking creation
  Rx<BookingModel> bookingModel = BookingModel().obs;
  Rx<StopOverModel> stopOverModel = StopOverModel().obs;
  Rx<Location> pickupLocation = Location().obs;
  Rx<Location> dropLocation = Location().obs;
  RxInt numberOfSeats = 1.obs;
  RxString subTotal = "0".obs;

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

      // Get additional data for automatic booking creation
      if (argumentData['bookingModel'] != null) {
        bookingModel.value = argumentData['bookingModel'];
      }
      if (argumentData['stopOverModel'] != null) {
        stopOverModel.value = argumentData['stopOverModel'];
      }
      if (argumentData['pickupLocation'] != null) {
        pickupLocation.value = argumentData['pickupLocation'];
      }
      if (argumentData['dropLocation'] != null) {
        dropLocation.value = argumentData['dropLocation'];
      }
      if (argumentData['numberOfSeats'] != null) {
        numberOfSeats.value = argumentData['numberOfSeats'];
      }
      if (argumentData['subTotal'] != null) {
        subTotal.value = argumentData['subTotal'];
      }
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

  // Cashfree Payment Integration with Verification and Automatic Booking
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
        String orderId = sessionData['order_id'].toString();

        // Save pending payment for crash recovery (for bookingSelect type)
        if (type.value == "bookingSelect" &&
            bookingModel.value.id != null &&
            stopOverModel.value.startAddress != null) {
          await PendingPaymentService.savePendingPayment(
            orderId: orderId,
            bookingId: bookingModel.value.id!,
            stopOver: stopOverModel.value,
            numberOfSeats: numberOfSeats.value.toString(),
            subTotal: subTotal.value,
            paymentType: selectedPaymentMethod.value,
            pickupLocation: pickupLocation.value,
            dropLocation: dropLocation.value,
          );
        }

        // Save pending top-up for crash recovery (for wallet type)
        if (type.value == "wallet") {
          await PendingPaymentService.savePendingTopup(
            orderId: orderId,
            amount: amount,
          );
        }

        // Navigate to Cashfree payment screen with WebView
        bool? result = await Get.to<bool>(() => CashfreeScreen(
              orderId: orderId,
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
          print("Payment SDK returned success, verifying with API...");
          ShowToastDialog.showLoader("Verifying payment...");

          // Verify payment with Cashfree API
          CashfreePaymentResult verificationResult =
              await CashfreeVerificationService.verifyPayment(orderId);

          ShowToastDialog.closeLoader();

          if (verificationResult.isVerified) {
            print("✅ Payment verified successfully!");
            ShowToastDialog.showToast("Payment Successful!");

            if (type.value == "bookingSelect") {
              // Create booking automatically after verified payment
              bool bookingCreated = await _createBookingAfterPayment(
                verificationResult,
              );

              if (bookingCreated) {
                // Clear pending payment
                await PendingPaymentService.clearPendingPayment();
                // Navigate to success screen
                Get.off(const BookingSuccessScreen());
              } else {
                // Booking creation failed, but payment was successful
                ShowToastDialog.showToast(
                    "Payment successful but booking failed. Please contact support.");
                Get.back(result: {
                  "paymentType": selectedPaymentMethod.value,
                  "paymentSuccess": true,
                  "bookingCreated": false
                });
              }
            } else {
              // For wallet top-up, proceed with wallet top-up
              await PendingPaymentService.clearPendingTopup();
              walletTopUp();
            }
          } else if (verificationResult.isPending) {
            print("⏳ Payment is still pending");
            ShowToastDialog.showToast(
                "Payment is being processed. We'll notify you when it's complete.");
            // Keep pending payment for recovery
            if (type.value == "bookingSelect") {
              Get.back(result: {
                "paymentType": selectedPaymentMethod.value,
                "paymentSuccess": false,
                "paymentPending": true
              });
            }
          } else {
            print(
                "❌ Payment verification failed: ${verificationResult.errorMessage}");
            ShowToastDialog.showToast(
                "Payment verification failed. Please try again.");
            await PendingPaymentService.clearPendingPayment();
            if (type.value == "bookingSelect") {
              Get.back(result: {
                "paymentType": selectedPaymentMethod.value,
                "paymentSuccess": false
              });
            }
          }
        } else {
          print(
              "Payment failed or cancelled for type: ${type.value}, result: $result");
          ShowToastDialog.showToast("Payment cancelled or failed");
          await PendingPaymentService.clearPendingPayment();
          if (type.value == "bookingSelect") {
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
      await PendingPaymentService.clearPendingPayment();
      if (type.value == "bookingSelect") {
        Get.back(result: {
          "paymentType": selectedPaymentMethod.value,
          "paymentSuccess": false
        });
      }
    }
  }

  /// Create booking after Cashfree payment is verified
  Future<bool> _createBookingAfterPayment(
      CashfreePaymentResult paymentResult) async {
    try {
      ShowToastDialog.showLoader("Creating booking...");

      // Refresh booking model to get latest data
      BookingModel? latestBooking =
          await BookingUtils.getMyBookingByUserId(bookingModel.value.id!);
      if (latestBooking == null) {
        print("❌ Booking not found");
        ShowToastDialog.closeLoader();
        return false;
      }
      bookingModel.value = latestBooking;

      // Add current user to booked users
      if (!bookingModel.value.bookedUserId!
          .contains(AuthUtils.getCurrentUid())) {
        bookingModel.value.bookedUserId!.add(AuthUtils.getCurrentUid());
      }
      int totalSeats = int.tryParse(bookingModel.value.totalSeat ?? "4") ?? 4;

      bookingModel.value.bookedSeat = BookingUtils.allocateSeats(
        bookingModel.value.bookedSeat,
        numberOfSeats.value,
        totalSeats,
      );

      // Get driver user for notifications
      UserModel? driverUser =
          await UserUtils.getUserProfile(bookingModel.value.createdBy!);

      // Create booked user model with Cashfree payment details
      BookedUserModel bookingUserModel = BookedUserModel();
      bookingUserModel.id = AuthUtils.getCurrentUid();
      bookingUserModel.bookedSeat = numberOfSeats.value.toString();
      bookingUserModel.paymentStatus = true; // Payment is verified
      bookingUserModel.paymentType = selectedPaymentMethod.value;
      bookingUserModel.stopOver = stopOverModel.value;
      bookingUserModel.createdAt = Timestamp.now();
      bookingUserModel.pickupLocation = pickupLocation.value;
      bookingUserModel.dropLocation = dropLocation.value;
      bookingUserModel.adminCommission = Constant.adminCommission;
      bookingUserModel.taxList = Constant.taxList;
      bookingUserModel.subTotal = subTotal.value;

      // Store Cashfree payment details for refund processing
      bookingUserModel.cashfreeOrderId = paymentResult.orderId;
      bookingUserModel.cashfreePaymentId = paymentResult.cfPaymentId;
      bookingUserModel.bankReference = paymentResult.bankReference;
      bookingUserModel.paymentVerified = true;
      bookingUserModel.paymentVerifiedAt = Timestamp.now();

      // Save user booking
      await BookingUtils.setUserBooking(bookingModel.value, bookingUserModel);

      // Send notification to driver
      if (driverUser != null && driverUser.fcmToken != null) {
        await SendNotification.sendOneNotification(
            type: Constant.booking_confirmed,
            token: driverUser.fcmToken!,
            payload: {});
      }

      // Send notification to passenger
      if (userModel.value.fcmToken != null &&
          userModel.value.fcmToken!.isNotEmpty) {
        await SendNotification.sendOneNotification(
            type: Constant.booking_confirmed,
            token: userModel.value.fcmToken!,
            payload: {});
      }

      // Send WhatsApp notifications
      if (userModel.value.phoneNumber != null) {
        await WhatsAppService.sendRiderBookingConfirmed(
          phoneNumber: userModel.value.phoneNumber!,
        );
      }

      if (driverUser != null && driverUser.phoneNumber != null) {
        await WhatsAppService.sendDriverSeatBook(
          phoneNumber: driverUser.phoneNumber!,
        );
      }

      // Update booking
      await BookingUtils.setBooking(bookingModel.value);

      ShowToastDialog.closeLoader();
      print("✅ Booking created successfully after Cashfree payment!");
      return true;
    } catch (e) {
      ShowToastDialog.closeLoader();
      print("❌ Error creating booking after payment: $e");
      return false;
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
          "order_note": type.value == "bookingSelect"
              ? "Ride booking payment"
              : "Wallet top-up via Cashfree",
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
        print(
            "Failed to create Cashfree payment session: ${response.statusCode}");
        print("Error response: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error creating Cashfree payment session: $e");
      return null;
    }
  }
}
