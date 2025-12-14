import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralModel {
  String? referralCode;
  String? referralBy; // legacy field, keep for backward compatibility
  String? referrerId;
  String? referredUserId;
  String? id;
  Timestamp? createdAt;

  ReferralModel(
      {this.referralCode,
      this.referralBy,
      this.referrerId,
      this.referredUserId,
      this.id,
      this.createdAt});

  ReferralModel.fromJson(Map<String, dynamic> json) {
    referralCode = json['referralCode'];
    referralBy = json['referralBy'];
    referrerId = json['referrerId'];
    referredUserId = json['referredUserId'];
    id = json['id'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['referralCode'] = referralCode;
    data['referralBy'] = referralBy;
    data['referrerId'] = referrerId ?? referralBy;
    data['referredUserId'] = referredUserId;
    data['id'] = id;
    data['createdAt'] = createdAt;
    return data;
  }
}
