import 'package:cloud_firestore/cloud_firestore.dart';

class SeatBooking {
  String? seatNumber;
  String? userId;
  Timestamp? bookedAt;
  bool? isBooked;

  SeatBooking({
    this.seatNumber,
    this.userId,
    this.bookedAt,
    this.isBooked = false,
  });

  SeatBooking.fromJson(Map<String, dynamic> json) {
    seatNumber = json['seatNumber'];
    userId = json['userId'];
    bookedAt = json['bookedAt'];
    isBooked = json['isBooked'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['seatNumber'] = seatNumber;
    data['userId'] = userId;
    data['bookedAt'] = bookedAt;
    data['isBooked'] = isBooked;
    return data;
  }
}
