import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/model/admin_commission.dart';
import 'package:poolmate/model/seat_booking_model.dart';
import 'package:poolmate/model/map/city_list_model.dart';
import 'package:poolmate/model/map/geometry.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/model/tax_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/model/vehicle_information_model.dart';

class BookingModel {
  String? id;
  String? status;
  String? createdBy;
  List<SeatBooking>? seatBookings;
  String? totalSeat;
  String? bookedSeat;
  List<int>? tempSeatSelection;
  String? distance;
  String? estimatedTime;
  String? pricePerSeat;
  String? luggageAllowed;
  String? pickUpAddress;
  String? dropAddress;
  CityModel? pickupLocation;
  CityModel? dropLocation;
  List<dynamic>? bookedUserId;
  List<dynamic>? cancelledUserId;
  List<dynamic>? selectedSeats;
  List<CityModel>? stopOver;
  List<StopOverModel>? stopOverList;
  VehicleInformationModel? vehicleInformation;
  TravelPreferenceModel? travelPreference;
  Timestamp? departureDateTime;
  Timestamp? createdAt;
  bool? womenOnly;
  bool? driverVerify;
  bool? twoPassengerMaxInBack;
  bool? onlyVerifiedPassenger;
  bool? publish;
  String? additionalRequirements;
  String?
      driverPaymentMethod; // New field for driver's preferred payment method

  BookingModel({
    this.id,
    this.status,
    this.createdBy,
    this.totalSeat,
    this.bookedSeat,
    this.tempSeatSelection,
    this.distance,
    this.estimatedTime,
    this.pricePerSeat,
    this.luggageAllowed,
    this.pickUpAddress,
    this.dropAddress,
    this.pickupLocation,
    this.dropLocation,
    this.stopOver,
    this.stopOverList,
    this.vehicleInformation,
    this.departureDateTime,
    this.createdAt,
    this.bookedUserId,
    this.cancelledUserId,
    this.selectedSeats,
    this.womenOnly,
    this.driverVerify,
    this.twoPassengerMaxInBack,
    this.onlyVerifiedPassenger,
    this.travelPreference,
    this.publish,
    this.additionalRequirements,
    this.driverPaymentMethod,
  });

  BookingModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    status = json['status'];

    if (json['seatBookings'] != null) {
      seatBookings = <SeatBooking>[];
      json['seatBookings'].forEach((v) {
        seatBookings!.add(SeatBooking.fromJson(v));
      });
    }
    createdBy = json['createdBy'];
    totalSeat = json['totalSeat'];
    bookedSeat = json['bookedSeat'] ?? "0";
    tempSeatSelection = json['tempSeatSelection'] != null
        ? List<int>.from(json['tempSeatSelection'])
        : [];
    pricePerSeat = json['pricePerSeat'];
    luggageAllowed = json['luggageAllowed'];
    distance = json['distance'];
    estimatedTime = json['estimatedTime'];
    pickUpAddress = json['pickUpAddress'];
    dropAddress = json['dropAddress'];
    pickupLocation = json['pickupLocation'] != null
        ? CityModel.fromJson(json['pickupLocation'])
        : null;
    dropLocation = json['dropLocation'] != null
        ? CityModel.fromJson(json['dropLocation'])
        : null;
    vehicleInformation = json['vehicleInformation'] != null
        ? VehicleInformationModel.fromJson(json['vehicleInformation'])
        : null;
    if (json['stopOver'] != null) {
      stopOver = <CityModel>[];
      json['stopOver'].forEach((v) {
        stopOver!.add(CityModel.fromJson(v));
      });
    }
    if (json['stopOverList'] != null) {
      stopOverList = <StopOverModel>[];
      json['stopOverList'].forEach((v) {
        stopOverList!.add(StopOverModel.fromJson(v));
      });
    }
    departureDateTime = json['departureDateTime'];
    createdAt = json['createdAt'];
    bookedUserId = json['bookedUserId'] ?? [];
    cancelledUserId = json['cancelledUserId'] ?? [];
    selectedSeats = json['selectedSeats'] ?? [];
    womenOnly = json['womenOnly'];
    driverVerify = json['driverVerify'];
    twoPassengerMaxInBack = json['twoPassengerMaxInBack'];
    onlyVerifiedPassenger = json['onlyVerifiedPassenger'];
    publish = json['publish'];
    additionalRequirements = json['additionalRequirements'];
    driverPaymentMethod = json['driverPaymentMethod'];
    travelPreference = json['travelPreference'] != null
        ? TravelPreferenceModel.fromJson(json['travelPreference'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;

    if (seatBookings != null) {
      data['seatBookings'] = seatBookings!.map((v) => v.toJson()).toList();
    }
    data['status'] = status;
    data['createdBy'] = createdBy;
    data['totalSeat'] = totalSeat;
    data['bookedSeat'] = bookedSeat;
    data['tempSeatSelection'] = tempSeatSelection ?? [];
    data['pricePerSeat'] = pricePerSeat;
    data['luggageAllowed'] = luggageAllowed;
    data['distance'] = distance;
    data['estimatedTime'] = estimatedTime;
    data['pickUpAddress'] = pickUpAddress;
    data['dropAddress'] = dropAddress;
    data['stopOver'] = stopOver;
    if (stopOver != null) {
      data['stopOver'] = stopOver!.map((v) => v.toJson()).toList();
    }
    if (stopOverList != null) {
      data['stopOverList'] = stopOverList!.map((v) => v.toJson()).toList();
    }
    if (vehicleInformation != null) {
      data['vehicleInformation'] = vehicleInformation!.toJson();
    }
    if (pickupLocation != null) {
      data['pickupLocation'] = pickupLocation!.toJson();
    }
    if (dropLocation != null) {
      data['dropLocation'] = dropLocation!.toJson();
    }
    data['departureDateTime'] = departureDateTime;
    data['createdAt'] = createdAt;
    data['bookedUserId'] = bookedUserId;
    data['cancelledUserId'] = cancelledUserId;
    data['selectedSeats'] = selectedSeats;
    data['womenOnly'] = womenOnly;
    data['driverVerify'] = driverVerify;
    data['twoPassengerMaxInBack'] = twoPassengerMaxInBack;
    data['onlyVerifiedPassenger'] = onlyVerifiedPassenger;
    data['publish'] = publish;
    data['additionalRequirements'] = additionalRequirements;
    data['driverPaymentMethod'] = driverPaymentMethod;
    if (travelPreference != null) {
      data['travelPreference'] = travelPreference!.toJson();
    }
    return data;
  }
}

class BookedUserModel {
  Timestamp? createdAt;
  String? id;
  String? bookedSeat;
  String? subTotal;
  bool? paymentStatus;
  String? paymentType;
  String? otp;
  bool? verified;
  String? pnrNumber;
  StopOverModel? stopOver;
  Location? pickupLocation;
  Location? dropLocation;
  List<TaxModel>? taxList;
  AdminCommission? adminCommission;

  List<String>? selectedSeats;
  Map<String, String?>?
      passengerNames; // Map of seat index (as string) to passenger name
  Map<String, String?>?
      passengerGenders; // Map of seat index (as string) to gender (Male/Female)
  Map<String, int?>? passengerAges; // Map of seat index (as string) to age

  BookedUserModel({
    this.createdAt,
    this.id,
    this.bookedSeat,
    this.paymentStatus,
    this.subTotal,
    this.stopOver,
    this.paymentType,
    this.otp,
    this.verified,
    this.pnrNumber,
    this.pickupLocation,
    this.dropLocation,
    this.taxList,
    this.adminCommission,
    this.selectedSeats,
    this.passengerNames,
    this.passengerGenders,
    this.passengerAges,
  });

  BookedUserModel.fromJson(Map<String, dynamic> json) {
    createdAt = json['createdAt'];
    id = json['id'];
    bookedSeat = json['bookedSeat'];
    subTotal = json['subTotal'];
    paymentStatus = json['paymentStatus'];
    paymentType = json['paymentType'];
    pnrNumber = json['pnrNumber'];
    otp = json['otp'];
    verified = json['verified'] ?? false;
    stopOver = json['stopOver'] != null
        ? StopOverModel.fromJson(json['stopOver'])
        : null;
    pickupLocation = json['pickupLocation'] != null
        ? Location.fromJson(json['pickupLocation'])
        : null;
    dropLocation = json['dropLocation'] != null
        ? Location.fromJson(json['dropLocation'])
        : null;
    if (json['taxList'] != null) {
      taxList = <TaxModel>[];
      json['taxList'].forEach((v) {
        taxList!.add(TaxModel.fromJson(v));
      });
    }
    adminCommission = json['adminCommission'] != null
        ? AdminCommission.fromJson(json['adminCommission'])
        : null;
    if (json['selectedSeats'] != null) {
      selectedSeats = List<String>.from(json['selectedSeats']);
    }
    if (json['passengerNames'] != null) {
      passengerNames = Map<String, String?>.from(
        json['passengerNames']
            .map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    if (json['passengerGenders'] != null) {
      passengerGenders = Map<String, String?>.from(
        json['passengerGenders']
            .map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    if (json['passengerAges'] != null) {
      passengerAges = Map<String, int?>.from(
        json['passengerAges'].map((key, value) => MapEntry(key.toString(),
            value is int ? value : int.tryParse(value?.toString() ?? ''))),
      );
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['createdAt'] = createdAt;
    data['id'] = id;
    data['bookedSeat'] = bookedSeat;
    data['subTotal'] = subTotal;
    data['paymentStatus'] = paymentStatus;
    data['paymentType'] = paymentType;
    data['pnrNumber'] = pnrNumber;
    if (otp != null) {
      data['otp'] = otp;
    }
    data['verified'] = verified ?? false;
    if (stopOver != null) {
      data['stopOver'] = stopOver!.toJson();
    }
    if (pickupLocation != null) {
      data['pickupLocation'] = pickupLocation!.toJson();
    }
    if (dropLocation != null) {
      data['dropLocation'] = dropLocation!.toJson();
    }
    if (taxList != null) {
      data['taxList'] = taxList!.map((v) => v.toJson()).toList();
    }
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    if (selectedSeats != null) {
      data['selectedSeats'] = selectedSeats;
    }
    if (passengerNames != null) {
      data['passengerNames'] = passengerNames;
    }
    if (passengerGenders != null) {
      data['passengerGenders'] = passengerGenders;
    }
    if (passengerAges != null) {
      data['passengerAges'] = passengerAges;
    }
    return data;
  }
}
