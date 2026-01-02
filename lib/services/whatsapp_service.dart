import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WhatsAppService {
  static const String _baseUrl = 'https://meta.muzztech.com/api/v1';
  static const String _authToken =
      'Bearer 4iroTl3KUjJWJ8Xj9K7QbJcXlooY3HXUakmmB3oQHz17U5i7qAqYbrVpzYOCXApECHRtw7OaKHgRkVVP1pjcALLdHFi3awQm3MZDSwtcShL5GixRVx53fxIJS1D04kkasq1bwUAZZ3tscUQDhBifeAH5nMnpBWoF';

  /// Send WhatsApp template message
  static Future<bool> sendTemplateMessage({
    required String phoneNumber,
    required String templateName,
    List<dynamic>? components,
  }) async {
    try {

      // Clean phone number (remove any non-digits and ensure proper format)
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (!cleanPhone.startsWith('+')) {
        // Add country code if missing (assuming India +91, modify as needed)
        if (cleanPhone.length == 10) {
          cleanPhone = '+91$cleanPhone';
        }
      }

      final Map<String, dynamic> payload = {
        'messaging_product': 'whatsapp',
        'recipient_type': 'individual',
        'to': cleanPhone,
        'type': 'template',
        'template': {
          'name': templateName,
          'language': {'code': 'en'},
          'components': components ?? []
        }
      };

      debugPrint('Request payload: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/send/custom/template'),
        headers: {
          'Authorization': _authToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ WhatsApp message sent successfully!');
          return true;
        } else {
          debugPrint('❌ WhatsApp API error: ${responseData['message']}');
          return false;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ WhatsApp service exception: $e');
      return false;
    }
  }

  /// Send rider booking cancelled message (to passengers when driver cancels)
  static Future<bool> sendRiderBookingCancelled({
    required String phoneNumber,
    List<dynamic>? rideDetails,
  }) async {
    return await sendTemplateMessage(
      phoneNumber: phoneNumber,
      templateName: 'rider_bookingcancelled',
      components: rideDetails,
    );
  }

  /// Send rider booking confirmed message (to passenger when they book)
  static Future<bool> sendRiderBookingConfirmed({
    required String phoneNumber,
    List<dynamic>? rideDetails,
  }) async {
    return await sendTemplateMessage(
      phoneNumber: phoneNumber,
      templateName: 'after_rider_booked',
      components: rideDetails,
    );
  }

  /// Send driver ride published message (to driver when they publish)
  static Future<bool> sendDriverRidePublished({
    required String phoneNumber,
    List<dynamic>? rideDetails,
  }) async {
    return await sendTemplateMessage(
      phoneNumber: phoneNumber,
      templateName: 'after_driver_ridepublish',
      components: rideDetails,
    );
  }

  /// Send driver cancelled message (to driver when passenger cancels)
  static Future<bool> sendDriverCancelled({
    required String phoneNumber,
    List<String>? rideDetails,
  }) async {
    return await sendTemplateMessage(
      phoneNumber: phoneNumber,
      templateName: 'driver_cancelled',
      components: rideDetails,
    );
  }

  /// Send driver seat book message (to driver when someone books)
  static Future<bool> sendDriverSeatBook({
    required String phoneNumber,
    List<String>? rideDetails,
  }) async {
    return await sendTemplateMessage(
      phoneNumber: phoneNumber,
      templateName: 'driver_seabook',
      components: rideDetails,
    );
  }
    static Future<bool> sendsos({
    required String phoneNumber,
    List<String>? rideDetails,
  }) async {
    return await sendTemplateMessage(
      phoneNumber: phoneNumber,
      templateName: 'sosalert',
      components: rideDetails,
    );
  }

  /// Send to multiple recipients (for driver cancellation to all passengers)
  static Future<List<bool>> sendToMultipleRecipients({
    required List<String> phoneNumbers,
    required String templateName,
    List<dynamic>? components,
  }) async {
    List<bool> results = [];

    for (String phoneNumber in phoneNumbers) {
      if (phoneNumber.isNotEmpty) {
        bool result = await sendTemplateMessage(
          phoneNumber: phoneNumber,
          templateName: templateName,
          components: components,
        );
        results.add(result);

        // Small delay between requests to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return results;
  }
}
