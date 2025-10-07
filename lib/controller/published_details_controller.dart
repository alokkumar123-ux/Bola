import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/chat/model/chat_model.dart';
import 'package:poolmate/app/chat/model/inbox_model.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/send_notification.dart';
import 'package:poolmate/services/whatsapp_service.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/map/city_list_model.dart';
import 'package:poolmate/model/review_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/fire_store_utils.dart';

class PublishedDetailsController extends GetxController {
  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  Rx<BookingModel> bookingModel = BookingModel().obs;
  RxList<BookedUserModel> bookingUserList = <BookedUserModel>[].obs;

  RxList<CityModel> stopOver = <CityModel>[].obs;
  Rx<UserModel> publisherUserModel = UserModel().obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      bookingModel.value = argumentData['bookingModel'];
    }

    getUserData();

    FireStoreUtils.fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.value.id)
        .snapshots()
        .listen(
      (event) {
        stopOver.clear();
        if (event.data() != null) {
          bookingModel.value = BookingModel.fromJson(event.data()!);
          stopOver.add(bookingModel.value.pickupLocation!);
          stopOver.addAll(bookingModel.value.stopOver!);
          stopOver.add(bookingModel.value.dropLocation!);
        }
      },
    );

    FireStoreUtils.fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.value.id)
        .collection("bookedUser")
        .snapshots()
        .listen((value) {
      bookingUserList.clear();
      for (var element in value.docs) {
        BookedUserModel documentModel =
            BookedUserModel.fromJson(element.data());
        bookingUserList.add(documentModel);
      }
    });

    await FireStoreUtils.getUserProfile(bookingModel.value.createdBy.toString())
        .then((value) {
      publisherUserModel.value = value!;
    });
  }

  changeStatus(CityModel cityModel, int index) async {
    if (cityModel.isArrived != true) {
      ShowToastDialog.showLoader("Please wait");
      cityModel.isArrived = true;
      if (index == 0) {
        bookingModel.value.status = Constant.onGoing;
      }
      if (index == stopOver.length - 1) {
        bookingModel.value.status = Constant.completed;
      }
      stopOver.removeAt(index);
      stopOver.insert(index, cityModel);
      stopOver.removeAt(0);
      stopOver.removeAt(stopOver.length - 1);
      bookingModel.value.stopOver = stopOver;

      await FireStoreUtils.setBooking(bookingModel.value);
      ShowToastDialog.closeLoader();
      CityModel nextStationCity;
      if (index == 0 || index == stopOver.length - 1) {
        nextStationCity = stopOver[index];
      } else {
        nextStationCity = stopOver[index + 1];
      }
      bookingUserList.forEach(
        (element) async {
          bool isSame = await checkSameCity(
            nextStationCity.geometry!.location!.lat!,
            nextStationCity.geometry!.location!.lng!,
            element.stopOver!.startLocation!.lat!,
            element.stopOver!.startLocation!.lng!,
          );
          if (isSame) {
            await FireStoreUtils.getUserProfile(element.id.toString())
                .then((value) async {
              if (value != null) {
                UserModel userModel = value;
                await SendNotification.sendOneNotification(
                    token: userModel.fcmToken.toString(),
                    type: Constant.ride_arrive,
                    payload: {});
              }
            });
          }
        },
      );

      // if (index == 0) {
      //   bookingModel.value.pickupLocation = cityModel;
      //   await FireStoreUtils.setBooking(bookingModel.value);
      // } else if (index == 0) {
      //   bookingModel.value.dropLocation = cityModel;
      //   await FireStoreUtils.setBooking(bookingModel.value);
      // } else {
      //
      // }
    }
  }

  publishRide() async {
    ShowToastDialog.showLoader("Please wait");
    if (bookingUserList.isEmpty) {
      await FireStoreUtils.setBooking(bookingModel.value).then((value) {
        ShowToastDialog.closeLoader();
        Get.back(result: true);
      });
    } else {
      bookingUserList.forEach(
        (element) async {
          BookedUserModel bookingUserModel = element;
          UserModel? userModel;

          await FireStoreUtils.getUserProfile(bookingUserModel.id.toString())
              .then((value) {
            userModel = value!;
          });
          // if (bookingUserModel.paymentStatus == true) {
          //   if (bookingUserModel.paymentType!.toLowerCase() != "cash") {
          //     WalletTransactionModel transactionModel = WalletTransactionModel(
          //         id: Constant.getUuid(),
          //         amount: calculateAmount(bookingUserModel).toString(),
          //         createdDate: Timestamp.now(),
          //         paymentType: "Wallet",
          //         transactionId: bookingModel.value.id,
          //         isCredit: false,
          //         type: "publisher",
          //         userId: bookingModel.value.createdBy.toString(),
          //         note: "Amount refunded for ${userModel!.fullName()} ride");
          //
          //     await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
          //       if (value == true) {
          //         await FireStoreUtils.updateOtherUserWallet(amount: "-${calculateAmount(bookingUserModel).toString()}", id: bookingModel.value.createdBy.toString());
          //       }
          //     });
          //     if (bookingUserModel.adminCommission != null &&
          //         bookingUserModel.adminCommission!.enable == true) {
          //       WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
          //           id: Constant.getUuid(),
          //           amount:
          //           "${Constant.calculateOrderAdminCommission(amount: double.parse(bookingUserModel.subTotal.toString()).toString(), adminCommission: bookingUserModel.adminCommission)}",
          //           createdDate: Timestamp.now(),
          //           paymentType: "Wallet",
          //           isCredit: true,
          //           transactionId: bookingModel.value.id,
          //           type: "publisher",
          //           userId: bookingModel.value.createdBy.toString(),
          //           note: "Admin commission credited for  ${userModel!.fullName()} ride");
          //
          //       await FireStoreUtils.setWalletTransaction(adminCommissionWallet).then((value) async {
          //         if (value == true) {
          //           await FireStoreUtils.updateOtherUserWallet(
          //               amount: "${Constant.calculateOrderAdminCommission(amount: bookingUserModel.subTotal.toString(), adminCommission: bookingUserModel.adminCommission)}",
          //               id: bookingModel.value.createdBy.toString());
          //         }
          //       });
          //     }
          //
          //   } else {
          //     if (bookingUserModel.adminCommission != null &&
          //         bookingUserModel.adminCommission!.enable == true) {
          //       WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
          //           id: Constant.getUuid(),
          //           amount:
          //           "${Constant.calculateOrderAdminCommission(amount: double.parse(bookingUserModel.subTotal.toString()).toString(), adminCommission: bookingUserModel.adminCommission)}",
          //           createdDate: Timestamp.now(),
          //           paymentType: "Wallet",
          //           isCredit: true,
          //           transactionId: bookingModel.value.id,
          //           userId: bookingModel.value.createdBy.toString(),
          //           type: "publisher",
          //           note: "Admin commission credited for  ${userModel!.fullName()} ride");
          //       await FireStoreUtils.setWalletTransaction(adminCommissionWallet).then((value) async {
          //         if (value == true) {
          //           await FireStoreUtils.updateOtherUserWallet(
          //               amount: "-${Constant.calculateOrderAdminCommission(amount: bookingUserModel.subTotal.toString(), adminCommission: bookingUserModel.adminCommission)}",
          //               id: bookingModel.value.createdBy.toString());
          //         }
          //       });
          //     }
          //
          //   }
          //
          //   WalletTransactionModel transactionModel = WalletTransactionModel(
          //       id: Constant.getUuid(),
          //       amount: calculateAmount(bookingUserModel).toString(),
          //       createdDate: Timestamp.now(),
          //       paymentType: "Wallet",
          //       transactionId: bookingModel.value.id,
          //       isCredit: true,
          //       userId: userModel!.id.toString(),
          //       type: "customer",
          //       note: "Amount refunded for ${publisherUserModel.value.fullName()} ride");
          //
          //   await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
          //     if (value == true) {
          //       await FireStoreUtils.updateOtherUserWallet(amount: calculateAmount(bookingUserModel).toString(), id: userModel!.id.toString());
          //     }
          //   });
          // }

          await FireStoreUtils.setCancelledUserBooking(
              bookingModel.value, bookingUserModel);
          await FireStoreUtils.removeUserBooking(
              bookingModel.value, bookingUserModel);

          await SendNotification.sendChatNotification(
              token: userModel!.fcmToken ?? "",
              title: publisherUserModel.value.fullName().toString(),
              body:
                  "We regret to inform you that your booking with us has been cancelled.",
              payload: {});
        },
      );
      bookingModel.value.bookedSeat = "0";
      bookingModel.value.bookedUserId!.clear();

      await FireStoreUtils.setBooking(bookingModel.value).then((value) {
        ShowToastDialog.closeLoader();
        Get.back(result: true);
      });
    }
  }

  // Mark the ride as cancelled instead of deleting. Moves users to cancelled list and updates booking status.
  cancelRide() async {
    try {
      ShowToastDialog.showLoader("Please wait");

      // If no one booked yet, just set status and unpublish
      if (bookingUserList.isEmpty) {
        bookingModel.value.status = Constant.canceled;
        bookingModel.value.publish = false;
        await FireStoreUtils.setBooking(bookingModel.value);
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Ride cancelled successfully".tr);
        Get.back(result: true);
        return;
      }

      // Create a copy of the list to avoid concurrent modification
      final List<BookedUserModel> usersToCancel = List.from(bookingUserList);

      // Move all booked users under cancelledUser and notify
      for (var element in usersToCancel) {
        final BookedUserModel bookingUserModel = element;
        UserModel? userModel;

        await FireStoreUtils.getUserProfile(bookingUserModel.id.toString())
            .then((value) {
          userModel = value!;
        });

        await FireStoreUtils.setCancelledUserBooking(
            bookingModel.value, bookingUserModel);
        await FireStoreUtils.removeUserBooking(
            bookingModel.value, bookingUserModel);

        // Prepare detailed ride information
        String rideDetails = _formatRideDetailsForNotification();

        // Create full message for chat
        // String chatMessage = "🚫 Ride Cancelled\n\n"
        //     "Your booked ride has been cancelled by the publisher.\n\n"
        //     "$rideDetails\n\n"
        //     "We apologize for any inconvenience caused. You can book another ride or contact support if needed.";
        String chatMessage =
            "The driver has cancelled his trip. Please check apps.";
        // Send message to chat room
        try {
          await _sendChatMessage(userModel!, chatMessage);
          print("✅ Chat message sent to ${userModel!.fullName()}");
        } catch (chatError) {
          print("❌ Failed to send chat message: $chatError");
        }

        // // Send push notification
        try {
          await SendNotification.sendChatNotification(
              token: userModel!.fcmToken ?? "",
              title: "Ride Cancelled - ${publisherUserModel.value.fullName()}",
              body: "The driver has cancelled his trip. Please check apps.",
              payload: {
                "type": "ride_cancelled",
                "bookingId": bookingModel.value.id ?? '',
                "publisherId": bookingModel.value.createdBy ?? '',
                "action": "ride_cancelled",
                "senderId": publisherUserModel.value.id ?? '',
                "receiverId": userModel!.id ?? '',
              });
          print("✅ Notification sent to ${userModel!.fullName()}");
        } catch (notifError) {
          print("❌ Failed to send notification: $notifError");
        }

        // Send WhatsApp notification to passenger about driver cancellation
        try {
          if (userModel?.phoneNumber != null) {
            await WhatsAppService.sendRiderBookingCancelled(
              phoneNumber: userModel!.phoneNumber!,
            );
            print("✅ WhatsApp sent to ${userModel!.fullName()}");
          }
        } catch (whatsappError) {
          print("❌ Failed to send WhatsApp: $whatsappError");
        }
      }

      // Reset seats and mark as cancelled
      bookingModel.value.bookedSeat = "0";
      bookingModel.value.bookedUserId?.clear();
      bookingModel.value.publish = false;
      bookingModel.value.status = Constant.canceled;

      await FireStoreUtils.setBooking(bookingModel.value);
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Ride cancelled successfully".tr);
      Get.back(result: true);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error cancelling ride: ${e.toString()}".tr);
      print("❌ Error in cancelRide: $e");
    }
  }

  /// Format ride details for notification message
  String _formatRideDetailsForNotification() {
    String pickupAddress = bookingModel.value.pickUpAddress ?? "Unknown pickup";
    String dropAddress =
        bookingModel.value.dropAddress ?? "Unknown destination";
    String dateTime = bookingModel.value.departureDateTime != null
        ? Constant.timestampToDateTime(bookingModel.value.departureDateTime!)
        : "Unknown date/time";
    String pricePerSeat = bookingModel.value.pricePerSeat != null
        ? Constant.amountShow(amount: bookingModel.value.pricePerSeat!)
        : "Unknown price";

    return "Ride Details:\n"
        "📍 From: $pickupAddress\n"
        "🏁 To: $dropAddress\n"
        "📅 Date & Time: $dateTime\n"
        "💰 Price per seat: $pricePerSeat\n"
        "🆔 Ride ID: ${bookingModel.value.id ?? 'Unknown'}";
  }

  /// Send chat message to passenger about ride cancellation
  _sendChatMessage(UserModel passengerUser, String message) async {
    try {
      // Create inbox models using existing InboxModel class
      InboxModel receiverInboxModel = InboxModel(
          archive: false,
          lastMessage: message,
          mediaUrl: '',
          receiverId: passengerUser.id.toString(),
          seen: false,
          senderId: publisherUserModel.value.id.toString(),
          timestamp: Timestamp.now(),
          type: 'text');

      InboxModel senderInboxModel = InboxModel(
          archive: false,
          lastMessage: message,
          mediaUrl: '',
          receiverId: passengerUser.id.toString(),
          seen: true,
          senderId: publisherUserModel.value.id.toString(),
          timestamp: Timestamp.now(),
          type: 'text');

      // Update inbox for both users
      await FireStoreUtils.fireStore
          .collection(CollectionName.chat)
          .doc(publisherUserModel.value.id.toString())
          .collection("inbox")
          .doc(passengerUser.id.toString())
          .set(senderInboxModel.toJson());

      await FireStoreUtils.fireStore
          .collection(CollectionName.chat)
          .doc(passengerUser.id.toString())
          .collection("inbox")
          .doc(publisherUserModel.value.id.toString())
          .set(receiverInboxModel.toJson());

      // Create chat message using existing ChatModel class
      ChatModel chatModel = ChatModel(
          type: 'text',
          timestamp: Timestamp.now(),
          senderId: publisherUserModel.value.id.toString(),
          seen: false,
          receiverId: passengerUser.id.toString(),
          mediaUrl: '',
          chatID: Constant.getUuid(),
          message: message);

      // Save chat message to both user conversations
      await FireStoreUtils.fireStore
          .collection(CollectionName.chat)
          .doc(publisherUserModel.value.id.toString())
          .collection(passengerUser.id.toString())
          .doc(chatModel.chatID!)
          .set(chatModel.toJson());

      await FireStoreUtils.fireStore
          .collection(CollectionName.chat)
          .doc(passengerUser.id.toString())
          .collection(publisherUserModel.value.id.toString())
          .doc(chatModel.chatID!)
          .set(chatModel.toJson());

      print("Chat message sent successfully to ${passengerUser.fullName()}");
    } catch (e) {
      print("Error sending chat message to ${passengerUser.fullName()}: $e");
    }
  }

  deleteRide() async {
    ShowToastDialog.showLoader("Please wait");
    if (bookingUserList.isEmpty) {
      await FireStoreUtils.deleteBooking(bookingModel.value).then(
        (value) {
          ShowToastDialog.closeLoader();
          Get.back(result: true);
          Get.back(result: true);
        },
      );
    } else {
      bookingUserList.forEach(
        (element) async {
          BookedUserModel bookingUserModel = element;
          UserModel? userModel;

          await FireStoreUtils.getUserProfile(bookingUserModel.id.toString())
              .then((value) {
            userModel = value!;
          });

          // if (bookingUserModel.paymentStatus == true) {
          //   if (bookingUserModel.paymentType!.toLowerCase() != "cash") {
          //     WalletTransactionModel transactionModel = WalletTransactionModel(
          //         id: Constant.getUuid(),
          //         amount: calculateAmount(bookingUserModel).toString(),
          //         createdDate: Timestamp.now(),
          //         paymentType: "Wallet",
          //         transactionId: bookingModel.value.id,
          //         isCredit: false,
          //         type: "publisher",
          //         userId: bookingModel.value.createdBy.toString(),
          //         note: "Amount refunded for ${userModel!.fullName()} ride");
          //
          //     await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
          //       if (value == true) {
          //         await FireStoreUtils.updateOtherUserWallet(amount: "-${calculateAmount(bookingUserModel).toString()}", id: bookingModel.value.createdBy.toString());
          //       }
          //     });
          //     if (bookingUserModel.adminCommission != null &&
          //         bookingUserModel.adminCommission!.enable == true) {
          //       WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
          //           id: Constant.getUuid(),
          //           amount:
          //           "${Constant.calculateOrderAdminCommission(amount: double.parse(bookingUserModel.subTotal.toString()).toString(), adminCommission: bookingUserModel.adminCommission)}",
          //           createdDate: Timestamp.now(),
          //           paymentType: "Wallet",
          //           isCredit: true,
          //           transactionId: bookingModel.value.id,
          //           userId: bookingModel.value.createdBy.toString(),
          //           type: "publisher",
          //           note: "Admin commission credited for  ${userModel!.fullName()} ride");
          //
          //       await FireStoreUtils.setWalletTransaction(adminCommissionWallet).then((value) async {
          //         if (value == true) {
          //           await FireStoreUtils.updateOtherUserWallet(
          //               amount: "${Constant.calculateOrderAdminCommission(amount: bookingUserModel.subTotal.toString(), adminCommission: bookingUserModel.adminCommission)}",
          //               id: bookingModel.value.createdBy.toString());
          //         }
          //       });
          //     }
          //
          //   } else {
          //     if (bookingUserModel.adminCommission != null &&
          //         bookingUserModel.adminCommission!.enable == true) {
          //       WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
          //           id: Constant.getUuid(),
          //           amount:
          //           "${Constant.calculateOrderAdminCommission(amount: double.parse(bookingUserModel.subTotal.toString()).toString(), adminCommission: bookingUserModel.adminCommission)}",
          //           createdDate: Timestamp.now(),
          //           paymentType: "Wallet",
          //           isCredit: true,
          //           transactionId: bookingModel.value.id,
          //           type: "publisher",
          //           userId: bookingModel.value.createdBy.toString(),
          //           note: "Admin commission credited for  ${userModel!.fullName()} ride");
          //       await FireStoreUtils.setWalletTransaction(adminCommissionWallet).then((value) async {
          //         if (value == true) {
          //           await FireStoreUtils.updateOtherUserWallet(
          //               amount: "-${Constant.calculateOrderAdminCommission(amount: bookingUserModel.subTotal.toString(), adminCommission: bookingUserModel.adminCommission)}",
          //               id: bookingModel.value.createdBy.toString());
          //         }
          //       });
          //     }
          //
          //   }
          //
          //   WalletTransactionModel transactionModel = WalletTransactionModel(
          //       id: Constant.getUuid(),
          //       amount: calculateAmount(bookingUserModel).toString(),
          //       createdDate: Timestamp.now(),
          //       paymentType: "Wallet",
          //       transactionId: bookingModel.value.id,
          //       isCredit: true,
          //       userId: userModel!.id.toString(),
          //       type: "customer",
          //       note: "Amount refunded for ${publisherUserModel.value.fullName()} ride");
          //
          //   await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
          //     if (value == true) {
          //       await FireStoreUtils.updateOtherUserWallet(amount: calculateAmount(bookingUserModel).toString(), id: userModel!.id.toString());
          //     }
          //   });
          // }

          await FireStoreUtils.setCancelledUserBooking(
              bookingModel.value, bookingUserModel);
          await FireStoreUtils.removeUserBooking(
              bookingModel.value, bookingUserModel);
          await SendNotification.sendChatNotification(
              token: userModel!.fcmToken ?? "",
              title: publisherUserModel.value.fullName().toString(),
              body:
                  "We regret to inform you that your booking with us has been cancelled.",
              payload: {});
        },
      );

      await FireStoreUtils.fireStore
          .collection(CollectionName.booking)
          .doc("bookedUser")
          .delete();
      await FireStoreUtils.fireStore
          .collection(CollectionName.booking)
          .doc("cancelledUser")
          .delete();

      await FireStoreUtils.deleteBooking(bookingModel.value).then(
        (value) {
          ShowToastDialog.closeLoader();
          Get.back(result: true);
          Get.back(result: true);
        },
      );
    }
  }

  Rx<ReviewModel> reviewModel = ReviewModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  getReview() async {
    await FireStoreUtils.getReview(
            bookingId: bookingModel.value.id ?? "",
            senderId: userModel.value.id ?? '')
        .then((value) {
      if (value != null) {
        reviewModel.value = value;
      }
    });
  }

  getUserData() async {
    await FireStoreUtils.getUserProfile(bookingModel.value.createdBy.toString())
        .then((value) {
      publisherUserModel.value = value!;
    });
  }

  double calculateAmount(BookedUserModel bookingUserModel) {
    RxString taxAmount = "0.0".obs;
    if (bookingUserModel.taxList != null) {
      for (var element in bookingUserModel.taxList!) {
        taxAmount.value = (double.parse(taxAmount.value) +
                Constant().calculateTax(
                    amount: bookingUserModel.subTotal.toString(),
                    taxModel: element))
            .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
      }
    }
    return (double.parse(bookingUserModel.subTotal.toString())) +
        double.parse(taxAmount.value);
  }

  Future<bool> checkSameCity(
      double lat1, double lon1, double lat2, double lon2) async {
    bool isSame = false;
    try {
      // Get the placemarks for the first location
      List<Placemark> placemarks1 = await placemarkFromCoordinates(lat1, lon1);
      // Get the placemarks for the second location
      List<Placemark> placemarks2 = await placemarkFromCoordinates(lat2, lon2);

      if (placemarks1.isNotEmpty && placemarks2.isNotEmpty) {
        String city1 = placemarks1[0].locality ?? '';
        String city2 = placemarks2[0].locality ?? '';

        if (city1.isNotEmpty && city2.isNotEmpty) {
          if (city1 == city2) {
            isSame = true;
          } else {
            isSame = false;
          }
        } else {
          isSame = false;
        }
      } else {
        isSame = false;
      }
    } catch (e) {
      isSame = false;
    }
    return isSame;
  }
}
