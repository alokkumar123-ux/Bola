
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/review_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/review_utils.dart';

class RatingController extends GetxController {
  RxBool isLoading = true.obs;
  RxDouble rating = 0.0.obs;
  Rx<TextEditingController> commentController = TextEditingController().obs;

  Rx<ReviewModel> reviewModel = ReviewModel().obs;

  Rx<BookingModel> bookingModel = BookingModel().obs;
  Rx<UserModel> senderUserModel = UserModel().obs;
  Rx<UserModel> reciverUserModel = UserModel().obs;

  @override
  void onInit() {
    super.onInit();
    getArgument();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      bookingModel.value = argumentData['bookingModel'];
      senderUserModel.value = argumentData['senderUserModel'];
      reciverUserModel.value = argumentData['reciverUserModel'];
    }
    print("senderUserModel :: ${senderUserModel.value.id}");
    print("reciverUserModel :: ${reciverUserModel.value.id}");
    await UserUtils.getUserProfile(senderUserModel.value.toString())
        .then((value) {
      if (value != null) {
        senderUserModel.value = value;
      }
    });

    await ReviewUtils.getReviewByReceiverId(
            bookingId: bookingModel.value.id ?? '',
            receiverId: reciverUserModel.value.id ?? '')
        .then((value) {
      if (value != null) {
        reviewModel.value = value;
        rating.value = double.parse(reviewModel.value.rating.toString());
        commentController.value.text = reviewModel.value.comment.toString();
      }
    });
    isLoading.value = false;
    update();
  }
}
