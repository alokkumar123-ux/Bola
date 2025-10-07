import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/seat_booking_model.dart';
import 'package:poolmate/utils/fire_store_utils.dart';

class SeatBookingController extends GetxController {
  RxList<String> selectedSeats = <String>[].obs;
  RxInt numberOfSelectedSeats = 1.obs;

  // Initialize seats for a booking
  List<SeatBooking> initializeSeats(int totalSeats) {
    return List.generate(
      totalSeats,
      (index) => SeatBooking(
        seatNumber: (index + 1).toString(),
        isBooked: false,
      ),
    );
  }

  // Book selected seats
  Future<bool> bookSeats(BookingModel booking) async {
    try {
      // Validate selected seats
      if (selectedSeats.isEmpty) {
        return false;
      }

      // Initialize seat bookings if not exist
      if (booking.seatBookings == null) {
        int totalSeats = int.tryParse(booking.totalSeat ?? '0') ?? 0;
        booking.seatBookings = initializeSeats(totalSeats);
      }

      // Mark selected seats as booked
      for (var seatNumber in selectedSeats) {
        var seatIndex = booking.seatBookings!
            .indexWhere((seat) => seat.seatNumber == seatNumber);

        if (seatIndex != -1) {
          booking.seatBookings![seatIndex] = SeatBooking(
            seatNumber: seatNumber,
            userId: FireStoreUtils.getCurrentUid(),
            bookedAt: Timestamp.now(),
            isBooked: true,
          );
        }
      }

      // Update booking in Firestore
      return await FireStoreUtils.setBooking(booking) ?? false;
    } catch (e) {
      print('Error booking seats: $e');
      return false;
    }
  }

  // Get available seats
  List<String> getAvailableSeats(BookingModel booking) {
    if (booking.seatBookings == null) {
      int totalSeats = int.tryParse(booking.totalSeat ?? '0') ?? 0;
      return List.generate(totalSeats, (index) => (index + 1).toString());
    }

    return booking.seatBookings!
        .where((seat) => seat.isBooked != true)
        .map((seat) => seat.seatNumber!)
        .toList();
  }

  // Get booked seats
  List<String> getBookedSeats(BookingModel booking) {
    if (booking.seatBookings == null) {
      return [];
    }

    return booking.seatBookings!
        .where((seat) => seat.isBooked == true)
        .map((seat) => seat.seatNumber!)
        .toList();
  }

  // Calculate number of available seats
  int getAvailableSeatsCount(BookingModel booking) {
    int totalSeats = int.tryParse(booking.totalSeat ?? '0') ?? 0;
    int bookedSeats =
        booking.seatBookings?.where((seat) => seat.isBooked == true).length ??
            0;
    return totalSeats - bookedSeats;
  }

  // Select a seat
  void toggleSeatSelection(String seatNumber) {
    if (selectedSeats.contains(seatNumber)) {
      selectedSeats.remove(seatNumber);
    } else {
      if (selectedSeats.length < numberOfSelectedSeats.value) {
        selectedSeats.add(seatNumber);
      }
    }
  }

  // Reset selections
  void resetSelections() {
    selectedSeats.clear();
    numberOfSelectedSeats.value = 1;
  }
}
