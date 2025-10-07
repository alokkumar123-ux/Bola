class AadhaarOtpRequest {
  final String aadhaarNumber;

  AadhaarOtpRequest({required this.aadhaarNumber});

  Map<String, dynamic> toJson() {
    return {
      'aadhaar_number': aadhaarNumber,
    };
  }
}

class AadhaarOtpResponse {
  final String status;
  final String message;
  final String? refId;

  AadhaarOtpResponse({
    required this.status,
    required this.message,
    this.refId,
  });

  factory AadhaarOtpResponse.fromJson(Map<String, dynamic> json) {
    return AadhaarOtpResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      refId: json['ref_id']?.toString(),
    );
  }

  bool get isSuccess => status == 'SUCCESS';
}

class AadhaarVerifyRequest {
  final String refId;
  final String otp;

  AadhaarVerifyRequest({
    required this.refId,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'ref_id': refId,
      'otp': otp,
    };
  }
}

class AadhaarVerifyResponse {
  final String status;
  final String message;
  final AadhaarData? data;

  AadhaarVerifyResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory AadhaarVerifyResponse.fromJson(Map<String, dynamic> json) {
    return AadhaarVerifyResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null
          ? AadhaarData.fromJson(json['data'])
          : (json['aadhaar_data'] != null
              ? AadhaarData.fromJson(json['aadhaar_data'])
              : null),
    );
  }

  bool get isSuccess => status == 'SUCCESS';
}

class AadhaarData {
  final String? name;
  final String? dateOfBirth;
  final String? gender;
  final String? mobileNumber;
  final String? emailId;
  final AadhaarAddress? address;
  final String? aadhaarNumber;
  final String? profileImage;

  AadhaarData({
    this.name,
    this.dateOfBirth,
    this.gender,
    this.mobileNumber,
    this.emailId,
    this.address,
    this.aadhaarNumber,
    this.profileImage,
  });

  factory AadhaarData.fromJson(Map<String, dynamic> json) {
    return AadhaarData(
      name: json['name'] ?? json['full_name'],
      dateOfBirth: json['date_of_birth'] ?? json['dob'],
      gender: json['gender'],
      mobileNumber: json['mobile_number'] ?? json['phone'],
      emailId: json['email_id'] ?? json['email'],
      address: json['address'] != null
          ? AadhaarAddress.fromJson(json['address'])
          : null,
      aadhaarNumber: json['aadhaar_number'],
      profileImage: json['profile_image'] ?? json['photo'],
    );
  }
}

class AadhaarAddress {
  final String? careOf;
  final String? house;
  final String? street;
  final String? landmark;
  final String? locality;
  final String? vtc;
  final String? subdivision;
  final String? district;
  final String? state;
  final String? country;
  final String? pincode;

  AadhaarAddress({
    this.careOf,
    this.house,
    this.street,
    this.landmark,
    this.locality,
    this.vtc,
    this.subdivision,
    this.district,
    this.state,
    this.country,
    this.pincode,
  });

  factory AadhaarAddress.fromJson(Map<String, dynamic> json) {
    return AadhaarAddress(
      careOf: json['care_of'],
      house: json['house'] ?? json['building'],
      street: json['street'],
      landmark: json['landmark'],
      locality: json['locality'] ?? json['po'],
      vtc: json['vtc'],
      subdivision: json['subdivision'],
      district: json['district'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
    );
  }

  String get fullAddress {
    List<String> addressParts = [];

    if (house?.isNotEmpty == true) addressParts.add(house!);
    if (street?.isNotEmpty == true) addressParts.add(street!);
    if (landmark?.isNotEmpty == true) addressParts.add(landmark!);
    if (locality?.isNotEmpty == true) addressParts.add(locality!);
    if (vtc?.isNotEmpty == true) addressParts.add(vtc!);
    if (district?.isNotEmpty == true) addressParts.add(district!);
    if (state?.isNotEmpty == true) addressParts.add(state!);
    if (pincode?.isNotEmpty == true) addressParts.add(pincode!);

    return addressParts.join(', ');
  }
}

class AadhaarApiError {
  final String code;
  final String message;
  final String? description;

  AadhaarApiError({
    required this.code,
    required this.message,
    this.description,
  });

  factory AadhaarApiError.fromJson(Map<String, dynamic> json) {
    return AadhaarApiError(
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      description: json['description'],
    );
  }
}
