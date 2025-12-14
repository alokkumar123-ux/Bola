import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralEarningModel {
  String? id;
  String? referrerId;
  String? referredUserId;
  String? bookingId;
  String? amount; // stored as string for consistency with wallet
  double? rate; // commission rate applied (e.g., 0.01 or 0.03)
  int? rideNumberForUser; // the nth ride for the referred user
  String? status; // pending, credited, skipped
  String? note;
  Timestamp? createdAt;

  ReferralEarningModel({
    this.id,
    this.referrerId,
    this.referredUserId,
    this.bookingId,
    this.amount,
    this.rate,
    this.rideNumberForUser,
    this.status,
    this.note,
    this.createdAt,
  });

  ReferralEarningModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    referrerId = json['referrerId'];
    referredUserId = json['referredUserId'];
    bookingId = json['bookingId'];
    amount = json['amount'];
    rate =
        json['rate'] != null ? double.tryParse(json['rate'].toString()) : null;
    rideNumberForUser = json['rideNumberForUser'];
    status = json['status'];
    note = json['note'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['referrerId'] = referrerId;
    data['referredUserId'] = referredUserId;
    data['bookingId'] = bookingId;
    data['amount'] = amount;
    data['rate'] = rate;
    data['rideNumberForUser'] = rideNumberForUser;
    data['status'] = status;
    data['note'] = note;
    data['createdAt'] = createdAt;
    return data;
  }
}
