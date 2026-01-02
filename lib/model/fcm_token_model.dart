import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for storing FCM tokens with device information
/// Supports multi-device per user
class FcmTokenModel {
  String token;
  String deviceId;
  String platform; // 'android' or 'ios'
  Timestamp createdAt;
  Timestamp lastUsedAt;
  bool isActive;

  FcmTokenModel({
    required this.token,
    required this.deviceId,
    required this.platform,
    required this.createdAt,
    required this.lastUsedAt,
    this.isActive = true,
  });

  factory FcmTokenModel.fromJson(Map<String, dynamic> json) {
    return FcmTokenModel(
      token: json['token'] ?? '',
      deviceId: json['deviceId'] ?? '',
      platform: json['platform'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      lastUsedAt: json['lastUsedAt'] ?? Timestamp.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'deviceId': deviceId,
      'platform': platform,
      'createdAt': createdAt,
      'lastUsedAt': lastUsedAt,
      'isActive': isActive,
    };
  }

  @override
  String toString() {
    return 'FcmTokenModel(token: ${token.substring(0, 20)}..., deviceId: $deviceId, platform: $platform, isActive: $isActive)';
  }
}
