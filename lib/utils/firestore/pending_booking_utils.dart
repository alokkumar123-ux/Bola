import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/model/pending_booking_model.dart';

class PendingBookingUtils {
  static const String _collection = 'pending_bookings';

  /// Create a pending booking record before payment initiation
  static Future<String?> createPendingBooking(PendingBookingModel model) async {
    try {
      final docRef = FirebaseFirestore.instance.collection(_collection).doc();
      model.id = docRef.id;
      await docRef.set(model.toJson());
      return docRef.id;
    } catch (e) {
      print('Error creating pending booking: $e');
      return null;
    }
  }

  /// Get pending booking by orderId
  static Future<PendingBookingModel?> getPendingBookingByOrderId(
      String orderId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return PendingBookingModel.fromJson(snapshot.docs.first.data());
    } catch (e) {
      print('Error getting pending booking: $e');
      return null;
    }
  }

  /// Get all pending bookings for a user (for recovery on app restart)
  static Future<List<PendingBookingModel>> getPendingBookingsForUser(
      String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs
          .map((doc) => PendingBookingModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting pending bookings for user: $e');
      return [];
    }
  }

  /// Update pending booking status
  static Future<bool> updateStatus(String id, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(id)
          .update({'status': status});
      return true;
    } catch (e) {
      print('Error updating pending booking status: $e');
      return false;
    }
  }

  /// Delete pending booking after successful processing or failure
  static Future<bool> deletePendingBooking(String id) async {
    try {
      await FirebaseFirestore.instance.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting pending booking: $e');
      return false;
    }
  }

  /// Delete pending booking by orderId
  static Future<bool> deletePendingBookingByOrderId(String orderId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('orderId', isEqualTo: orderId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      print('Error deleting pending booking by orderId: $e');
      return false;
    }
  }
}
