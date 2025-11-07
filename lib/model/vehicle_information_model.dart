import 'package:poolmate/model/vehicle_brand_model.dart';
import 'package:poolmate/model/vehicle_model.dart';
import 'package:poolmate/model/vehicle_type_model.dart';

class VehicleInformationModel {
  String? id;
  String? userId;
  String? licensePlatNumber;
  String? vehicleColor;
  String? vehicleRegistrationYear;
  String? seatCount;
  VehicleBrandModel? vehicleBrand;
  VehicleModel? vehicleModel;
  VehicleTypeModel? vehicleType;
  List<dynamic>? vehicleImages;
  bool? rcVerified;
  String? rcStatus;
  String? rcExpiryDate;
  String? vehicleInsuranceUpto;
  String? verifiedAt;

  VehicleInformationModel({
    this.id,
    this.userId,
    this.licensePlatNumber,
    this.vehicleColor,
    this.vehicleRegistrationYear,
    this.seatCount,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleType,
    this.vehicleImages,
    this.rcVerified,
    this.rcStatus,
    this.rcExpiryDate,
    this.vehicleInsuranceUpto,
    this.verifiedAt,
  });

  VehicleInformationModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    licensePlatNumber = json['licensePlatNumber'];
    vehicleColor = json['vehicleColor'];
    vehicleRegistrationYear = json['vehicleRegistrationYear'];
    seatCount = json['seatCount'];
    vehicleImages = json['vehicleImages'];
    rcVerified = json['rcVerified'] ?? false;
    rcStatus = json['rcStatus'];
    rcExpiryDate = json['rcExpiryDate'];
    vehicleInsuranceUpto = json['vehicleInsuranceUpto'];
    verifiedAt = json['verifiedAt'];

    vehicleBrand = json['vehicleBrand'] != null
        ? VehicleBrandModel.fromJson(json['vehicleBrand'])
        : null;
    vehicleModel = json['vehicleModel'] != null
        ? VehicleModel.fromJson(json['vehicleModel'])
        : null;
    vehicleType = json['vehicleType'] != null
        ? VehicleTypeModel.fromJson(json['vehicleType'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['userId'] = userId;
    data['licensePlatNumber'] = licensePlatNumber;
    data['vehicleColor'] = vehicleColor;
    data['vehicleRegistrationYear'] = vehicleRegistrationYear;
    data['seatCount'] = seatCount;
    data['vehicleImages'] = vehicleImages;
    data['rcVerified'] = rcVerified;
    data['rcStatus'] = rcStatus;
    data['rcExpiryDate'] = rcExpiryDate;
    data['vehicleInsuranceUpto'] = vehicleInsuranceUpto;
    data['verifiedAt'] = verifiedAt;
    if (vehicleBrand != null) {
      data['vehicleBrand'] = vehicleBrand!.toJson();
    }
    if (vehicleModel != null) {
      data['vehicleModel'] = vehicleModel!.toJson();
    }
    if (vehicleType != null) {
      data['vehicleType'] = vehicleType!.toJson();
    }
    return data;
  }
}
