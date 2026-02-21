import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';

/// Booking and ride management utilities
class BookingUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  /// Create or update booking
  static Future<bool?> setBooking(BookingModel bookingModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .set(bookingModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      print("Failed to set booking: $error");
      isAdded = false;
    });
    return isAdded;
  }

  /// Delete booking
  static Future<bool?> deleteBooking(BookingModel bookingModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .delete()
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      print("Failed to delete booking: $error");
      isAdded = false;
    });
    return isAdded;
  }

  /// Get published bookings by current user
  static Future<List<BookingModel>?> getPublishes() async {
    List<BookingModel>? bookingList = [];
    await fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: AuthUtils.getCurrentUid())
        .orderBy("createdAt", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        bookingList.add(BookingModel.fromJson(element.data()));
      }
    }).catchError((error) {
      print("Failed to get publishes: $error");
    });
    return bookingList;
  }

  /// Check active published bookings
  static Future<List<BookingModel>?> checkActivePublishes() async {
    List<BookingModel>? bookingList = [];
    await fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: AuthUtils.getCurrentUid())
        .where("status", isNotEqualTo: Constant.completed)
        .where('publish', isEqualTo: true)
        .orderBy("createdAt", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        bookingList.add(BookingModel.fromJson(element.data()));
      }
    }).catchError((error) {
      print("Failed to check active publishes: $error");
    });
    return bookingList;
  }

  /// Get bookings current user is participating in
  static Future<List<BookingModel>?> getMyBooking() async {
    List<BookingModel>? bookingList = [];
    await fireStore
        .collection(CollectionName.booking)
        .where("bookedUserId", arrayContains: AuthUtils.getCurrentUid())
        .orderBy("createdAt", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        bookingList.add(BookingModel.fromJson(element.data()));
      }
    }).catchError((error) {
      print("Failed to get my bookings: $error");
    });
    return bookingList;
  }

  /// Get booking by ID
  static Future<BookingModel?> getMyBookingByUserId(String id) async {
    BookingModel? bookingList;
    await fireStore
        .collection(CollectionName.booking)
        .doc(id)
        .get()
        .then((value) {
      if (value.exists) {
        bookingList = BookingModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      print("Failed to get booking: $error");
    });
    return bookingList;
  }

  static Future<BookedUserModel?> getMyBookingUser(
      BookingModel bookingModel) async {
    BookedUserModel? bookingUserModel;
    String currentUserId = AuthUtils.getCurrentUid();

    try {
      // First, try to get from bookedUser subcollection
      await fireStore
          .collection(CollectionName.booking)
          .doc(bookingModel.id)
          .collection("bookedUser")
          .doc(currentUserId)
          .get()
          .then((value) {
        if (value.exists) {
          bookingUserModel = BookedUserModel.fromJson(value.data()!);
          print(
              "Found user in bookedUser subcollection for booking: ${bookingModel.id}");
        }
      }).catchError((error) {
        print("Error checking bookedUser: $error");
      });

      // If not found in bookedUser, check cancelledUser subcollection
      if (bookingUserModel == null) {
        await fireStore
            .collection(CollectionName.booking)
            .doc(bookingModel.id)
            .collection("cancelledUser")
            .doc(currentUserId)
            .get()
            .then((value) {
          if (value.exists) {
            bookingUserModel = BookedUserModel.fromJson(value.data()!);
            print(
                "Found user in cancelledUser subcollection for booking: ${bookingModel.id}");
          }
        }).catchError((error) {
          print("Error checking cancelledUser: $error");
        });
      }

      if (bookingUserModel == null) {
        print(
            "BookedUserModel not found for booking: ${bookingModel.id}, status: ${bookingModel.status}");
      }
    } catch (error) {
      print("Error in getMyBookingUser: $error");
    }

    return bookingUserModel;
  }

  static Future<List<BookedUserModel>?> getMyBookingUserList(
      BookingModel bookingModel) async {
    List<BookedUserModel>? bookingList = [];
    await fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .collection("bookedUser")
        .get()
        .then((value) {
      for (var element in value.docs) {
        BookedUserModel documentModel =
            BookedUserModel.fromJson(element.data());
        bookingList.add(documentModel);
      }
    }).catchError((error) {
      print("Failed to update user: $error");
    });
    return bookingList;
  }

  static Future<bool?> setUserBooking(
      BookingModel bookingModel, BookedUserModel bookingUserModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .collection("bookedUser")
        .doc(bookingUserModel.id)
        .set(bookingUserModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      print("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  // Real-time stream for BookedUserModel - checks both bookedUser and cancelledUser
  static Stream<BookedUserModel?> getMyBookingUserStream(
      BookingModel bookingModel) {
    String currentUserId = AuthUtils.getCurrentUid();

    // Check bookedUser collection first
    Stream<BookedUserModel?> bookedUserStream = fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .collection("bookedUser")
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return BookedUserModel.fromJson(snapshot.data()!);
      }
      return null;
    });

    // Check cancelledUser collection
    Stream<BookedUserModel?> cancelledUserStream = fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .collection("cancelledUser")
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return BookedUserModel.fromJson(snapshot.data()!);
      }
      return null;
    });

    // Combine both streams - return bookedUser if exists, otherwise cancelledUser
    return Rx.combineLatest2(bookedUserStream, cancelledUserStream,
        (BookedUserModel? bookedUser, BookedUserModel? cancelledUser) {
      return bookedUser ?? cancelledUser;
    });
  }

  /// Get cancelled bookings
  static Future<List<BookingModel>?> getCancelledBookings() async {
    List<BookingModel>? bookingList = [];
    await fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: AuthUtils.getCurrentUid())
        .where("status", isEqualTo: Constant.canceled)
        .orderBy("createdAt", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        bookingList.add(BookingModel.fromJson(element.data()));
      }
    }).catchError((error) {
      print("Failed to get cancelled bookings: $error");
    });
    return bookingList;
  }

  /// Get completed bookings
  static Future<List<BookingModel>?> getCompletedBookings() async {
    List<BookingModel>? bookingList = [];
    await fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: AuthUtils.getCurrentUid())
        .where("status", isEqualTo: Constant.completed)
        .orderBy("createdAt", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        bookingList.add(BookingModel.fromJson(element.data()));
      }
    }).catchError((error) {
      print("Failed to get completed bookings: $error");
    });
    return bookingList;
  }

  // ==================== Real-time Streams ====================

  /// Stream of my bookings
  static Stream<List<BookingModel>> getMyBookingStream() {
    String currentUid = AuthUtils.getCurrentUid();
    return fireStore
        .collection(CollectionName.booking)
        .where("bookedUserId", arrayContains: currentUid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      List<BookingModel> bookingList = [];
      for (var doc in snapshot.docs) {
        BookingModel documentModel = BookingModel.fromJson(doc.data());
        documentModel.id = doc.id;
        bookingList.add(documentModel);
      }
      return bookingList;
    });
  }

  /// Stream of published bookings
  static Stream<List<BookingModel>> getPublishesStream() {
    String currentUid = AuthUtils.getCurrentUid();
    return fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: currentUid)
        .where("status", whereNotIn: [Constant.completed, Constant.canceled])
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          List<BookingModel> bookingList = [];
          for (var doc in snapshot.docs) {
            BookingModel documentModel = BookingModel.fromJson(doc.data());
            documentModel.id = doc.id;
            bookingList.add(documentModel);
          }
          return bookingList;
        });
  }

  /// Stream of cancelled bookings (combined driver and passenger)
  static Stream<List<BookingModel>> getCancelledBookingsStream() {
    String currentUid = AuthUtils.getCurrentUid();

    // Driver's cancelled rides (where user created the booking)
    Stream<List<BookingModel>> driverStream = fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: currentUid)
        .where("status", isEqualTo: Constant.canceled)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(_mapBookingSnapshot);

    // Passenger's cancelled rides (still in bookedUserId - ride was cancelled by driver)
    Stream<List<BookingModel>> passengerBookedStream = fireStore
        .collection(CollectionName.booking)
        .where("bookedUserId", arrayContains: currentUid)
        .where("status", isEqualTo: Constant.canceled)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(_mapBookingSnapshot);

    // Passenger's cancelled rides (moved to cancelledUserId - passenger cancelled their booking)
    Stream<List<BookingModel>> passengerCancelledStream = fireStore
        .collection(CollectionName.booking)
        .where("cancelledUserId", arrayContains: currentUid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(_mapBookingSnapshot);

    return Rx.combineLatest3(
        driverStream, passengerBookedStream, passengerCancelledStream,
        (List<BookingModel> driverBookings,
            List<BookingModel> passengerBookedBookings,
            List<BookingModel> passengerCancelledBookings) {
      return _deduplicateBookings(driverBookings +
          passengerBookedBookings +
          passengerCancelledBookings);
    });
  }

  /// Stream of completed bookings (combined driver and passenger)
  static Stream<List<BookingModel>> getCompletedBookingsStream() {
    String currentUid = AuthUtils.getCurrentUid();

    Stream<List<BookingModel>> driverStream = fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: currentUid)
        .where("status", isEqualTo: Constant.completed)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(_mapBookingSnapshot);

    Stream<List<BookingModel>> passengerStream = fireStore
        .collection(CollectionName.booking)
        .where("bookedUserId", arrayContains: currentUid)
        .where("status", isEqualTo: Constant.completed)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(_mapBookingSnapshot);

    return Rx.combineLatest2(driverStream, passengerStream,
        (List<BookingModel> driverBookings,
            List<BookingModel> passengerBookings) {
      return _deduplicateBookings(driverBookings + passengerBookings);
    });
  }

  static Future<List<BookingModel>?> checkAtivePublishes() async {
    List<BookingModel>? bookingList = [];

    await fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: AuthUtils.getCurrentUid())
        .where("status", isNotEqualTo: Constant.completed)
        .where('publish', isEqualTo: true)
        .orderBy("createdAt", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        print("BookingList :: ${element.id}");
        BookingModel documentModel = BookingModel.fromJson(element.data());
        bookingList.add(documentModel);
      }
    }).catchError((error) {
      print("Failed to update user: $error");
    });
    return bookingList;
  }

  // ==================== Helper Methods ====================

  static List<BookingModel> _mapBookingSnapshot(QuerySnapshot snapshot) {
    List<BookingModel> bookingList = [];
    for (var doc in snapshot.docs) {
      BookingModel documentModel =
          BookingModel.fromJson(doc.data() as Map<String, dynamic>);
      documentModel.id = doc.id;
      bookingList.add(documentModel);
    }
    return bookingList;
  }

  static List<BookingModel> _deduplicateBookings(List<BookingModel> bookings) {
    Set<String> addedIds = {};
    List<BookingModel> uniqueBookings = [];

    for (var booking in bookings) {
      if (!addedIds.contains(booking.id)) {
        uniqueBookings.add(booking);
        addedIds.add(booking.id!);
      }
    }

    uniqueBookings.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) return 0;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return uniqueBookings;
  }

  // ==================== Booking User Management ====================

  /// Remove user from booking
  static Future<bool?> removeUserBooking(
      BookingModel bookingModel, dynamic bookingUserModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .collection("bookedUser")
        .doc(bookingUserModel.id)
        .delete()
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      print("Failed to remove user booking: $error");
      isAdded = false;
    });
    return isAdded;
  }

  /// Move user to cancelled bookings
  static Future<bool?> setCancelledUserBooking(
      BookingModel bookingModel, dynamic bookingUserModel) async {
    bool isSuccess = false;

    try {
      await fireStore.runTransaction((transaction) async {
        // Get references
        final bookingRef =
            fireStore.collection(CollectionName.booking).doc(bookingModel.id);
        final cancelledUserRef =
            bookingRef.collection("cancelledUser").doc(bookingUserModel.id);
        final bookedUserRef =
            bookingRef.collection("bookedUser").doc(bookingUserModel.id);

        // Add to cancelled users
        transaction.set(cancelledUserRef, bookingUserModel.toJson());

        // Update main booking document
        transaction.update(bookingRef, {
          'bookedSeat': bookingModel.bookedSeat!
              .replaceAll(bookingUserModel.bookedSeat.toString(), ""),
          'selectedSeats': bookingModel.selectedSeats,
          'bookedUserId': bookingModel.bookedUserId,
          'cancelledUserId': bookingModel.cancelledUserId,
          'seatBookings':
              bookingModel.seatBookings?.map((e) => e.toJson()).toList()
        });

        // Remove from booked users
        transaction.delete(bookedUserRef);
      });

      isSuccess = true;
    } catch (error) {
      print('Error in setCancelledUserBooking: $error');
      isSuccess = false;
    }

    return isSuccess;
  }

  // Convert stored seat indices CSV (e.g., "1,2") to labels CSV (e.g., "A1,A2")
  static String formatSeatLabelsCsv(String? csv) {
    if (csv == null || csv.trim().isEmpty) return 'No';
    final parts =
        csv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    // Filter out seat index 0 (A1 - driver's seat) as it's always occupied by the driver
    final passengerSeats =
        parts.where((p) => (int.tryParse(p) ?? -1) != 0).map((p) {
      final idx = int.tryParse(p) ?? -1;
      return seatIndexToLabel(idx);
    }).toList();

    // If no passenger seats are booked (only driver seat), return 'No'
    if (passengerSeats.isEmpty) return 'No';

    return passengerSeats.join(',');
  }

  static String seatIndexToLabel(int index) {
    const labels = ['A1', 'A2', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3'];
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return 'S$index';
  }

  /// Allocate seats for a new booking
  /// [currentBookedSeats] - CSV string of currently booked seats (e.g. "0,1")
  /// [seatsNeeded] - Number of seats to allocate
  /// [totalSeats] - Total capacity of the vehicle
  /// Returns updated CSV string with new seats appended (e.g. "0,1,2,3")
  static String allocateSeats(
      String? currentBookedSeats, int seatsNeeded, int totalSeats) {
    Set<int> occupied = {};

    if (currentBookedSeats != null && currentBookedSeats.isNotEmpty) {
      final parts = currentBookedSeats.split(',');
      for (var part in parts) {
        final idx = int.tryParse(part.trim());
        if (idx != null) {
          occupied.add(idx);
        }
      }
    } else {
      // If empty, assume driver (0) is occupied if that's the convention,
      // but strictly speaking if the string is empty, we start fresh.
      // However, usually "0" is present.
      // Let's rely on the input string.
    }

    List<int> newAllocations = [];
    int seatsFound = 0;

    // Iterate through all possible indices to find available ones
    // We assume seat indices are 0-based: 0 to totalSeats-1
    for (int i = 0; i < totalSeats; i++) {
      if (!occupied.contains(i)) {
        newAllocations.add(i);
        seatsFound++;
        if (seatsFound >= seatsNeeded) break;
      }
    }

    if (seatsFound < seatsNeeded) {
      // Not enough seats available
      // This refers to a race condition or logic error upstream
      throw Exception("Not enough seats available");
    }

    // Add new allocations to occupied set for the result
    occupied.addAll(newAllocations);

    // Convert back to CSV, sorted for consistency
    final sortedList = occupied.toList()..sort();
    return sortedList.join(',');
  }
}
