
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/rating_controller.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/themes/text_field_widget.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/review_utils.dart';
import 'package:provider/provider.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<RatingController>(
        init: RatingController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: themeChange.getThem()
                  ? AppThemeData.grey900
                  : AppThemeData.grey50,
              centerTitle: false,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              leading: InkWell(
                onTap: () {
                  Get.back();
                },
                child: Icon(
                  Icons.chevron_left_outlined,
                  color: themeChange.getThem()
                      ? AppThemeData.grey50
                      : AppThemeData.grey900,
                ),
              ),
              title: Text(
                "Review".tr,
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey100
                        : AppThemeData.grey800,
                    fontFamily: AppThemeData.bold,
                    fontSize: 18),
              ),
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: Container(
                  color: themeChange.getThem()
                      ? AppThemeData.grey700
                      : AppThemeData.grey200,
                  height: 4.0,
                ),
              ),
            ),
            body: controller.isLoading.value == true
                ? Center(child: Constant.loader())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: RatingBar.builder(
                            initialRating: controller.rating.value,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemSize: 32,
                            itemPadding:
                                const EdgeInsets.symmetric(horizontal: 2.0),
                            itemBuilder: (context, _) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (rating) {
                              controller.rating(rating);
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        TextFieldWidget(
                          title: 'Leave review'.tr,
                          controller: controller.commentController.value,
                          hintText: 'Write Review here...'.tr,
                          maxLine: 5,
                        ),
                      ],
                    ),
                  ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: RoundedButtonFill(
                title: controller.reviewModel.value.id != null
                    ? "Edit Review"
                    : "Leave a Review".tr,
                color: AppThemeData.primary300,
                textColor: AppThemeData.primary50,
                onPress: () async {
                  if (controller.rating.value < 1) {
                    ShowToastDialog.showToast("Please select rating");
                  } else if (controller.commentController.value.text.isEmpty) {
                    ShowToastDialog.showToast("Please enter review comment");
                  } else {
                    ShowToastDialog.showLoader("Please wait".tr);

                    if (controller.reviewModel.value.id != null) {
                      controller.reciverUserModel.value.reviewSum =
                          (double.parse(controller
                                      .reciverUserModel.value.reviewSum
                                      .toString()) -
                                  double.parse(controller
                                      .reviewModel.value.rating
                                      .toString()))
                              .toString();
                      controller.reciverUserModel.value.reviewCount =
                          (double.parse(controller
                                      .reciverUserModel.value.reviewCount
                                      .toString()) -
                                  1)
                              .toString();
                    } else {
                      controller.reviewModel.value.id = Constant.getUuid();
                    }
                    controller.reciverUserModel.value.reviewSum = (double.parse(
                                controller.reciverUserModel.value.reviewSum
                                    .toString()) +
                            double.parse(controller.rating.value.toString()))
                        .toString();
                    controller.reciverUserModel.value.reviewCount =
                        (double.parse(controller
                                    .reciverUserModel.value.reviewCount
                                    .toString()) +
                                1)
                            .toString();
                    print(
                        "reciverUserModel :: ${controller.reciverUserModel.value.id} :: reviewSum :: ${controller.reciverUserModel.value.reviewSum} :: reviewCount :: ${controller.reciverUserModel.value.reviewCount} ");
                    await UserUtils.updateUser(
                        controller.reciverUserModel.value);

                    controller.reviewModel.value.bookingId =
                        controller.bookingModel.value.id;
                    controller.reviewModel.value.comment =
                        controller.commentController.value.text;
                    controller.reviewModel.value.rating =
                        controller.rating.value.toString();
                    controller.reviewModel.value.receiverId =
                        controller.reciverUserModel.value.id;
                    controller.reviewModel.value.senderId =
                        controller.senderUserModel.value.id;
                    controller.reviewModel.value.date = Timestamp.now();

                    await ReviewUtils.setReview(controller.reviewModel.value)
                        .then((value) {
                      if (value != null && value == true) {
                        ShowToastDialog.closeLoader();
                        ShowToastDialog.showToast(
                            "Review submit successfully".tr);
                        Get.back(result: true);
                      }
                    });
                  }
                },
              ),
            ),
          );
        });
  }
}
