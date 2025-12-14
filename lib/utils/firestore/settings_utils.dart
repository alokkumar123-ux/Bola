import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/model/admin_commission.dart';
import 'package:poolmate/model/currency_model.dart';
import 'package:poolmate/model/language_model.dart';
import 'package:poolmate/themes/app_them_data.dart';

class SettingsUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  getSettings() async {
    await fireStore
        .collection(CollectionName.settings)
        .doc("global")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.termsAndConditions = value.data()!["termsAndConditions"];
        Constant.privacyPolicy = value.data()!["privacyPolicy"];
        Constant.appBannerImageDark = value.data()!["appBannerImageDark"];
        Constant.appBannerImageLight = value.data()!["appBannerImageLight"];
        Constant.globalUrl = value.data()!["globalUrl"];
        AppThemeData.primary300 = Color(
            int.parse(value.data()!["appColor"].replaceFirst("#", "0xff")));
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("adminCommission")
        .get()
        .then((value) {
      if (value.data() != null) {
        Constant.adminCommission = AdminCommission.fromJson(value.data()!);
      }
    });

    fireStore
        .collection(CollectionName.settings)
        .doc("globalKey")
        .snapshots()
        .listen((event) {
      if (event.exists) {
        Constant.mapAPIKey = event.data()!["googleMapKey"];
        Constant.distanceType = event.data()!["distanceType"];
      }
    });

    fireStore
        .collection(CollectionName.settings)
        .doc("globalValue")
        .snapshots()
        .listen((event) {
      if (event.exists) {
        Constant.priceVariation = event.data()!["priceVariation"];
        Constant.radius = event.data()!["radius"];
        Constant.intervalHoursForPublishNewRide =
            event.data()!['intervalHoursForPublishNewRide'];
        Constant.minimumAmountToDeposit =
            event.data()!["minimumAmountToDeposit"];
        Constant.minimumAmountToWithdrawal =
            event.data()!["minimumAmountToWithdrawal"];
        Constant.verifyBooking = event.data()!["verifyBooking"];
        Constant.verifyPublish = event.data()!["verifyPublish"];
      }
    });

    fireStore
        .collection(CollectionName.settings)
        .doc("notification_settings")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.senderId = value.data()!["senderId"];
        Constant.jsonNotificationFileURL = value.data()!["serviceJson"];
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("referral")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.referralAmount = value.data()!["referralAmount"];
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("contact_us")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.supportURL = value.data()!["supportURL"];
      }
    });
  }

  Future<CurrencyModel?> getCurrency() async {
    CurrencyModel? currencyModel;
    await fireStore
        .collection(CollectionName.currency)
        .where("enable", isEqualTo: true)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        currencyModel = CurrencyModel.fromJson(value.docs.first.data());
      }
    });
    return currencyModel;
  }

  static Future<List<LanguageModel>?> getLanguage() async {
    List<LanguageModel> languageList = [];

    await fireStore
        .collection(CollectionName.languages)
        .where("enable", isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        LanguageModel taxModel = LanguageModel.fromJson(element.data());
        languageList.add(taxModel);
      }
    }).catchError((error) {
      print(error.toString());
    });
    return languageList;
  }

  static Future<List<String>> getAdvertiseBannersData() async {
    try {
      final snapshot = await fireStore
          .collection(CollectionName.settings)
          .doc("AdvertiseBanners")
          .get();
      if (snapshot.exists) {
        final banners = snapshot.data()?['banners'] as List<dynamic>?;
        if (banners != null) {
          final advertiseBannerModel =
              banners.map((e) => e.toString()).toList();
          return advertiseBannerModel;
        }
      }
    } catch (error, stackTrace) {
      print('Error fetching advertise banners: $error');
    }
    return [];
  }
}
