import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';

class EditProfileController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<UserModel> userModel = UserModel().obs;

  Rx<TextEditingController> firstNameController = TextEditingController().obs;
  Rx<TextEditingController> lastNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  Rx<TextEditingController> sosWhatsAppNumberController1 =
      TextEditingController().obs;
  Rx<TextEditingController> sosWhatsAppNumberController2 =
      TextEditingController().obs;
  Rx<TextEditingController> dateOfBirthController = TextEditingController().obs;
  Rx<TextEditingController> bioController = TextEditingController().obs;
  Rx<TextEditingController> countryCodeController =
      TextEditingController(text: "+91").obs;
  RxString preAddressOfName = "Mr.".obs;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  getData() async {
    await UserUtils.getUserProfile(AuthUtils.getCurrentUid()).then((value) {
      if (value != null) {
        userModel.value = value;
        firstNameController.value.text = userModel.value.firstName.toString();
        lastNameController.value.text = userModel.value.lastName.toString();
        emailController.value.text = userModel.value.email.toString();
        phoneNumberController.value.text =
            userModel.value.phoneNumber.toString();
        // Initialize SOS WhatsApp number controllers
        if (userModel.value.sosWhatsAppNumbers != null &&
            userModel.value.sosWhatsAppNumbers!.isNotEmpty) {
          sosWhatsAppNumberController1.value.text =
              userModel.value.sosWhatsAppNumbers!.isNotEmpty
                  ? userModel.value.sosWhatsAppNumbers![0]
                  : "";
          sosWhatsAppNumberController2.value.text =
              userModel.value.sosWhatsAppNumbers!.length > 1
                  ? userModel.value.sosWhatsAppNumbers![1]
                  : "";
        } else {
          sosWhatsAppNumberController1.value.text = "";
          sosWhatsAppNumberController2.value.text = "";
        }
        dateOfBirthController.value.text =
            userModel.value.dateOfBirth.toString();
        bioController.value.text = userModel.value.bio.toString();
        countryCodeController.value.text =
            userModel.value.countryCode.toString();
        profileImage.value = userModel.value.profilePic.toString();
        preAddressOfName.value = userModel.value.gender.toString();
      }
    });

    isLoading.value = false;
  }

  saveData() async {
    // Validate SOS WhatsApp numbers
    String sosNumber1 = sosWhatsAppNumberController1.value.text.trim();
    String sosNumber2 = sosWhatsAppNumberController2.value.text.trim();

    // Check if SOS number 1 is not empty and doesn't have exactly 10 digits
    if (sosNumber1.isNotEmpty && sosNumber1.length != 10) {
      ShowToastDialog.showToast(
          "SOS WhatsApp number 1 must contain exactly 10 digits");
      return;
    }

    // Check if SOS number 2 is not empty and doesn't have exactly 10 digits
    if (sosNumber2.isNotEmpty && sosNumber2.length != 10) {
      ShowToastDialog.showToast(
          "SOS WhatsApp number 2 must contain exactly 10 digits");
      return;
    }

    // Check if both numbers are filled and are the same
    if (sosNumber1.isNotEmpty &&
        sosNumber2.isNotEmpty &&
        sosNumber1 == sosNumber2) {
      ShowToastDialog.showToast(
          "SOS WhatsApp number 1 and 2 cannot be the same");
      return;
    }

    ShowToastDialog.showLoader("Please wait...");
    if (Constant().hasValidUrl(profileImage.value) == false &&
        profileImage.value.isNotEmpty) {
      profileImage.value = await Constant.uploadUserImageToFireStorage(
        File(profileImage.value),
        "profileImage/${AuthUtils.getCurrentUid()}",
        File(profileImage.value).path.split('/').last,
      );
    }

    userModel.value.firstName = firstNameController.value.text;
    userModel.value.lastName = lastNameController.value.text;
    userModel.value.dateOfBirth = dateOfBirthController.value.text;
    userModel.value.bio = bioController.value.text;
    userModel.value.profilePic = profileImage.value;
    userModel.value.gender = preAddressOfName.value;
    // Save SOS WhatsApp numbers
    userModel.value.sosWhatsAppNumbers = [
      sosWhatsAppNumberController1.value.text,
      sosWhatsAppNumberController2.value.text
    ].where((number) => number.isNotEmpty).toList();

    await UserUtils.updateUser(userModel.value).then((value) {
      ShowToastDialog.closeLoader();
      Get.back(result: true);
    });
  }

  final ImagePicker _imagePicker = ImagePicker();
  RxString profileImage = "".obs;

  Future pickFile({required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      Get.back();
      profileImage.value = image.path;
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"failed_to_pick".tr} : \n $e");
    }
  }
}
