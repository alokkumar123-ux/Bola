import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:poolmate/model/payment_method_model.dart';
import 'package:poolmate/utils/firestore/payment_utils.dart';

/// Service to verify Cashfree payments by calling Cashfree API
/// This ensures payment is actually successful before creating booking
class CashfreeVerificationService {
  /// Get order status from Cashfree API
  /// Returns the full order response including order_status
  static Future<Map<String, dynamic>?> getOrderStatus(String orderId) async {
    try {
      // Get payment configuration
      PaymentModel? paymentModel = await PaymentUtils().getPayment();
      if (paymentModel?.cashfree == null) {
        print("❌ Cashfree not configured");
        return null;
      }

      bool isSandbox = paymentModel!.cashfree!.isSandbox ?? true;

      String baseUrl = isSandbox
          ? 'https://sandbox.cashfree.com/pg/orders'
          : 'https://api.cashfree.com/pg/orders';

      // Get credentials based on environment
      String clientId;
      String clientSecret;

      if (isSandbox) {
        // SANDBOX: Use hardcoded test credentials
        clientId = '22299146f982141989bf1c09f3199222';
        clientSecret = 'e5048e944dee7d5f6af2843fdb35570e6f38372b';
      } else {
        // PRODUCTION: Use credentials from Firebase
        if (paymentModel.cashfree?.clientId == null ||
            paymentModel.cashfree?.clientSecret == null) {
          print("❌ Cashfree production credentials not configured");
          return null;
        }
        clientId = paymentModel.cashfree!.clientId!;
        clientSecret = paymentModel.cashfree!.clientSecret!;
      }

      print("🔍 Verifying order status for: $orderId");
      print("🌍 Environment: ${isSandbox ? 'SANDBOX' : 'PRODUCTION'}");

      final response = await http.get(
        Uri.parse('$baseUrl/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'X-Client-Id': clientId,
          'X-Client-Secret': clientSecret,
          'x-api-version': '2023-08-01',
        },
      );

      print("📥 Order Status Response Code: ${response.statusCode}");
      print("📥 Order Status Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Failed to get order status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error getting order status: $e");
      return null;
    }
  }

  /// Get all payments for an order from Cashfree API
  /// Returns list of payment attempts with their statuses
  static Future<List<Map<String, dynamic>>?> getPaymentsForOrder(
      String orderId) async {
    try {
      // Get payment configuration
      PaymentModel? paymentModel = await PaymentUtils().getPayment();
      if (paymentModel?.cashfree == null) {
        print("❌ Cashfree not configured");
        return null;
      }

      bool isSandbox = paymentModel!.cashfree!.isSandbox ?? true;

      String baseUrl = isSandbox
          ? 'https://sandbox.cashfree.com/pg/orders'
          : 'https://api.cashfree.com/pg/orders';

      // Get credentials based on environment
      String clientId;
      String clientSecret;

      if (isSandbox) {
        clientId = '22299146f982141989bf1c09f3199222';
        clientSecret = 'e5048e944dee7d5f6af2843fdb35570e6f38372b';
      } else {
        if (paymentModel.cashfree?.clientId == null ||
            paymentModel.cashfree?.clientSecret == null) {
          print("❌ Cashfree production credentials not configured");
          return null;
        }
        clientId = paymentModel.cashfree!.clientId!;
        clientSecret = paymentModel.cashfree!.clientSecret!;
      }

      print("🔍 Getting payments for order: $orderId");

      final response = await http.get(
        Uri.parse('$baseUrl/$orderId/payments'),
        headers: {
          'Content-Type': 'application/json',
          'X-Client-Id': clientId,
          'X-Client-Secret': clientSecret,
          'x-api-version': '2023-08-01',
        },
      );

      print("📥 Payments Response Code: ${response.statusCode}");
      print("📥 Payments Response: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> payments = jsonDecode(response.body);
        return payments.cast<Map<String, dynamic>>();
      } else {
        print("❌ Failed to get payments: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error getting payments: $e");
      return null;
    }
  }

  /// Verify if payment is successful by checking with Cashfree API
  /// Returns a CashfreePaymentResult with verification status and payment details
  static Future<CashfreePaymentResult> verifyPayment(String orderId) async {
    try {
      print("🔐 Starting payment verification for order: $orderId");

      // First check order status
      Map<String, dynamic>? orderData = await getOrderStatus(orderId);
      if (orderData == null) {
        return CashfreePaymentResult(
          isVerified: false,
          errorMessage: "Could not fetch order status",
        );
      }

      String? orderStatus = orderData['order_status'];
      print("📋 Order Status: $orderStatus");

      // Check if order is PAID
      if (orderStatus == 'PAID') {
        // Get payment details for additional info
        List<Map<String, dynamic>>? payments =
            await getPaymentsForOrder(orderId);

        if (payments != null && payments.isNotEmpty) {
          // Find the successful payment
          Map<String, dynamic>? successfulPayment;
          for (var payment in payments) {
            if (payment['payment_status'] == 'SUCCESS') {
              successfulPayment = payment;
              break;
            }
          }

          if (successfulPayment != null) {
            print("✅ Payment verified successfully!");
            print("🆔 Order ID: $orderId");
            print("💰 Payment ID: ${successfulPayment['cf_payment_id']}");
            print("🏦 Bank Reference: ${successfulPayment['bank_reference']}");

            return CashfreePaymentResult(
              isVerified: true,
              orderId: orderId,
              cfOrderId: orderData['cf_order_id']?.toString(),
              cfPaymentId: successfulPayment['cf_payment_id']?.toString(),
              bankReference: successfulPayment['bank_reference']?.toString(),
              paymentAmount: successfulPayment['payment_amount']?.toString(),
              paymentMethod:
                  _getPaymentMethodString(successfulPayment['payment_method']),
              paymentTime:
                  successfulPayment['payment_completion_time']?.toString(),
            );
          }
        }

        // Order is PAID but no payment details found - still mark as verified
        return CashfreePaymentResult(
          isVerified: true,
          orderId: orderId,
          cfOrderId: orderData['cf_order_id']?.toString(),
        );
      } else if (orderStatus == 'ACTIVE') {
        // Order is still active, payment might be pending
        return CashfreePaymentResult(
          isVerified: false,
          isPending: true,
          errorMessage: "Payment is still being processed",
        );
      } else if (orderStatus == 'EXPIRED') {
        return CashfreePaymentResult(
          isVerified: false,
          errorMessage: "Order has expired",
        );
      } else {
        return CashfreePaymentResult(
          isVerified: false,
          errorMessage: "Order status: $orderStatus",
        );
      }
    } catch (e) {
      print("❌ Error verifying payment: $e");
      return CashfreePaymentResult(
        isVerified: false,
        errorMessage: "Error verifying payment: $e",
      );
    }
  }

  /// Helper to extract payment method string
  static String? _getPaymentMethodString(dynamic paymentMethod) {
    if (paymentMethod == null) return null;
    if (paymentMethod is Map) {
      if (paymentMethod.containsKey('upi')) return 'UPI';
      if (paymentMethod.containsKey('card')) return 'Card';
      if (paymentMethod.containsKey('netbanking')) return 'Net Banking';
      if (paymentMethod.containsKey('wallet')) return 'Wallet';
    }
    return paymentMethod.toString();
  }
}

/// Result class for Cashfree payment verification
class CashfreePaymentResult {
  final bool isVerified;
  final bool isPending;
  final String? orderId;
  final String? cfOrderId;
  final String? cfPaymentId;
  final String? bankReference;
  final String? paymentAmount;
  final String? paymentMethod;
  final String? paymentTime;
  final String? errorMessage;

  CashfreePaymentResult({
    required this.isVerified,
    this.isPending = false,
    this.orderId,
    this.cfOrderId,
    this.cfPaymentId,
    this.bankReference,
    this.paymentAmount,
    this.paymentMethod,
    this.paymentTime,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'CashfreePaymentResult(isVerified: $isVerified, isPending: $isPending, '
        'orderId: $orderId, cfPaymentId: $cfPaymentId, bankReference: $bankReference, '
        'errorMessage: $errorMessage)';
  }
}
