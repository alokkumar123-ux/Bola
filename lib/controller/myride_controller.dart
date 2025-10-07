import 'dart:async';
import 'package:get/get.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/utils/fire_store_utils.dart';

class MyRideController extends GetxController {
  late StreamSubscription<List<BookingModel>> _myBookingSubscription;
  late StreamSubscription<List<BookingModel>> _publisherBookingSubscription;
  late StreamSubscription<List<BookingModel>> _cancelledBookingSubscription;
  late StreamSubscription<List<BookingModel>> _completedBookingSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeStreams();
  }

  @override
  void onClose() {
    _myBookingSubscription.cancel();
    _publisherBookingSubscription.cancel();
    _cancelledBookingSubscription.cancel();
    _completedBookingSubscription.cancel();
    super.onClose();
  }

  RxBool isLoading = true.obs;
  RxList<BookingModel> myBooking = <BookingModel>[].obs;
  RxList<BookingModel> publisherBooking = <BookingModel>[].obs;
  RxList<BookingModel> cancelledBooking = <BookingModel>[].obs;
  RxList<BookingModel> completedBooking = <BookingModel>[].obs;

  void _initializeStreams() {
    print("=== MyRideController: Initializing real-time streams ===");

    // Subscribe to My Bookings stream
    _myBookingSubscription = FireStoreUtils.getMyBookingStream().listen(
      (bookings) {
        myBooking.value = bookings;
        print("REAL-TIME: MyBookings updated - Count: ${bookings.length}");
        _checkIfAllDataLoaded();
      },
      onError: (error) {
        print("Error in MyBookings stream: $error");
        _checkIfAllDataLoaded();
      },
    );

    // Subscribe to Publisher Bookings stream
    _publisherBookingSubscription = FireStoreUtils.getPublishesStream().listen(
      (bookings) {
        publisherBooking.value = bookings;
        print(
            "REAL-TIME: PublisherBookings updated - Count: ${bookings.length}");
        _checkIfAllDataLoaded();
      },
      onError: (error) {
        print("Error in PublisherBookings stream: $error");
        _checkIfAllDataLoaded();
      },
    );

    // Subscribe to Cancelled Bookings stream
    _cancelledBookingSubscription =
        FireStoreUtils.getCancelledBookingsStream().listen(
      (bookings) {
        cancelledBooking.value = bookings;
        print(
            "REAL-TIME: CancelledBookings updated - Count: ${bookings.length}");
        for (var booking in bookings) {
          print(
              "  - Cancelled: ${booking.id}: ${booking.status} (createdBy: ${booking.createdBy})");
        }
        _checkIfAllDataLoaded();
      },
      onError: (error) {
        print("Error in CancelledBookings stream: $error");
        _checkIfAllDataLoaded();
      },
    );

    // Subscribe to Completed Bookings stream
    _completedBookingSubscription =
        FireStoreUtils.getCompletedBookingsStream().listen(
      (bookings) {
        completedBooking.value = bookings;
        print(
            "REAL-TIME: CompletedBookings updated - Count: ${bookings.length}");
        for (var booking in bookings) {
          print("  - ${booking.id}: ${booking.status}");
        }
        _checkIfAllDataLoaded();
      },
      onError: (error) {
        print("Error in CompletedBookings stream: $error");
        _checkIfAllDataLoaded();
      },
    );
  }

  void _checkIfAllDataLoaded() {
    // Set loading to false after initial data is loaded
    if (isLoading.value) {
      isLoading.value = false;
      print("=== MyRideController: All streams initialized ===");
    }
  }

  // Keep this method for backward compatibility and manual refresh
  getBookedRight() async {
    print("=== Manual refresh triggered ===");
    // The streams will automatically refresh, but we can trigger reload if needed
    isLoading.value = true;

    // Wait a moment for the streams to emit new data
    await Future.delayed(const Duration(milliseconds: 500));

    _checkIfAllDataLoaded();
  }
}
