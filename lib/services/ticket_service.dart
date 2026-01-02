import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/user_model.dart';

class TicketService {
  static const String _apiUrl = 'https://bolaletsgo.com/ticket.php';

  /// Generate a random transaction ID
  static String _generateTransactionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'TXN${List.generate(10, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  /// Format Timestamp to ISO8601 string with timezone
  static String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now().toIso8601String();
    try {
      final DateTime dt = timestamp.toDate();
      return DateFormat("yyyy-MM-dd'T'HH:mm:ssZ").format(dt);
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  /// Build passengers list from booking data
  static List<Map<String, dynamic>> _buildPassengersList(
    BookedUserModel bookingUserModel,
    UserModel userModel,
  ) {
    List<Map<String, dynamic>> passengers = [];

    final passengerNames = bookingUserModel.passengerNames ?? {};
    final passengerGenders = bookingUserModel.passengerGenders ?? {};
    final passengerAges = bookingUserModel.passengerAges ?? {};

    // Seat label mapping (0-indexed seat index to label)
    const seatLabels = ['A1', 'A2', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3'];

    // Convert seat index to label
    String getSeatLabel(String seatKey) {
      final seatIndex = int.tryParse(seatKey) ?? -1;
      if (seatIndex >= 0 && seatIndex < seatLabels.length) {
        return seatLabels[seatIndex];
      }
      return 'S$seatKey';
    }

    // First priority: use passengerNames map if available
    if (passengerNames.isNotEmpty) {
      passengerNames.forEach((seatKey, name) {
        if (name != null && name.toString().isNotEmpty) {
          passengers.add({
            'passenger_name': name.toString(),
            'seat_no': getSeatLabel(seatKey),
            'gender': passengerGenders[seatKey] ?? 'Male',
            'age': passengerAges[seatKey] ?? 25,
          });
        }
      });
    }

    // If passengerNames is empty, try to use selectedSeats
    if (passengers.isEmpty && bookingUserModel.selectedSeats != null) {
      for (var seat in bookingUserModel.selectedSeats!) {
        passengers.add({
          'passenger_name':
              '${userModel.firstName ?? ''} ${userModel.lastName ?? ''}'.trim(),
          'seat_no': getSeatLabel(seat.toString()),
        });
      }
    }

    // If still empty, try to parse bookedSeat (e.g., "1,2" or just "2")
    if (passengers.isEmpty && bookingUserModel.bookedSeat != null) {
      // Check if bookedSeat is a comma-separated list like "1,2"
      final bookedSeatStr = bookingUserModel.bookedSeat!;
      if (bookedSeatStr.contains(',')) {
        // Multiple seats like "1,2"
        final seatParts = bookedSeatStr.split(',');
        for (var seat in seatParts) {
          final trimmedSeat = seat.trim();
          if (trimmedSeat.isNotEmpty) {
            passengers.add({
              'passenger_name':
                  '${userModel.firstName ?? ''} ${userModel.lastName ?? ''}'
                      .trim(),
              'seat_no': getSeatLabel(trimmedSeat),
            });
          }
        }
      } else {
        // Single count like "2" - just add that many passengers
        final seatCount = int.tryParse(bookedSeatStr) ?? 1;
        for (int i = 0; i < seatCount; i++) {
          passengers.add({
            'passenger_name':
                '${userModel.firstName ?? ''} ${userModel.lastName ?? ''}'
                    .trim(),
            'seat_no': 'S${i + 1}',
          });
        }
      }
    }

    // Final fallback: add at least one passenger
    if (passengers.isEmpty) {
      String userName =
          '${userModel.firstName ?? ''} ${userModel.lastName ?? ''}'.trim();
      if (userName.isEmpty) userName = 'Passenger';
      passengers.add({
        'passenger_name': userName,
        'seat_no': 'A1',
      });
    }

    debugPrint('📋 Built passengers list: $passengers');
    return passengers;
  }

  /// Calculate total amount including taxes
  static double _calculateTotal(BookedUserModel bookingUserModel) {
    double subTotal = double.tryParse(bookingUserModel.subTotal ?? '0') ?? 0;
    double taxAmount = 0;

    if (bookingUserModel.taxList != null) {
      for (var tax in bookingUserModel.taxList!) {
        if (tax.enable == true && tax.tax != null) {
          if (tax.type == 'percentage' || tax.type == 'Percentage') {
            taxAmount += subTotal * (double.tryParse(tax.tax!) ?? 0) / 100;
          } else {
            taxAmount += double.tryParse(tax.tax!) ?? 0;
          }
        }
      }
    }

    return subTotal + taxAmount;
  }

  /// Generate ticket PDF and return the PDF URL
  static Future<Map<String, dynamic>> generateTicket({
    required BookingModel bookingModel,
    required BookedUserModel bookingUserModel,
    required UserModel userModel,
    required UserModel publisherUserModel,
  }) async {
    try {
      // Build driver name
      String driverName =
          '${publisherUserModel.firstName ?? ''} ${publisherUserModel.lastName ?? ''}'
              .trim();
      if (driverName.isEmpty) driverName = 'Driver';

      // Build vehicle type from brand and model
      String vehicleType = '';
      if (bookingModel.vehicleInformation != null) {
        final brand = bookingModel.vehicleInformation!.vehicleBrand?.name ?? '';
        final model = bookingModel.vehicleInformation!.vehicleModel?.name ?? '';
        vehicleType = '$brand $model'.trim();
      }
      if (vehicleType.isEmpty) vehicleType = 'Vehicle';

      // Parse distance - distance is stored in meters, convert to km
      int distanceKm = 0;
      if (bookingModel.distance != null) {
        // Distance is stored in meters (e.g., "5150" or "5150 m")
        final distanceStr =
            bookingModel.distance!.replaceAll(RegExp(r'[^0-9.]'), '');
        final distanceInMeters = double.tryParse(distanceStr) ?? 0;
        // Convert meters to kilometers
        distanceKm = (distanceInMeters / 1000).round();
      }

      // Build passengers list
      final passengers = _buildPassengersList(bookingUserModel, userModel);

      // Calculate prices
      double perSeatPrice =
          double.tryParse(bookingModel.pricePerSeat ?? '0') ?? 0;
      double subTotal = double.tryParse(bookingUserModel.subTotal ?? '0') ?? 0;
      double totalAmount = _calculateTotal(bookingUserModel);

      // Build request body
      final Map<String, dynamic> requestBody = {
        'pickup_location': bookingModel.pickUpAddress ?? '',
        'drop_location': bookingModel.dropAddress ?? '',
        'departure_time': _formatDateTime(bookingModel.departureDateTime),
        'distance_km': distanceKm,
        'pnr_number': bookingUserModel.pnrNumber ??
            'PNR${DateTime.now().millisecondsSinceEpoch}',
        'vehicle_details': {
          'license_number':
              bookingModel.vehicleInformation?.licensePlatNumber ?? '',
          'driver_name': driverName,
          'vehicle_type': vehicleType,
        },
        'passengers': passengers,
        'payment_details': {
          'per_seat_price': perSeatPrice,
          'sub_total': subTotal,
          'total_amount': totalAmount,
          'payment_status':
              bookingUserModel.paymentStatus == true ? 'Paid' : 'Pending',
          'payment_method': bookingUserModel.paymentType ?? 'Cash',
          'transaction_id': _generateTransactionId(),
        },
        'booking_status': _getBookingStatus(bookingModel, userModel),
        'created_at': _formatDateTime(bookingUserModel.createdAt),
      };

      debugPrint('📝 Ticket API Request: ${jsonEncode(requestBody)}');

      // Make API call
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint(
          '📬 Ticket API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == true && responseData['pdf_url'] != null) {
          return {
            'success': true,
            'pdf_url': responseData['pdf_url'],
            'message': responseData['message'] ?? 'PDF Generated Successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to generate ticket',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Ticket service error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Get booking status considering user cancellation
  static String _getBookingStatus(
      BookingModel bookingModel, UserModel userModel) {
    if (userModel.id != null &&
        bookingModel.cancelledUserId != null &&
        bookingModel.cancelledUserId!.contains(userModel.id) &&
        bookingModel.bookedUserId!.contains(userModel.id)) {
      return _mapBookingStatus(bookingModel.status);
    } else if (userModel.id != null &&
        bookingModel.cancelledUserId != null &&
        bookingModel.cancelledUserId!.contains(userModel.id)) {
      return 'Cancelled';
    }
    return _mapBookingStatus(bookingModel.status);
  }

  /// Map internal booking status to display status
  static String _mapBookingStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'placed':
        return 'Confirmed';
      case 'ongoing':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Confirmed';
    }
  }
}
