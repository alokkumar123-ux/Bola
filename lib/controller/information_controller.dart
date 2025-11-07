import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poolmate/app/dashboard_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/fire_store_utils.dart';
import 'package:poolmate/utils/notification_service.dart';

class InformationController extends GetxController {
  RxInt currentPage = 1.obs;

  Rx<GlobalKey<FormState>> formKey = GlobalKey<FormState>().obs;
  Rx<TextEditingController> firstNameController = TextEditingController().obs;
  Rx<TextEditingController> lastNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  Rx<TextEditingController> dateOfBirthController = TextEditingController().obs;

  Rx<TextEditingController> countryCode =
      TextEditingController(text: "+91").obs;
  RxString loginType = "".obs;
  final ImagePicker imagePicker = ImagePicker();
  RxString profileImage = "".obs;

  RxString preAddressOfName = "Mr.".obs;

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  Rx<UserModel> userModel = UserModel().obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      userModel.value = argumentData['userModel'];
      loginType.value = userModel.value.loginType.toString();
      if (loginType.value == Constant.phoneLoginType) {
        phoneNumberController.value.text =
            userModel.value.phoneNumber.toString();
        countryCode.value.text = userModel.value.countryCode.toString();
      } else {
        emailController.value.text = userModel.value.email ?? "";
        firstNameController.value.text = userModel.value.firstName ?? "";
        lastNameController.value.text = userModel.value.lastName ?? "";
      }
    }
    update();
  }

  createAccount() async {
    String fcmToken = '';
    try {
      fcmToken = await NotificationService.getToken();
    } catch (e) {
      debugPrint("Failed to get FCM token during account creation: $e");
      // Continue with account creation even if FCM token fails
    }

    if (profileImage.value.isNotEmpty) {
      profileImage.value = await Constant.uploadUserImageToFireStorage(
        File(profileImage.value),
        "profileImage/${FireStoreUtils.getCurrentUid()}",
        File(profileImage.value).path.split('/').last,
      );
    }
    ShowToastDialog.showLoader("Please wait...".tr);
    UserModel userModelData = userModel.value;
    userModelData.firstName = firstNameController.value.text;
    userModelData.lastName = lastNameController.value.text;
    userModelData.email = emailController.value.text;
    userModelData.countryCode = countryCode.value.text;
    userModelData.phoneNumber = phoneNumberController.value.text;
    userModelData.profilePic = profileImage.value;
    userModelData.fcmToken = fcmToken;
    userModelData.createdAt = Timestamp.now();
    userModelData.isActive = true;
    userModelData.aadharVerified = false;
    userModelData.panVerified = false;
    userModelData.gender = preAddressOfName.value;
    userModelData.dateOfBirth = dateOfBirthController.value.text;

    await FireStoreUtils.updateUser(userModelData).then((value) {
      ShowToastDialog.closeLoader();
      if (value == true) {
        Get.offAll(const DashBoardScreen());
      }
    });
    // if (referralCodeController.value.text.isNotEmpty) {
    //   await FireStoreUtils.checkReferralCodeValidOrNot(referralCodeController.value.text).then((value) async {
    //     if (value == true) {
    //       ShowToastDialog.showLoader("Please wait...".tr);
    //       UserModel userModelData = userModel.value;
    //       userModelData.firstName = firstNameController.value.text;
    //       userModelData.lastName = lastNameController.value.text;
    //       userModelData.email = emailController.value.text;
    //       userModelData.countryCode = countryCode.value.text;
    //       userModelData.phoneNumber = phoneNumberController.value.text;
    //       userModelData.profilePic = profileImage.value;
    //       userModelData.fcmToken = fcmToken;
    //       userModelData.createdAt = Timestamp.now();
    //       userModelData.isActive = true;
    //       userModelData.aadharVerified = false;
    //       userModelData.verifiedAsDriver = false;
    //       userModelData.gender = preAddressOfName.value;
    //       userModelData.dateOfBirth = dateOfBirthController.value.text;
    //
    //       FireStoreUtils.getReferralUserByCode(referralCodeController.value.text).then((value) async {
    //         if (value != null) {
    //           ReferralModel ownReferralModel = ReferralModel(id: FireStoreUtils.getCurrentUid(), referralBy: value.id, referralCode: Constant.getReferralCode());
    //           await FireStoreUtils.referralAdd(ownReferralModel);
    //         } else {
    //           ReferralModel referralModel = ReferralModel(id: FireStoreUtils.getCurrentUid(), referralBy: "", referralCode: Constant.getReferralCode());
    //           await FireStoreUtils.referralAdd(referralModel);
    //         }
    //       });
    //
    //       await FireStoreUtils.updateUser(userModelData).then((value) {
    //         ShowToastDialog.closeLoader();
    //         if (value == true) {
    //           Get.offAll(const DashBoardScreen());
    //         }
    //       });
    //     } else {
    //       ShowToastDialog.showToast("referral_code_invalid".tr);
    //     }
    //   });
    // } else {
    //
    // }
  }

  Future pickFile({required ImageSource source}) async {
    try {
      XFile? image = await imagePicker.pickImage(source: source);
      if (image == null) return;
      Get.back();
      profileImage.value = image.path;
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"failed_to_pick".tr} : \n $e");
    }
  }
}
