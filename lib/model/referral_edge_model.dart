import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralEdgeModel {
  String? id; // document id, typically referredUserId
  String? referrerId;
  String? referredUserId;
  String? referralCodeUsed;
  Timestamp? createdAt;
  int? rideCount; // number of completed rides processed for this referred user
  bool? firstRideRewardGiven; // whether 1% first-ride reward already granted
  String? lastBookingId;
  String? totalEarnedFromUser; // aggregate earned from this referred user

  ReferralEdgeModel({
    this.id,
    this.referrerId,
    this.referredUserId,
    this.referralCodeUsed,
    this.createdAt,
    this.rideCount,
    this.firstRideRewardGiven,
    this.lastBookingId,
    this.totalEarnedFromUser,
  });

  ReferralEdgeModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    referrerId = json['referrerId'];
    referredUserId = json['referredUserId'];
    referralCodeUsed = json['referralCodeUsed'];
    createdAt = json['createdAt'];
    rideCount = json['rideCount'];
    firstRideRewardGiven = json['firstRideRewardGiven'] ?? false;
    lastBookingId = json['lastBookingId'];
    totalEarnedFromUser = json['totalEarnedFromUser'] ?? '0';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['referrerId'] = referrerId;
    data['referredUserId'] = referredUserId;
    data['referralCodeUsed'] = referralCodeUsed;
    data['createdAt'] = createdAt;
    data['rideCount'] = rideCount;
    data['firstRideRewardGiven'] = firstRideRewardGiven;
    data['lastBookingId'] = lastBookingId;
    data['totalEarnedFromUser'] = totalEarnedFromUser;
    return data;
  }
}
