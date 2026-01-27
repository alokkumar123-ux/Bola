import 'package:cloud_firestore/cloud_firestore.dart';

class PendingBookingModel {
  String? id;
  String? userId;
  String? orderId;
  String? bookingId;
  double? amount;
  String? status; // pending, processing, completed, failed
  Timestamp? createdAt;

  // All booking data needed for processing
  List<int>? selectedSeatIndices;
  Map<String, String?>? passengerNames;
  Map<String, String?>? passengerGenders;
  Map<String, int?>? passengerAges;
  Map<String, dynamic>? stopOverData;
  double? pricePerSeat;
  String? paymentMethod;

  PendingBookingModel({
    this.id,
    this.userId,
    this.orderId,
    this.bookingId,
    this.amount,
    this.status,
    this.createdAt,
    this.selectedSeatIndices,
    this.passengerNames,
    this.passengerGenders,
    this.passengerAges,
    this.stopOverData,
    this.pricePerSeat,
    this.paymentMethod,
  });

  factory PendingBookingModel.fromJson(Map<String, dynamic> json) {
    return PendingBookingModel(
      id: json['id'],
      userId: json['userId'],
      orderId: json['orderId'],
      bookingId: json['bookingId'],
      amount: double.tryParse(json['amount']?.toString() ?? '0'),
      status: json['status'],
      createdAt: json['createdAt'],
      selectedSeatIndices: json['selectedSeatIndices'] != null
          ? List<int>.from(json['selectedSeatIndices'])
          : null,
      passengerNames: json['passengerNames'] != null
          ? Map<String, String?>.from(json['passengerNames'])
          : null,
      passengerGenders: json['passengerGenders'] != null
          ? Map<String, String?>.from(json['passengerGenders'])
          : null,
      passengerAges: json['passengerAges'] != null
          ? (json['passengerAges'] as Map)
              .map((key, value) => MapEntry(key.toString(), value as int?))
          : null,
      stopOverData: json['stopOverData'] != null
          ? Map<String, dynamic>.from(json['stopOverData'])
          : null,
      pricePerSeat: double.tryParse(json['pricePerSeat']?.toString() ?? '0'),
      paymentMethod: json['paymentMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderId': orderId,
      'bookingId': bookingId,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
      'selectedSeatIndices': selectedSeatIndices,
      'passengerNames': passengerNames,
      'passengerGenders': passengerGenders,
      'passengerAges': passengerAges,
      'stopOverData': stopOverData,
      'pricePerSeat': pricePerSeat,
      'paymentMethod': paymentMethod,
    };
  }
}
