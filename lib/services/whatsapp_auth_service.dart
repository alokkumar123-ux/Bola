import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class WhatsAppAuthService {
  static const String _baseUrl =
      'https://meta.muzztech.com/api/v1/send/authentication/template/messages';
  static const String _templateId = '25275470052095062';
  static const String _authToken =
      'Bearer 4iroTl3KUjJWJ8Xj9K7QbJcXlooY3HXUakmmB3oQHz17U5i7qAqYbrVpzYOCXApECHRtw7OaKHgRkVVP1pjcALLdHFi3awQm3MZDSwtcShL5GixRVx53fxIJS1D04kkasq1bwUAZZ3tscUQDhBifeAH5nMnpBWoF';

  /// Generates a 6-digit OTP
  static String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Generates a secure unique user ID similar to Firebase Auth UID format
  static String generateUserId() {
    // Generate a UUID v4 and remove hyphens to make it similar to Firebase UID
    const uuid = Uuid();
    return uuid.v4().replaceAll('-', '');
  }

  /// Sends OTP via WhatsApp
  /// Returns a map with 'success' boolean and 'message' string
  static Future<Map<String, dynamic>> sendOTP({
    required String countryCode,
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      // Clean the country code (remove + if present)
      final cleanCountryCode = countryCode.replaceAll('+', '');
      // Clean the phone number (remove any spaces or special characters)
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

      final body = {
        'template_id': _templateId,
        'country_code': cleanCountryCode,
        'recipient_phone_number': cleanPhoneNumber,
        'otp': otp,
      };

      debugPrint('WhatsApp Auth Request: $body');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _authToken,
        },
        body: jsonEncode(body),
      );

      debugPrint('WhatsApp Auth Response Status: ${response.statusCode}');
      debugPrint('WhatsApp Auth Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'OTP sent successfully',
            'data': responseData['data'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to send OTP',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to send OTP. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('WhatsApp Auth Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Verifies the OTP entered by user against the stored OTP
  static bool verifyOTP(String enteredOTP, String storedOTP) {
    return enteredOTP == storedOTP;
  }
}
