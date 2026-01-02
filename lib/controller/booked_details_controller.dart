import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/send_notification.dart';
import 'package:poolmate/services/whatsapp_service.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/model/wallet_transaction_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/booking_utils.dart';
import 'package:poolmate/utils/firestore/review_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/wallet_utils.dart';

import '../constant/collection_name.dart';
import '../controller/chat_controller.dart';
import '../model/review_model.dart';

class BookedDetailsController extends GetxController {
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  Rx<BookingModel> bookingModel = BookingModel().obs;
  Rx<BookedUserModel> bookingUserModel = BookedUserModel().obs;
  Rx<String> paymentType = "".obs;
  Rx<UserModel> userModel = UserModel().obs;
  Rx<UserModel> publisherUserModel = UserModel().obs;

  Rx<ReviewModel> reviewModel = ReviewModel().obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      bookingModel.value = argumentData['bookingModel'];

      // Check if bookingUserModel is provided and not null
      if (argumentData['bookingUserModel'] != null) {
        bookingUserModel.value = argumentData['bookingUserModel'];
      }

      // If bookingUserModel is null or incomplete, try to fetch it
      if (argumentData['bookingUserModel'] == null ||
          bookingUserModel.value.id == null) {
        print(
            "BookingUserModel is null or incomplete, fetching from Firebase...");

        // Check if this is a booking created by current user (published ride)
        if (bookingModel.value.createdBy == AuthUtils.getCurrentUid()) {
          print(
              "This is a published ride by current user, BookingUserModel not required");
          // For published rides, we don't need BookingUserModel
          // The screen should show the booking details without it
        } else {
          // This is a booking where current user is a passenger
          await BookingUtils.getMyBookingUser(bookingModel.value).then((value) {
            if (value != null) {
              bookingUserModel.value = value;
              print("Successfully fetched BookingUserModel");
            } else {
              print(
                  "Failed to fetch BookingUserModel - it may not exist for this booking");
            }
          });
        }
      }
    }
    await UserUtils.getUserProfile(AuthUtils.getCurrentUid()).then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });

    // Only setup snapshot listener if booking ID exists
    if (bookingModel.value.id != null) {
      AuthUtils.fireStore
          .collection(CollectionName.booking)
          .doc(bookingModel.value.id)
          .snapshots()
          .listen(
        (event) {
          if (event.exists && event.data() != null) {
            bookingModel.value = BookingModel.fromJson(event.data()!);
          }
        },
      );
    }

    await getUserData();
    await getReview();
    isLoading.value = false;
  }

  getReview() async {
    try {
      await ReviewUtils.getReview(
              bookingId: bookingModel.value.id ?? "",
              senderId: AuthUtils.getCurrentUid())
          .then((value) {
        if (value != null) {
          reviewModel.value = value;
        }
      });
    } catch (e) {
      print("Error fetching review: $e");
    }
  }

  getUserData() async {
    try {
      await UserUtils.getUserProfile(bookingModel.value.createdBy.toString())
          .then((value) {
        if (value != null) {
          publisherUserModel.value = value;
        } else {
          print("Publisher user not found");
        }
      });
    } catch (e) {
      print("Error fetching publisher user data: $e");
    }
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

  /// Send a chat message using the centralized ChatController static method
  _sendChatMessage(UserModel receiverUser, String message) async {
    await ChatController.sendMessageStatic(
      senderUser: userModel.value,
      receiverUser: receiverUser,
      message: message,
      sendNotification: true,
    );
  }

  Future<bool> cancelBooking() async {
    try {
      String currentUserId = AuthUtils.getCurrentUid();

      // Update booked seat count
      int currentBookedSeats =
          int.tryParse(bookingModel.value.bookedSeat ?? '') ?? 0;
      int cancellingSeats = (bookingUserModel.value.selectedSeats != null)
          ? (bookingUserModel.value.selectedSeats!.length)
          : (int.tryParse(bookingUserModel.value.bookedSeat ?? '') ?? 0);
      final int updatedBookedSeats = (currentBookedSeats - cancellingSeats) < 0
          ? 0
          : (currentBookedSeats - cancellingSeats);
      bookingModel.value.bookedSeat = updatedBookedSeats.toString();

      // Update user lists
      bookingModel.value.bookedUserId?.remove(currentUserId);
      if (!bookingModel.value.cancelledUserId!.contains(currentUserId)) {
        bookingModel.value.cancelledUserId!.add(currentUserId);
      }

      // Clear selected seats for this user
      if (bookingModel.value.selectedSeats != null) {
        final Set<String> userSeatSet = {
          ...((bookingUserModel.value.selectedSeats ?? <String>[]))
              .map((e) => e.toString())
        };
        List<dynamic> updatedSeats = [...bookingModel.value.selectedSeats!];
        updatedSeats.removeWhere(
            (seatNumber) => userSeatSet.contains(seatNumber.toString()));
        bookingModel.value.selectedSeats = updatedSeats;
      }

      // Update seat bookings
      if (bookingModel.value.seatBookings != null) {
        bookingModel.value.seatBookings!
            .removeWhere((seat) => seat.userId == currentUserId);
      }

      // Process refund if payment was made
      if (bookingUserModel.value.paymentStatus == true) {
        await processRefund();
      }

      // Update booking records
      await BookingUtils.setCancelledUserBooking(
          bookingModel.value, bookingUserModel.value);
      await BookingUtils.removeUserBooking(
          bookingModel.value, bookingUserModel.value);
      await BookingUtils.setBooking(bookingModel.value);
      // Send cancellation notification
      await SendNotification.sendOneNotification(
          type: "booking_cancelled",
          token: publisherUserModel.value.fcmToken.toString(),
          payload: {
            "bookingId": bookingModel.value.id ?? "",
            "cancelledBy": userModel.value.fullName() ?? "",
            "cancelledUserId": AuthUtils.getCurrentUid(),
            "cancelledSeats": cancellingSeats.toString(),
            "pickUpAddress": bookingModel.value.pickUpAddress ?? "",
            "dropAddress": bookingModel.value.dropAddress ?? "",
            "departureDateTime":
                bookingModel.value.departureDateTime?.toDate().toString() ?? ""
          });

      // Send WhatsApp notification to driver about booking cancellation
      if (publisherUserModel.value.phoneNumber != null) {
        await WhatsAppService.sendDriverCancelled(
          phoneNumber: publisherUserModel.value.phoneNumber!,
        );
        print(
            "🔄 Sending WhatsApp notification to driver: ${publisherUserModel.value.phoneNumber}");
      }

      // Send chat message to publisher about cancellation
      String cancellationMessage = "🚫 Booking Cancelled\n\n"
          "I had to cancel my booking for this ride.\n\n"
          "Ride Details:\n"
          "📍 From: ${bookingModel.value.pickUpAddress ?? 'pickup location'}\n"
          "🏁 To: ${bookingModel.value.dropAddress ?? 'destination'}\n"
          "🪑 Cancelled seats: ${bookingUserModel.value.bookedSeat ?? '1'}\n"
          "📅 Date & Time: ${bookingModel.value.departureDateTime != null ? Constant.timestampToDateTime(bookingModel.value.departureDateTime!) : 'Unknown'}\n"
          "🆔 Booking ID: ${bookingModel.value.id ?? 'Unknown'}\n\n"
          "Thank you for understanding. You can now offer these seats to other passengers.";

      try {
        await _sendChatMessage(publisherUserModel.value, cancellationMessage);
        print(
            "✅ Cancellation message sent to publisher: ${publisherUserModel.value.fullName()}");
      } catch (chatError) {
        print("❌ Failed to send cancellation message: $chatError");
        // Let's also try to handle the error and continue with the cancellation
      }

      return true;
    } catch (error) {
      print('Error in cancelBooking: $error');
      return false;
    }
  }

  Future<void> processRefund() async {
    if (bookingUserModel.value.paymentType!.toLowerCase() != "cash") {
      // Refund to publisher's wallet
      WalletTransactionModel publisherRefund = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: calculateAmount().toString(),
          createdDate: Timestamp.now(),
          paymentType: "Wallet",
          transactionId: bookingModel.value.id,
          isCredit: false,
          type: "publisher",
          userId: bookingModel.value.createdBy.toString(),
          note: "Amount refunded for ${userModel.value.fullName()} ride");

      await WalletUtils.setWalletTransaction(publisherRefund)
          .then((value) async {
        if (value == true) {
          await WalletUtils.updateOtherUserWallet(
              amount: "-${calculateAmount().toString()}",
              id: bookingModel.value.createdBy.toString());
        }
      });
    }

    // Handle admin commission refund
    if (bookingUserModel.value.adminCommission != null &&
        bookingUserModel.value.adminCommission!.enable == true) {
      double adminCommissionAmount = Constant.calculateOrderAdminCommission(
          amount: bookingUserModel.value.subTotal.toString(),
          adminCommission: bookingUserModel.value.adminCommission);

      WalletTransactionModel adminCommissionRefund = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: adminCommissionAmount.toString(),
          createdDate: Timestamp.now(),
          paymentType: "Wallet",
          isCredit: true,
          transactionId: bookingModel.value.id,
          type: "publisher",
          userId: bookingModel.value.createdBy.toString(),
          note:
              "Admin commission reversed for ${userModel.value.fullName()} cancellation");

      await WalletUtils.setWalletTransaction(adminCommissionRefund)
          .then((value) async {
        if (value == true) {
          await WalletUtils.updateOtherUserWallet(
              amount: adminCommissionAmount.toString(),
              id: bookingModel.value.createdBy.toString());
        }
      });
    }

    // Refund to customer's wallet
    WalletTransactionModel customerRefund = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: calculateAmount().toString(),
        createdDate: Timestamp.now(),
        paymentType: "Wallet",
        transactionId: bookingModel.value.id,
        isCredit: true,
        type: "customer",
        userId: userModel.value.id.toString(),
        note:
            "Refund for cancelled ride with ${publisherUserModel.value.fullName()}");

    await WalletUtils.setWalletTransaction(customerRefund).then((value) async {
      if (value == true) {
        await WalletUtils.updateOtherUserWallet(
            amount: calculateAmount().toString(),
            id: userModel.value.id.toString());
      }
    });
  }

  paymentCompleted() async {
    ShowToastDialog.showLoader("Please wait..");
    bookingUserModel.value.paymentStatus = true;
    bookingUserModel.value.paymentType = paymentType.value;

    if (paymentType.value.toLowerCase() != "cash") {
      WalletTransactionModel transactionModel = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: calculateAmount().toString(),
          createdDate: Timestamp.now(),
          paymentType: paymentType.value,
          transactionId: bookingModel.value.id,
          isCredit: true,
          type: "publisher",
          userId: bookingModel.value.createdBy.toString(),
          note: "Amount credited for ${userModel.value.fullName()} ride");

      await WalletUtils.setWalletTransaction(transactionModel)
          .then((value) async {
        if (value == true) {
          await WalletUtils.updateOtherUserWallet(
              amount: calculateAmount().toString(),
              id: bookingModel.value.createdBy.toString());
        }
      });
    }

    if (bookingUserModel.value.adminCommission != null &&
        bookingUserModel.value.adminCommission!.enable == true) {
      WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
          id: Constant.getUuid(),
          amount:
              "-${Constant.calculateOrderAdminCommission(amount: double.parse(bookingUserModel.value.subTotal.toString()).toString(), adminCommission: bookingUserModel.value.adminCommission)}",
          createdDate: Timestamp.now(),
          paymentType: "wallet",
          isCredit: false,
          type: "publisher",
          transactionId: bookingModel.value.id,
          userId: bookingModel.value.createdBy.toString(),
          note: "Admin commission debited for  ${userModel.value.fullName()}");

      await WalletUtils.setWalletTransaction(adminCommissionWallet)
          .then((value) async {
        if (value == true) {
          await WalletUtils.updateOtherUserWallet(
              amount:
                  "-${Constant.calculateOrderAdminCommission(amount: bookingUserModel.value.subTotal.toString(), adminCommission: bookingUserModel.value.adminCommission)}",
              id: bookingModel.value.createdBy.toString());
        }
      });
    }

    await BookingUtils.setUserBooking(
        bookingModel.value, bookingUserModel.value);
    await SendNotification.sendOneNotification(
        type: Constant.payment_successful,
        token: publisherUserModel.value.fcmToken.toString(),
        payload: {});

    await BookingUtils.setBooking(bookingModel.value).then((value) {
      ShowToastDialog.closeLoader();
      Get.back(result: true);
    });
  }
}
