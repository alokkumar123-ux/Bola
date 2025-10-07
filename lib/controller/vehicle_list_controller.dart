import 'package:get/get.dart';
import 'package:poolmate/model/vehicle_information_model.dart';
import 'package:poolmate/utils/fire_store_utils.dart';

class VehicleListController extends GetxController {
  RxList<VehicleInformationModel> userVehicleList = <VehicleInformationModel>[].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getVehicleInformation();
    super.onInit();
  }

  RxBool isLoading = true.obs;

  getVehicleInformation() async {
    await FireStoreUtils.getUserVehicleInformation().then((value) {
      if (value != null) {
        userVehicleList.value = value;
      }
    });
    isLoading.value = false;
  }
}
