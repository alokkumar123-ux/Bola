import 'package:get/get.dart';
import 'package:poolmate/model/vehicle_information_model.dart';
import 'package:poolmate/utils/firestore/vehicle_utils.dart';

class VehicleListController extends GetxController {
  RxList<VehicleInformationModel> userVehicleList =
      <VehicleInformationModel>[].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getVehicleInformation();
    super.onInit();
  }

  RxBool isLoading = true.obs;

  getVehicleInformation() async {
    await VehicleUtils.getUserVehicleInformation().then((value) {
      if (value != null) {
        userVehicleList.value = value;
      }
    });
    isLoading.value = false;
  }
}
