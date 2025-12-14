import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? firstName;
  String? lastName;
  String? bio;
  String? id;
  String? email;
  String? loginType;
  String? profilePic;
  String? dateOfBirth;
  String? fcmToken;
  String? countryCode;
  String? phoneNumber;
  String? walletAmount;
  String? gender;
  bool? isActive;
  bool? isVerify;
  bool? aadharVerified;
  bool? panVerified;
  String? referralCode;
  String? referredBy;
  int? referralStage; // 1,2,3 sequential tasks
  List<String>? task1Refs; // first referred user ids (max 1 expected)
  List<String>? task2Refs; // next 5 referred user ids that completed first ride
  List<String>?
      task3Refs; // additional 8 referred user ids that completed first ride
  String?
      commissionRate; // stored as string percentage (e.g., "0.01" or "0.03")
  String? referralEarningsTotal; // aggregate credited to wallet
  String? referralEarningsPending; // pending to be credited
  bool?
      referralPromptDismissed; // whether we already asked the user to enter a code
  bool?
      task2BonusGiven; // whether ₹100 bonus for Task 2 completion was already given
  TravelPreferenceModel? travelPreference;
  Timestamp? createdAt;
  String? reviewCount;
  String? reviewSum;
  List<String>? sosWhatsAppNumbers;
  UserModel({
    this.id,
    this.firstName,
    this.lastName,
    this.isActive,
    this.dateOfBirth,
    this.email,
    this.loginType,
    this.profilePic,
    this.fcmToken,
    this.countryCode,
    this.phoneNumber,
    this.walletAmount,
    this.createdAt,
    this.gender,
    this.travelPreference,
    this.bio,
    this.reviewSum,
    this.reviewCount,
    this.aadharVerified,
    this.panVerified,
    this.sosWhatsAppNumbers,
    this.referralCode,
    this.referredBy,
    this.referralStage,
    this.task1Refs,
    this.task2Refs,
    this.task3Refs,
    this.commissionRate,
    this.referralEarningsTotal,
    this.referralEarningsPending,
    this.referralPromptDismissed,
    this.task2BonusGiven,
  });

  fullName() {
    return "${firstName ?? ''} ${lastName ?? ''}";
  }

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    loginType = json['loginType'];
    profilePic = json['profilePic'];
    fcmToken = json['fcmToken'];
    countryCode = json['countryCode'];
    phoneNumber = json['phoneNumber'];
    walletAmount = json['walletAmount'] ?? "0.0";
    createdAt = json['createdAt'];
    gender = json['gender'];
    dateOfBirth = json['dateOfBirth'] ?? '';
    isActive = json['isActive'];
    isVerify = json['isVerify'];
    aadharVerified = json['aadharVerified'] ?? false;
    panVerified = json['panVerified'] ?? false;
    bio = json['bio'] ?? '';
    referralCode = json['referralCode'];
    referredBy = json['referredBy'];
    referralStage = json['referralStage'];
    task1Refs =
        json['task1Refs'] != null ? List<String>.from(json['task1Refs']) : null;
    task2Refs =
        json['task2Refs'] != null ? List<String>.from(json['task2Refs']) : null;
    task3Refs =
        json['task3Refs'] != null ? List<String>.from(json['task3Refs']) : null;
    commissionRate = json['commissionRate'];
    referralEarningsTotal = json['referralEarningsTotal'];
    referralEarningsPending = json['referralEarningsPending'];
    referralPromptDismissed = json['referralPromptDismissed'] ?? false;
    task2BonusGiven = json['task2BonusGiven'] ?? false;
    travelPreference = json['travelPreference'] != null
        ? TravelPreferenceModel.fromJson(json['travelPreference'])
        : null;
    reviewSum = json['reviewSum'] ?? '0.0';
    reviewCount = json['reviewCount'] ?? '0.0';
    sosWhatsAppNumbers = json['sosWhatsAppNumbers'] != null
        ? List<String>.from(json['sosWhatsAppNumbers'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['email'] = email;
    if (travelPreference != null) {
      data['travelPreference'] = travelPreference!.toJson();
    }
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['loginType'] = loginType;
    data['profilePic'] = profilePic;
    data['fcmToken'] = fcmToken;
    data['countryCode'] = countryCode;
    data['phoneNumber'] = phoneNumber;
    data['walletAmount'] = walletAmount;
    data['createdAt'] = createdAt;
    data['gender'] = gender;
    data['dateOfBirth'] = dateOfBirth;
    data['isActive'] = isActive;
    data['isVerify'] = isVerify;
    data['aadharVerified'] = aadharVerified;
    data['panVerified'] = panVerified;
    data['bio'] = bio;
    data['referralCode'] = referralCode;
    data['referredBy'] = referredBy;
    data['referralStage'] = referralStage;
    data['task1Refs'] = task1Refs;
    data['task2Refs'] = task2Refs;
    data['task3Refs'] = task3Refs;
    data['commissionRate'] = commissionRate;
    data['referralEarningsTotal'] = referralEarningsTotal;
    data['referralEarningsPending'] = referralEarningsPending;
    data['referralPromptDismissed'] = referralPromptDismissed;
    data['task2BonusGiven'] = task2BonusGiven;
    data['reviewSum'] = reviewSum;
    data['reviewCount'] = reviewCount;
    data['sosWhatsAppNumbers'] = sosWhatsAppNumbers;
    return data;
  }
}

class TravelPreferenceModel {
  String? chattiness;
  String? smoking;
  String? music;
  String? pets;

  TravelPreferenceModel({this.chattiness, this.smoking, this.music, this.pets});

  TravelPreferenceModel.fromJson(Map<String, dynamic> json) {
    chattiness = json['chattiness'];
    smoking = json['smoking'];
    music = json['music'];
    pets = json['pets'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['chattiness'] = chattiness;
    data['smoking'] = smoking;
    data['music'] = music;
    data['pets'] = pets;
    return data;
  }
}
