import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/model/fcm_token_model.dart';

/// Firestore utilities for FCM token management
/// Handles multi-device token storage in fcm_tokens subcollection
class FcmTokenUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save or update FCM token for a user device
  /// Creates/updates document in users/{userId}/fcm_tokens/{deviceId}
  static Future<void> saveToken({
    required String userId,
    required FcmTokenModel tokenModel,
  }) async {
    if (userId.isEmpty) {
      print('🔔 FcmTokenUtils: Cannot save token - userId is empty');
      return;
    }

    try {
      print(
          '🔔 Saving FCM token for user: $userId, device: ${tokenModel.deviceId}');

      await _firestore
          .collection(CollectionName.users)
          .doc(userId)
          .collection(CollectionName.fcmTokens)
          .doc(tokenModel.deviceId)
          .set(tokenModel.toJson(), SetOptions(merge: true));

      // Also update the legacy fcmToken field for backward compatibility
      await _firestore
          .collection(CollectionName.users)
          .doc(userId)
          .update({'fcmToken': tokenModel.token});

      print('✅ FCM token saved successfully');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Update the lastUsedAt timestamp for a token
  static Future<void> updateTokenLastUsed({
    required String userId,
    required String deviceId,
  }) async {
    try {
      await _firestore
          .collection(CollectionName.users)
          .doc(userId)
          .collection(CollectionName.fcmTokens)
          .doc(deviceId)
          .update({'lastUsedAt': Timestamp.now()});
    } catch (e) {
      print('❌ Error updating token lastUsedAt: $e');
    }
  }

  /// Remove a specific device token
  static Future<void> removeToken({
    required String userId,
    required String deviceId,
  }) async {
    try {
      print('🔔 Removing FCM token for device: $deviceId');
      await _firestore
          .collection(CollectionName.users)
          .doc(userId)
          .collection(CollectionName.fcmTokens)
          .doc(deviceId)
          .delete();
      print('✅ FCM token removed');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }

  /// Deactivate all tokens for a user (used on logout)
  static Future<void> deactivateAllTokens(String userId) async {
    if (userId.isEmpty) return;

    try {
      print('🔔 Deactivating all FCM tokens for user: $userId');

      final tokensSnapshot = await _firestore
          .collection(CollectionName.users)
          .doc(userId)
          .collection(CollectionName.fcmTokens)
          .get();

      final batch = _firestore.batch();
      for (var doc in tokensSnapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      await batch.commit();

      // Clear legacy fcmToken field
      await _firestore
          .collection(CollectionName.users)
          .doc(userId)
          .update({'fcmToken': ''});

      print('✅ All FCM tokens deactivated');
    } catch (e) {
      print('❌ Error deactivating FCM tokens: $e');
    }
  }

  /// Deactivate a specific device token (for logout on single device)
  static Future<void> deactivateToken({
    required String userId,
    required String deviceId,
  }) async {
    if (userId.isEmpty || deviceId.isEmpty) return;

    try {
      print('🔔 Deactivating FCM token for device: $deviceId');

      await _firestore
          .collection(CollectionName.users)
          .doc(userId)
          .collection(CollectionName.fcmTokens)
          .doc(deviceId)
          .update({'isActive': false});

      print('✅ FCM token deactivated');
    } catch (e) {
      print('❌ Error deactivating FCM token: $e');
    }
  }

  /// Get all active tokens for a user (for sending notifications to multiple devices)
  static Future<List<FcmTokenModel>> getActiveTokens(String userId) async {
    if (userId.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection(CollectionName.users)
          .doc(userId)
          .collection(CollectionName.fcmTokens)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => FcmTokenModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting active FCM tokens: $e');
      return [];
    }
  }

  /// Delete an invalid token when FCM reports it as unregistered
  static Future<void> deleteInvalidToken({
    required String userId,
    required String token,
  }) async {
    if (userId.isEmpty || token.isEmpty) return;

    try {
      print('🔔 Deleting invalid FCM token');

      final snapshot = await _firestore
          .collection(CollectionName.users)
          .doc(userId)
          .collection(CollectionName.fcmTokens)
          .where('token', isEqualTo: token)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Invalid FCM token deleted');
    } catch (e) {
      print('❌ Error deleting invalid FCM token: $e');
    }
  }
}
