import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:poolmate/model/payment_method_model.dart';

/// Utility class for verifying Cashfree payments via GET API
class CashfreeVerificationUtils {
  /// Verify payment by calling GET /pg/orders/{orderId}
  /// Returns order_status: ACTIVE, PAID, EXPIRED, TERMINATED
  static Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required Cashfree cashfreeConfig,
  }) async {
    try {
      final bool isSandbox = cashfreeConfig.isSandbox ?? true;

      final String apiUrl = isSandbox
          ? 'https://sandbox.cashfree.com/pg/orders/$orderId'
          : 'https://api.cashfree.com/pg/orders/$orderId';

      // Choose credentials based on environment
      late final String clientId;
      late final String clientSecret;

      if (isSandbox) {
        // SANDBOX: use hardcoded test credentials
        clientId = '22299146f982141989bf1c09f3199222';
        clientSecret = 'e5048e944dee7d5f6af2843fdb35570e6f38372b';
      } else {
        if (cashfreeConfig.clientId == null ||
            cashfreeConfig.clientSecret == null) {
          return {
            'success': false,
            'message': 'Cashfree credentials not configured',
          };
        }
        clientId = cashfreeConfig.clientId!;
        clientSecret = cashfreeConfig.clientSecret!;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Client-Id': clientId,
          'X-Client-Secret': clientSecret,
          'x-api-version': '2023-08-01',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? orderStatus = data['order_status'];
        final double? orderAmount =
            double.tryParse(data['order_amount']?.toString() ?? '0');

        return {
          'success': true,
          'order_status': orderStatus,
          'order_amount': orderAmount,
          'is_paid': orderStatus == 'PAID',
          'cf_order_id': data['cf_order_id'],
          'order_id': data['order_id'],
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to verify payment: ${response.statusCode}',
          'body': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error verifying payment: $e',
      };
    }
  }

  /// Get detailed payment information for an order
  /// Returns list of payment attempts with their statuses
  static Future<Map<String, dynamic>> getPaymentsForOrder({
    required String orderId,
    required Cashfree cashfreeConfig,
  }) async {
    try {
      final bool isSandbox = cashfreeConfig.isSandbox ?? true;

      final String apiUrl = isSandbox
          ? 'https://sandbox.cashfree.com/pg/orders/$orderId/payments'
          : 'https://api.cashfree.com/pg/orders/$orderId/payments';

      late final String clientId;
      late final String clientSecret;

      if (isSandbox) {
        clientId = '22299146f982141989bf1c09f3199222';
        clientSecret = 'e5048e944dee7d5f6af2843fdb35570e6f38372b';
      } else {
        if (cashfreeConfig.clientId == null ||
            cashfreeConfig.clientSecret == null) {
          return {
            'success': false,
            'message': 'Cashfree credentials not configured',
          };
        }
        clientId = cashfreeConfig.clientId!;
        clientSecret = cashfreeConfig.clientSecret!;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Client-Id': clientId,
          'X-Client-Secret': clientSecret,
          'x-api-version': '2023-08-01',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> payments = jsonDecode(response.body);

        // Check if any payment was successful
        bool hasSuccessfulPayment =
            payments.any((p) => p['payment_status'] == 'SUCCESS');

        return {
          'success': true,
          'payments': payments,
          'has_successful_payment': hasSuccessfulPayment,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get payments: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error getting payments: $e',
      };
    }
  }
}
