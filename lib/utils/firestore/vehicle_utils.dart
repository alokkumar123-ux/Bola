import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/model/vehicle_brand_model.dart';
import 'package:poolmate/model/vehicle_information_model.dart';
import 'package:poolmate/model/vehicle_model.dart';
import 'package:poolmate/model/vehicle_type_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';

class VehicleUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static Future<List<VehicleBrandModel>?> getVehicleBrand() async {
    List<VehicleBrandModel> list = [];

    await fireStore
        .collection(CollectionName.vehicleBrand)
        .where("enable", isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        VehicleBrandModel searchModel =
            VehicleBrandModel.fromJson(element.data());
        list.add(searchModel);
      }
    }).catchError((error) {
      print(error.toString());
    });
    return list;
  }

  static Future<List<VehicleModel>?> getVehicleModel(String brandId) async {
    List<VehicleModel> list = [];

    await fireStore
        .collection(CollectionName.vehicleModel)
        .where("brandId", isEqualTo: brandId)
        .where("enable", isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        VehicleModel searchModel = VehicleModel.fromJson(element.data());
        list.add(searchModel);
      }
    }).catchError((error) {
      print(error.toString());
    });
    return list;
  }

  static Future<List<VehicleTypeModel>?> getVehicleType() async {
    List<VehicleTypeModel> list = [];

    await fireStore
        .collection(CollectionName.vehicleType)
        .where("enable", isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        VehicleTypeModel searchModel =
            VehicleTypeModel.fromJson(element.data());
        list.add(searchModel);
      }
    }).catchError((error) {
      print(error.toString());
    });
    return list;
  }

  static Future<bool?> setUserVehicleInformation(
      VehicleInformationModel informationModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.userVehicleInformation)
        .doc(informationModel.id)
        .set(informationModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      print("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> deleteVehicleInformation(
      VehicleInformationModel informationModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.userVehicleInformation)
        .doc(informationModel.id)
        .delete()
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      print("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

    static Future<List<VehicleInformationModel>?>
      getUserVehicleInformation() async {
    List<VehicleInformationModel> list = [];

    await fireStore
        .collection(CollectionName.userVehicleInformation)
        .where("userId", isEqualTo:AuthUtils.getCurrentUid())
        .get()
        .then((value) {
      for (var element in value.docs) {
        VehicleInformationModel searchModel =
            VehicleInformationModel.fromJson(element.data());
        list.add(searchModel);
      }
    }).catchError((error) {
      print(error.toString());
    });
    return list;
  }
}
