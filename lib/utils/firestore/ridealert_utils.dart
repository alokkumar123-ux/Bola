import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/map/geometry.dart';
import 'package:poolmate/model/ride_alert_model.dart';


class RideAlertUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  /// Create or update a ride alert
  static Future<bool> setRideAlert(RideAlertModel rideAlertModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.rideAlerts)
        .doc(rideAlertModel.id)
        .set(rideAlertModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      print("Failed to create ride alert: $error");
      isAdded = false;
    });
    return isAdded;
  }

  /// Get active ride alerts for a user
  static Future<List<RideAlertModel>?> getUserActiveRideAlerts(
      String userId) async {
    List<RideAlertModel> list = [];

    await fireStore
        .collection(CollectionName.rideAlerts)
        .where("userId", isEqualTo: userId)
        .where("isActive", isEqualTo: true)
        .where("expiryDate", isGreaterThanOrEqualTo: Timestamp.now())
        .get()
        .then((value) {
      for (var element in value.docs) {
        RideAlertModel alertModel = RideAlertModel.fromJson(element.data());
        list.add(alertModel);
      }
    }).catchError((error) {
      print("Error fetching active ride alerts: $error");
    });

    return list;
  }

  /// Deactivate a ride alert
  static Future<bool> deactivateRideAlert(String alertId) async {
    bool success = false;
    await fireStore
        .collection(CollectionName.rideAlerts)
        .doc(alertId)
        .update({'isActive': false}).then((value) {
      success = true;
    }).catchError((error) {
      print("Failed to deactivate ride alert: $error");
      success = false;
    });
    return success;
  }

  /// Clean up expired ride alerts (can be called periodically)
  static Future<void> cleanupExpiredRideAlerts() async {
    try {
      final expiredAlerts = await fireStore
          .collection(CollectionName.rideAlerts)
          .where("expiryDate", isLessThan: Timestamp.now())
          .where("isActive", isEqualTo: true)
          .get();

      for (var doc in expiredAlerts.docs) {
        await doc.reference.update({'isActive': false});
      }
      print("Cleaned up ${expiredAlerts.docs.length} expired ride alerts");
    } catch (error) {
      print("Error cleaning up expired ride alerts: $error");
    }
  }

  /// Check if a booking matches a ride alert criteria
  static Future<List<RideAlertModel>> getMatchingRideAlerts(
      BookingModel booking) async {
    List<RideAlertModel> matchingAlerts = [];

    try {
      // Get all active alerts that expire on or after the booking's departure date
      final alertsSnapshot = await fireStore
          .collection(CollectionName.rideAlerts)
          .where("isActive", isEqualTo: true)
          .where("expiryDate",
              isGreaterThanOrEqualTo: booking.departureDateTime)
          .where("expiryDate",
              isLessThanOrEqualTo: Timestamp.fromDate(booking.departureDateTime!
                  .toDate()
                  .add(const Duration(days: 1))))
          .get();

      for (var doc in alertsSnapshot.docs) {
        RideAlertModel alert = RideAlertModel.fromJson(doc.data());

        // Don't alert the person who published the ride
        if (alert.userId == booking.createdBy) {
          continue;
        }

        // Check if alert has expired
        if (alert.expiryDate != null &&
            alert.expiryDate!.toDate().isBefore(DateTime.now())) {
          continue;
        }

        // Check if the alert matches this booking's route using location matching
        if (_doesAlertMatchBookingRoute(alert, booking)) {
          matchingAlerts.add(alert);
        }
      }
    } catch (error) {
      // Error finding matching ride alerts
    }

    return matchingAlerts;
  }

  /// Helper method to check if a ride alert matches a booking's route
  /// Uses the same matching logic as pickupIsSame() from home_controller
  static bool _doesAlertMatchBookingRoute(
      RideAlertModel alert, BookingModel booking) {
    // Check if booking has stopOverList
    if (booking.stopOverList == null || booking.stopOverList!.isEmpty) {
      return false;
    }

    // Check if alert has valid pickup and drop locations
    if (alert.pickUpLocation == null || alert.dropLocation == null) {
      return false;
    }

    bool isPickUpMatched = false;
    bool isDropOffMatched = false;

    // Iterate through all stopOvers in the booking to find matching pickup and drop
    for (var stopOver in booking.stopOverList!) {
      // Skip if stopOver doesn't have valid location data
      if (stopOver.startLocation == null || stopOver.endLocation == null) {
        continue;
      }

      // Calculate distance between alert pickup and stopOver start location
      double distancePickup = Constant.calculateDistance(
          Location(
              lat: stopOver.startLocation!.lat,
              lng: stopOver.startLocation!.lng),
          Location(
              lat: alert.pickUpLocation!.lat, lng: alert.pickUpLocation!.lng));

      // Calculate distance between alert drop and stopOver end location
      double distanceDrop = Constant.calculateDistance(
          Location(
              lat: stopOver.endLocation!.lat, lng: stopOver.endLocation!.lng),
          Location(lat: alert.dropLocation!.lat, lng: alert.dropLocation!.lng));

      // Check if pickup is within radius
      if (distancePickup <= double.parse(Constant.radius)) {
        isPickUpMatched = true;
      }

      // Check if drop is within radius
      if (distanceDrop <= double.parse(Constant.radius)) {
        isDropOffMatched = true;
      }

      // If both pickup and drop are matched in this stopOver, alert matches this booking
      if (isPickUpMatched && isDropOffMatched) {
        return true;
      }

      // Reset for next iteration
      isPickUpMatched = false;
      isDropOffMatched = false;
    }

    return false;
  }
}
