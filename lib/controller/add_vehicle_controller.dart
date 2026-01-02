import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/vehicle_brand_model.dart';
import 'package:poolmate/model/vehicle_information_model.dart';
import 'package:poolmate/model/vehicle_model.dart';
import 'package:poolmate/model/vehicle_type_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/vehicle_utils.dart';

class AddVehicleController extends GetxController {
  Rx<TextEditingController> licensePlatNumberController =
      TextEditingController().obs;
  Rx<TextEditingController> vehicleRegisterYearController =
      TextEditingController().obs;
  Rx<TextEditingController> seatCountController = TextEditingController().obs;
  RxInt selectedSeatCount = 0.obs;

  RxBool isLoading = true.obs;
  RxBool isRcVerified = false.obs;

  @override
  void onInit() {
    print("CLICK::33");
    // TODO: implement onInit
    getVehicleData();
    // Load argument first (if editing existing vehicle)
    getArgument();
    // Then check RC verification status (only if not already set from argument)
    if (!isRcVerified.value) {
      checkRcVerificationStatus();
    }
    super.onInit();
  }

  Rx<VehicleInformationModel> vehicleInformationModel =
      VehicleInformationModel().obs;

  // Check if RC is already verified in Firebase
  checkRcVerificationStatus() async {
    try {
      final currentVehicleNumber =
          licensePlatNumberController.value.text.trim().toUpperCase();
      if (currentVehicleNumber.isEmpty) {
        isRcVerified.value = false;
        return;
      }

      final userId = AuthUtils.getCurrentUid();

      // Check if vehicle with this number has RC verified in user_vehicle_information
      final querySnapshot = await AuthUtils.fireStore
          .collection('user_vehicle_information')
          .where('userId', isEqualTo: userId)
          .where('licensePlatNumber', isEqualTo: currentVehicleNumber)
          .where('rcVerified', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Load RC data from Firebase
        final doc = querySnapshot.docs.first;
        final data = doc.data();

        // Update vehicle information model with RC data from Firebase
        vehicleInformationModel.value.rcVerified = data['rcVerified'] ?? false;
        vehicleInformationModel.value.rcStatus = data['rcStatus'];
        vehicleInformationModel.value.rcExpiryDate = data['rcExpiryDate'];
        vehicleInformationModel.value.vehicleInsuranceUpto =
            data['vehicleInsuranceUpto'];
        vehicleInformationModel.value.verifiedAt = data['verifiedAt'];

        isRcVerified.value = true;

        // Trigger update to refresh UI
        vehicleInformationModel.refresh();
        return;
      }

      isRcVerified.value = false;
    } catch (e) {
      print("Error checking RC verification: $e");
      isRcVerified.value = false;
    }
  }

  // Check if vehicle number already exists in user_vehicle_information collection
  Future<bool> checkVehicleNumberExists(String vehicleNumber) async {
    try {
      final userId = AuthUtils.getCurrentUid();
      final vehicleNumberUpper = vehicleNumber.trim().toUpperCase();

      // If editing existing vehicle, exclude current vehicle from check
      final currentVehicleId = vehicleInformationModel.value.id;

      final querySnapshot = await AuthUtils.fireStore
          .collection('user_vehicle_information')
          .where('userId', isEqualTo: userId)
          .where('licensePlatNumber', isEqualTo: vehicleNumberUpper)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Check if it's not the current vehicle being edited
        for (var doc in querySnapshot.docs) {
          if (currentVehicleId == null || doc.id != currentVehicleId) {
            // Found another vehicle with same number
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print("Error checking vehicle number exists: $e");
      return false;
    }
  }

  // Verify RC using API call
  Future<Map<String, dynamic>?> verifyRcWithApi(String vehicleNumber) async {
    try {
      final url = Uri.parse('https://bolaletsgo.com/aadhar/rc.php');

      // Send POST request to PHP API
      final response = await http.post(
        url,
        body: {'vehicle_number': vehicleNumber.trim().toUpperCase()},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final rcData = jsonResponse['data'];

          // Store RC data in vehicle information model
          vehicleInformationModel.value.rcVerified = true;
          vehicleInformationModel.value.rcStatus = rcData['rc_status'];
          vehicleInformationModel.value.rcExpiryDate = rcData['rc_expiry_date'];
          vehicleInformationModel.value.vehicleInsuranceUpto =
              rcData['vehicle_insurance_upto'];
          vehicleInformationModel.value.verifiedAt = rcData['verified_at'];

          return rcData;
        } else {
          ShowToastDialog.showToast(
              jsonResponse['message'] ?? "RC verification failed".tr);
          return null;
        }
      } else {
        ShowToastDialog.showToast(
            "Failed to connect to verification server".tr);
        return null;
      }
    } catch (e) {
      print("Error verifying RC: $e");
      ShowToastDialog.showToast("Error verifying RC: ${e.toString()}".tr);
      return null;
    }
  }

  RxList images = <dynamic>[].obs;

  getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      vehicleInformationModel.value = argumentData['vehicleInformationModel'];

      licensePlatNumberController.value.text =
          vehicleInformationModel.value.licensePlatNumber.toString();
      vehicleRegisterYearController.value.text =
          vehicleInformationModel.value.vehicleRegistrationYear.toString();
      seatCountController.value.text =
          vehicleInformationModel.value.seatCount ?? '4';
      selectedSeatCount.value =
          int.tryParse(vehicleInformationModel.value.seatCount ?? '2') ?? 2;
      selectedColor.value =
          vehicleInformationModel.value.vehicleColor.toString();
      isRcVerified.value = vehicleInformationModel.value.rcVerified ?? false;
      if (vehicleInformationModel.value.vehicleImages != null &&
          vehicleInformationModel.value.vehicleImages!.isNotEmpty) {
        images.value = vehicleInformationModel.value.vehicleImages!;
      }
    }
  }

  getVehicleData() async {
    await VehicleUtils.getVehicleBrand().then((value) {
      if (value != null) {
        vehicleBrandModelList.value = value;
      }
    });

    await VehicleUtils.getVehicleType().then((value) {
      if (value != null) {
        vehicleTypeModelList.value = value;
      }
    });

    if (Get.arguments != null) {
      for (var element in vehicleBrandModelList) {
        if (element.id ==
            vehicleInformationModel.value.vehicleBrand!.id.toString()) {
          selectedVehicleBrand.value = element;
        }
      }

      for (var element in vehicleTypeModelList) {
        if (element.id ==
            vehicleInformationModel.value.vehicleType!.id.toString()) {
          selectedVehicleType.value = element;
        }
      }

      await VehicleUtils.getVehicleModel(
              selectedVehicleBrand.value.id.toString())
          .then((value) {
        if (value != null) {
          vehicleModelList.value = value;
          for (var element in vehicleModelList) {
            if (element.id ==
                vehicleInformationModel.value.vehicleModel!.id.toString()) {
              selectedVehicleModel.value = element;
            }
          }
        }
      });
    }
    isLoading.value = false;
  }

  RxList<VehicleBrandModel> vehicleBrandModelList = <VehicleBrandModel>[].obs;
  Rx<VehicleBrandModel> selectedVehicleBrand = VehicleBrandModel().obs;

  RxList<VehicleModel> vehicleModelList = <VehicleModel>[].obs;
  Rx<VehicleModel> selectedVehicleModel = VehicleModel().obs;

  RxList<VehicleTypeModel> vehicleTypeModelList = <VehicleTypeModel>[].obs;
  Rx<VehicleTypeModel> selectedVehicleType = VehicleTypeModel().obs;

  RxList<String> colourList = <String>[
    "Black",
    "White",
    "Dark grey",
    "Grey",
    "Red",
    "Dark blue",
    "Blue",
    "Dark green",
    "Green",
    "Brown",
    "Beige",
    "Orange",
    "Yellow",
    "Purple",
    "Pink"
  ].obs;
  RxString selectedColor = "".obs;

  getVehicleModel(String brandId) async {
    selectedVehicleModel.value = VehicleModel();
    await VehicleUtils.getVehicleModel(brandId).then((value) {
      if (value != null) {
        vehicleModelList.value = value;
      }
    });
  }

  setVehicleInformationData() async {
    ShowToastDialog.showLoader("Please wait..");
    vehicleInformationModel.value.id ??= Constant.getUuid();
    vehicleInformationModel.value.licensePlatNumber =
        licensePlatNumberController.value.text;
    vehicleInformationModel.value.vehicleRegistrationYear =
        vehicleRegisterYearController.value.text;
    vehicleInformationModel.value.seatCount =
        selectedSeatCount.value.toString();
    vehicleInformationModel.value.vehicleBrand = selectedVehicleBrand.value;
    vehicleInformationModel.value.vehicleModel = selectedVehicleModel.value;
    vehicleInformationModel.value.vehicleType = selectedVehicleType.value;
    vehicleInformationModel.value.vehicleColor = selectedColor.value;
    vehicleInformationModel.value.userId = AuthUtils.getCurrentUid();
    for (int i = 0; i < images.length; i++) {
      if (images[i].runtimeType == XFile) {
        String url = await Constant.uploadUserImageToFireStorage(
          File(images[i].path),
          "profileImage/${AuthUtils.getCurrentUid()}",
          File(images[i].path).path.split('/').last,
        );
        images.removeAt(i);
        images.insert(i, url);
      }
    }
    vehicleInformationModel.value.vehicleImages = images;
    await VehicleUtils.setUserVehicleInformation(vehicleInformationModel.value);
    ShowToastDialog.closeLoader();
    Get.back(result: vehicleInformationModel.value.id);
  }

  deleteVehicle() async {
    ShowToastDialog.showLoader("Please wait..");
    await VehicleUtils.deleteVehicleInformation(vehicleInformationModel.value)
        .then(
      (value) {
        ShowToastDialog.showToast("Vehicle delete successfully");
        ShowToastDialog.closeLoader();
        Get.back(result: true);
      },
    );
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future pickFile({required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      images.add(image);
      Get.back();
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"failed_to_pick".tr} : \n $e");
    }
  }
}
