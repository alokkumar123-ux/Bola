import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/home_screen/booking_success_screen.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/send_notification.dart';
import 'package:poolmate/services/whatsapp_service.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/home_controller.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/booking_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';

class BookingDetailsController extends GetxController {
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  HomeController homeController = Get.find<HomeController>();
  Rx<BookingModel> bookingModel = BookingModel().obs;
  Rx<StopOverModel> stopOverModel = StopOverModel().obs;
  Rx<BookedUserModel> bookingUserModel = BookedUserModel().obs;

  Rx<String> paymentType = "".obs;
  Rx<UserModel> publisherUserModel = UserModel().obs;
  Rx<UserModel> userModel = UserModel().obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      bookingModel.value = argumentData['bookingModel'];
      stopOverModel.value = argumentData['stopOverModel'];
    }

    AuthUtils.fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.value.id)
        .snapshots()
        .listen(
      (event) {
        bookingModel.value = BookingModel.fromJson(event.data()!);
      },
    );

    if (bookingModel.value.status == Constant.onGoing) {
      await BookingUtils.getMyBookingUser(bookingModel.value).then((value) {
        if (value != null) {
          bookingUserModel.value = value;
        }
      });
    }

    await UserUtils.getUserProfile(bookingModel.value.createdBy.toString())
        .then((value) {
      publisherUserModel.value = value!;
    });

    await UserUtils.getUserProfile(AuthUtils.getCurrentUid()).then((value) {
      userModel.value = value!;
    });
    isLoading.value = false;
  }

  // Helper method to get the correct price per seat
  // Checks if the booking matches a preset stopover or uses bookingModel.pricePerSeat
  double getCorrectPricePerSeat() {
    // Get the stopOver from the controller
    final stopOver = stopOverModel.value;

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

    // No matching preset found, use the stopOver price
    return double.tryParse(stopOver.price ?? '0') ?? 0.0;
  }

  bookingPlace() async {
    if (bookingModel.value.bookedUserId!.contains(AuthUtils.getCurrentUid()) ==
        false) {
      bookingModel.value.bookedUserId!.add(AuthUtils.getCurrentUid());
    }
    bookingModel.value.bookedSeat =
        (int.parse(bookingModel.value.bookedSeat.toString()) +
                int.parse(homeController.numberOfSheet.value.toString()))
            .toString();

    BookedUserModel bookingUserModel = BookedUserModel();
    bookingUserModel.id = AuthUtils.getCurrentUid();
    bookingUserModel.bookedSeat = homeController.numberOfSheet.value.toString();
    bookingUserModel.paymentStatus = false;
    bookingUserModel.paymentType = paymentType.value;
    bookingUserModel.stopOver = stopOverModel.value;
    bookingUserModel.createdAt = Timestamp.now();
    bookingUserModel.pickupLocation = homeController.pickUpLocation.value;
    bookingUserModel.dropLocation = homeController.dropLocation.value;
    bookingUserModel.adminCommission = Constant.adminCommission;
    bookingUserModel.taxList = Constant.taxList;
    // Use the correct price per seat (checks for preset prices)
    double correctPricePerSeat = getCorrectPricePerSeat();
    bookingUserModel.subTotal = (correctPricePerSeat *
            double.parse(homeController.numberOfSheet.value.toString()))
        .toString();

    ShowToastDialog.showLoader("Please wait..");
    await BookingUtils.setUserBooking(bookingModel.value, bookingUserModel);

    // Send notification to driver
    await SendNotification.sendOneNotification(
        type: Constant.booking_confirmed,
        token: publisherUserModel.value.fcmToken.toString(),
        payload: {});

    // Send notification to passenger (user who booked) confirming their booking
    if (userModel.value.fcmToken != null &&
        userModel.value.fcmToken!.isNotEmpty) {
      await SendNotification.sendOneNotification(
          type: Constant.booking_confirmed,
          token: userModel.value.fcmToken.toString(),
          payload: {});
    }

    // Send WhatsApp notifications
    // To passenger: booking confirmed
    if (userModel.value.phoneNumber != null) {
      await WhatsAppService.sendRiderBookingConfirmed(
        phoneNumber: userModel.value.phoneNumber!,
      );
    }

    // To driver: seat booked
    if (publisherUserModel.value.phoneNumber != null) {
      await WhatsAppService.sendDriverSeatBook(
        phoneNumber: publisherUserModel.value.phoneNumber!,
      );
    }

    await BookingUtils.setBooking(bookingModel.value).then((value) {
      ShowToastDialog.closeLoader();
      Get.off(const BookingSuccessScreen());
      clearData();
    });
  }

  clearData() {
    homeController.pickUpLocationController.value.clear();
    homeController.dropLocationController.value.clear();
  }
}
