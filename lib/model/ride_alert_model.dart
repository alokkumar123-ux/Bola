import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/model/map/geometry.dart';

class RideAlertModel {
  String? id;
  String? userId;
  String? pickUpAddress;
  String? dropAddress;
  Location? pickUpLocation;
  Location? dropLocation;
  String? person;
  Timestamp? searchDate; // The date when user searched
  Timestamp?
      expiryDate; // When this alert should expire (matches the ride date)
  Timestamp? createdAt;
  bool? isActive; // Whether the alert is still active

  RideAlertModel({
    this.id,
    this.userId,
    this.pickUpAddress,
    this.dropAddress,
    this.pickUpLocation,
    this.dropLocation,
    this.person,
    this.searchDate,
    this.expiryDate,
    this.createdAt,
    this.isActive,
  });

  RideAlertModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? '';
    userId = json['userId'] ?? '';
    pickUpAddress = json['pickUpAddress'] ?? '';
    dropAddress = json['dropAddress'] ?? '';
    pickUpLocation = json['pickUpLocation'] != null
        ? Location.fromJson(json['pickUpLocation'])
        : null;
    dropLocation = json['dropLocation'] != null
        ? Location.fromJson(json['dropLocation'])
        : null;
    person = json['person'];
    searchDate = json['searchDate'];
    expiryDate = json['expiryDate'];
    createdAt = json['createdAt'];
    isActive = json['isActive'] ?? true;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (pickUpLocation != null) {
      data['pickUpLocation'] = pickUpLocation!.toJson();
    }
    if (dropLocation != null) {
      data['dropLocation'] = dropLocation!.toJson();
    }
    data['pickUpAddress'] = pickUpAddress;
    data['dropAddress'] = dropAddress;
    data['person'] = person;
    data['searchDate'] = searchDate;
    data['expiryDate'] = expiryDate;
    data['createdAt'] = createdAt;
    data['id'] = id;
    data['userId'] = userId;
    data['isActive'] = isActive;
    return data;
  }
}
