import 'package:get/get.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/review_model.dart';
import 'package:poolmate/utils/firestore/review_utils.dart';

class PassengerDetailsController extends GetxController {
  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  Rx<BookingModel> bookingModel = BookingModel().obs;
  Rx<BookedUserModel> bookingUserModel = BookedUserModel().obs;
  RxBool isLoading = true.obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      bookingModel.value = argumentData['bookingModel'];
      bookingUserModel.value = argumentData['bookingUserModel'];
    }
    await getReview();
    isLoading.value = false;
  }

  // Helper method to get the correct price per seat
  // Checks if the booking matches a preset stopover or uses bookingModel.pricePerSeat
  double getCorrectPricePerSeat() {
    // Get the stopOver from bookingUserModel
    final stopOver = bookingUserModel.value.stopOver;
    if (stopOver == null) {
      // Fallback to bookingModel pricePerSeat if stopOver is null
      return double.tryParse(bookingModel.value.pricePerSeat ?? '0') ?? 0.0;
    }

    // Check if it's a full route booking
    final bookingPickupLat =
        bookingModel.value.pickupLocation?.geometry?.location?.lat;
    final bookingPickupLng =
        bookingModel.value.pickupLocation?.geometry?.location?.lng;
    final bookingDropLat =
        bookingModel.value.dropLocation?.geometry?.location?.lat;
    final bookingDropLng =
        bookingModel.value.dropLocation?.geometry?.location?.lng;

    final stopOverStartLat = stopOver.startLocation?.lat;
    final stopOverStartLng = stopOver.startLocation?.lng;
    final stopOverEndLat = stopOver.endLocation?.lat;
    final stopOverEndLng = stopOver.endLocation?.lng;

    if (bookingPickupLat != null &&
        bookingPickupLng != null &&
        bookingDropLat != null &&
        bookingDropLng != null &&
        stopOverStartLat != null &&
        stopOverStartLng != null &&
        stopOverEndLat != null &&
        stopOverEndLng != null) {
      // Check if it's a full route (start and end match booking's pickup and drop)
      bool startMatches = (bookingPickupLat - stopOverStartLat).abs() < 0.001 &&
          (bookingPickupLng - stopOverStartLng).abs() < 0.001;
      bool endMatches = (bookingDropLat - stopOverEndLat).abs() < 0.001 &&
          (bookingDropLng - stopOverEndLng).abs() < 0.001;

      if (startMatches && endMatches) {
        // It's a full route, use bookingModel.pricePerSeat
        return double.tryParse(bookingModel.value.pricePerSeat ?? '0') ?? 0.0;
      }

      // Check if this matches any preset stopover in stopOverList
      final stopOverList = bookingModel.value.stopOverList;
      if (stopOverList != null && stopOverList.isNotEmpty) {
        for (var presetStopOver in stopOverList) {
          final presetStartLat = presetStopOver.startLocation?.lat;
          final presetStartLng = presetStopOver.startLocation?.lng;
          final presetEndLat = presetStopOver.endLocation?.lat;
          final presetEndLng = presetStopOver.endLocation?.lng;

          if (presetStartLat != null &&
              presetStartLng != null &&
              presetEndLat != null &&
              presetEndLng != null) {
            // Check if locations match (within small tolerance)
            bool presetStartMatches =
                (presetStartLat - stopOverStartLat).abs() < 0.001 &&
                    (presetStartLng - stopOverStartLng).abs() < 0.001;
            bool presetEndMatches =
                (presetEndLat - stopOverEndLat).abs() < 0.001 &&
                    (presetEndLng - stopOverEndLng).abs() < 0.001;

            if (presetStartMatches && presetEndMatches) {
              // Found matching preset stopover, use its price (not recommendedPrice)
              return double.tryParse(presetStopOver.price ?? '0') ?? 0.0;
            }
          }
        }
      }
    }

    // No matching preset found, use the stopOver price from bookingUserModel
    return double.tryParse(stopOver.price ?? '0') ?? 0.0;
  }

  double calculateAmount() {
    RxString taxAmount = "0.0".obs;
    if (bookingUserModel.value.taxList != null) {
      for (var element in bookingUserModel.value.taxList!) {
        taxAmount.value = (double.parse(taxAmount.value) +
                Constant().calculateTax(
                    amount: bookingUserModel.value.subTotal.toString(),
                    taxModel: element))
            .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
      }
    }
    return (double.parse(bookingUserModel.value.subTotal.toString())) +
        double.parse(taxAmount.value);
  }

  Rx<ReviewModel> reviewModel = ReviewModel().obs;

  getReview() async {
    await ReviewUtils.getReview(
            bookingId: bookingModel.value.id ?? "",
            senderId: bookingUserModel.value.id ?? '')
        .then((value) {
      if (value != null) {
        reviewModel.value = value;
      }
    });
  }
}
