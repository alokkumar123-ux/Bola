import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/admin_commission.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/conversation_admin_model.dart';
import 'package:poolmate/model/currency_model.dart';
import 'package:poolmate/model/document_model.dart';
import 'package:poolmate/model/inbox_admin_model.dart';
import 'package:poolmate/model/language_model.dart';
import 'package:poolmate/model/notification_model.dart';
import 'package:poolmate/model/on_boarding_model.dart';
import 'package:poolmate/model/payment_method_model.dart';
import 'package:poolmate/model/recent_search_model.dart';
import 'package:poolmate/model/referral_model.dart';
import 'package:poolmate/model/report_model.dart';
import 'package:poolmate/model/review_model.dart';
import 'package:poolmate/model/sos_model.dart';
import 'package:poolmate/model/tax_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/model/user_verification_model.dart';
import 'package:poolmate/model/vehicle_brand_model.dart';
import 'package:poolmate/model/vehicle_information_model.dart';
import 'package:poolmate/model/vehicle_model.dart';
import 'package:poolmate/model/vehicle_type_model.dart';
import 'package:poolmate/model/wallet_transaction_model.dart';
import 'package:poolmate/model/withdraw_method_model.dart';
import 'package:poolmate/model/withdraw_model.dart';
import 'package:poolmate/themes/app_them_data.dart';

class FireStoreUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  static String getCurrentUid() {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  static Future<bool> isLogin() async {
    bool isLogin = false;
    if (FirebaseAuth.instance.currentUser != null) {
      isLogin = await userExistOrNot(FirebaseAuth.instance.currentUser!.uid);
    } else {
      isLogin = false;
    }
    return isLogin;
  }

  static Future<bool> userExistOrNot(String uid) async {
    bool isExist = false;

    await fireStore.collection(CollectionName.users).doc(uid).get().then(
      (value) {
        if (value.exists) {
          isExist = true;
        } else {
          isExist = false;
        }
      },
    ).catchError((error) {
      log("Failed to check user exist: $error");
      isExist = false;
    });
    return isExist;
  }

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    List<OnBoardingModel> onBoardingModel = [];
    await fireStore.collection(CollectionName.onBoarding).get().then((value) {
      for (var element in value.docs) {
        OnBoardingModel documentModel =
            OnBoardingModel.fromJson(element.data());
        onBoardingModel.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return onBoardingModel;
  }

  Future<List<TaxModel>?> getTaxList() async {
    List<TaxModel> taxList = [];

    await fireStore
        .collection(CollectionName.tax)
        .where('country', isEqualTo: Constant.country)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        TaxModel taxModel = TaxModel.fromJson(element.data());
        taxList.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return taxList;
  }

  static Future<bool?> checkReferralCodeValidOrNot(String referralCode) async {
    bool? isExit;
    try {
      await fireStore
          .collection(CollectionName.referral)
          .where("referralCode", isEqualTo: referralCode)
          .get()
          .then((value) {
        if (value.size > 0) {
          isExit = true;
        } else {
          isExit = false;
        }
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return isExit;
  }

  static Future<ReferralModel?> getReferralUserByCode(
      String referralCode) async {
    ReferralModel? referralModel;
    try {
      await fireStore
          .collection(CollectionName.referral)
          .where("referralCode", isEqualTo: referralCode)
          .get()
          .then((value) {
        referralModel = ReferralModel.fromJson(value.docs.first.data());
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return referralModel;
  }

  static Future<String?> referralAdd(ReferralModel ratingModel) async {
    try {
      await fireStore
          .collection(CollectionName.referral)
          .doc(ratingModel.id)
          .set(ratingModel.toJson());
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return null;
  }

  static Future<bool> updateUser(UserModel userModel) async {
    bool isUpdate = false;
    await fireStore
        .collection(CollectionName.users)
        .doc(userModel.id)
        .set(userModel.toJson(), SetOptions(merge: true))
        .whenComplete(() {
      isUpdate = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isUpdate = false;
    });
    return isUpdate;
  }

  static Future<UserModel?> getUserProfile(String uuid) async {
    print(uuid);
    UserModel? userModel;
    await fireStore
        .collection(CollectionName.users)
        .doc(uuid)
        .get()
        .then((value) {
      if (value.exists) {
        userModel = UserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      userModel = null;
    });
    return userModel;
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
      log(error.toString());
    });
    return languageList;
  }

  static Future<List<ReviewModel>?> getRating(String reviewReceivedId) async {
    List<ReviewModel> taxList = [];

    await fireStore
        .collection(CollectionName.review)
        .where('receiver_id', isEqualTo: reviewReceivedId)
        .orderBy("date", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        ReviewModel taxModel = ReviewModel.fromJson(element.data());
        taxList.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return taxList;
  }

  static Future<bool?> deleteUser() async {
    bool? isDelete;
    try {
      await fireStore
          .collection(CollectionName.users)
          .doc(FireStoreUtils.getCurrentUid())
          .delete();

      // delete user  from firebase auth
      await FirebaseAuth.instance.currentUser!.delete().then((value) {
        isDelete = true;
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return isDelete;
  }

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

  Future<PaymentModel?> getPayment() async {
    PaymentModel? paymentModel;
    await fireStore
        .collection(CollectionName.settings)
        .doc("payment")
        .get()
        .then((value) {
      paymentModel = PaymentModel.fromJson(value.data()!);
    });
    return paymentModel;
  }

  static Future<bool?> updateUserWallet({required String amount}) async {
    bool isAdded = false;
    await getUserProfile(FireStoreUtils.getCurrentUid()).then((value) async {
      if (value != null) {
        UserModel userModel = value;
        userModel.walletAmount =
            (double.parse(userModel.walletAmount.toString()) +
                    double.parse(amount))
                .toString();
        await FireStoreUtils.updateUser(userModel).then((value) {
          isAdded = value;
        });
      }
    });
    return isAdded;
  }

  static Future<bool?> updateOtherUserWallet(
      {required String amount, required String id}) async {
    bool isAdded = false;
    await getUserProfile(id).then((value) async {
      if (value != null) {
        UserModel userModel = value;
        userModel.walletAmount =
            (double.parse(userModel.walletAmount.toString()) +
                    double.parse(amount))
                .toString();
        await FireStoreUtils.updateUser(userModel).then((value) {
          isAdded = value;
        });
      }
    });
    return isAdded;
  }

  static Future<bool?> setSearchHistory(
      RecentSearchModel recentSearchModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.userSearchHistory)
        .doc(recentSearchModel.id)
        .set(recentSearchModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<RecentSearchModel>?> getSearchHistory() async {
    List<RecentSearchModel> list = [];

    await fireStore
        .collection(CollectionName.userSearchHistory)
        .where("userId", isEqualTo: getCurrentUid())
        .orderBy('createdAt', descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        RecentSearchModel searchModel =
            RecentSearchModel.fromJson(element.data());
        list.add(searchModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return list;
  }

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
      log(error.toString());
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
      log(error.toString());
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
      log(error.toString());
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
      log("Failed to update user: $error");
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
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<VehicleInformationModel>?>
      getUserVehicleInformation() async {
    List<VehicleInformationModel> list = [];

    await fireStore
        .collection(CollectionName.userVehicleInformation)
        .where("userId", isEqualTo: getCurrentUid())
        .get()
        .then((value) {
      for (var element in value.docs) {
        VehicleInformationModel searchModel =
            VehicleInformationModel.fromJson(element.data());
        list.add(searchModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return list;
  }

  static Future<bool?> setBooking(BookingModel bookingModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .set(bookingModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> deleteBooking(BookingModel bookingModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .delete()
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<BookingModel>?> getPublishes() async {
    List<BookingModel>? bookingList = [];
    await fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: FireStoreUtils.getCurrentUid())
        .orderBy("createdAt", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        BookingModel documentModel = BookingModel.fromJson(element.data());
        bookingList.add(documentModel);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
    });
    return bookingList;
  }

  static Future<List<BookingModel>?> checkAtivePublishes() async {
    List<BookingModel>? bookingList = [];

    await fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: FireStoreUtils.getCurrentUid())
        .where("status", isNotEqualTo: Constant.completed)
        .where('publish', isEqualTo: true)
        .orderBy("createdAt", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        log("BookingList :: ${element.id}");
        BookingModel documentModel = BookingModel.fromJson(element.data());
        bookingList.add(documentModel);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
    });
    return bookingList;
  }

  static Future<List<BookingModel>?> getMyBooking() async {
    List<BookingModel>? bookingList = [];
    await fireStore
        .collection(CollectionName.booking)
        .where("bookedUserId", arrayContains: FireStoreUtils.getCurrentUid())
        .orderBy("createdAt", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        BookingModel documentModel = BookingModel.fromJson(element.data());
        bookingList.add(documentModel);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
    });
    return bookingList;
  }

  static Future<BookingModel?> getMyBookingNyUserId(String id) async {
    BookingModel? bookingList;
    await fireStore
        .collection(CollectionName.booking)
        .doc(id)
        .get()
        .then((value) {
      if (value.exists) {
        bookingList = BookingModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
    });
    return bookingList;
  }

  static Future<BookedUserModel?> getMyBookingUser(
      BookingModel bookingModel) async {
    BookedUserModel? bookingUserModel;
    String currentUserId = getCurrentUid();

    try {
      // First, try to get from bookedUser subcollection
      await fireStore
          .collection(CollectionName.booking)
          .doc(bookingModel.id)
          .collection("bookedUser")
          .doc(currentUserId)
          .get()
          .then((value) {
        if (value.exists) {
          bookingUserModel = BookedUserModel.fromJson(value.data()!);
          print(
              "Found user in bookedUser subcollection for booking: ${bookingModel.id}");
        }
      }).catchError((error) {
        print("Error checking bookedUser: $error");
      });

      // If not found in bookedUser, check cancelledUser subcollection
      if (bookingUserModel == null) {
        await fireStore
            .collection(CollectionName.booking)
            .doc(bookingModel.id)
            .collection("cancelledUser")
            .doc(currentUserId)
            .get()
            .then((value) {
          if (value.exists) {
            bookingUserModel = BookedUserModel.fromJson(value.data()!);
            print(
                "Found user in cancelledUser subcollection for booking: ${bookingModel.id}");
          }
        }).catchError((error) {
          print("Error checking cancelledUser: $error");
        });
      }

      if (bookingUserModel == null) {
        print(
            "BookedUserModel not found for booking: ${bookingModel.id}, status: ${bookingModel.status}");
      }
    } catch (error) {
      print("Error in getMyBookingUser: $error");
    }

    return bookingUserModel;
  }

  static Future<List<BookedUserModel>?> getMyBookingUserList(
      BookingModel bookingModel) async {
    List<BookedUserModel>? bookingList = [];
    await fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .collection("bookedUser")
        .get()
        .then((value) {
      for (var element in value.docs) {
        BookedUserModel documentModel =
            BookedUserModel.fromJson(element.data());
        bookingList.add(documentModel);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
    });
    return bookingList;
  }

  static Future<bool?> setUserBooking(
      BookingModel bookingModel, BookedUserModel bookingUserModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .collection("bookedUser")
        .doc(bookingUserModel.id)
        .set(bookingUserModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> removeUserBooking(
      BookingModel bookingModel, BookedUserModel bookingUserModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .collection("bookedUser")
        .doc(bookingUserModel.id)
        .delete()
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> setCancelledUserBooking(
      BookingModel bookingModel, BookedUserModel bookingUserModel) async {
    bool isSuccess = false;

    try {
      await fireStore.runTransaction((transaction) async {
        // Get references
        final bookingRef =
            fireStore.collection(CollectionName.booking).doc(bookingModel.id);
        final cancelledUserRef =
            bookingRef.collection("cancelledUser").doc(bookingUserModel.id);
        final bookedUserRef =
            bookingRef.collection("bookedUser").doc(bookingUserModel.id);

        // Add to cancelled users
        transaction.set(cancelledUserRef, bookingUserModel.toJson());

        // Update main booking document
        transaction.update(bookingRef, {
          'bookedSeat': bookingModel.bookedSeat!
              .replaceAll(bookingUserModel.bookedSeat.toString(), ""),
          'selectedSeats': bookingModel.selectedSeats,
          'bookedUserId': bookingModel.bookedUserId,
          'cancelledUserId': bookingModel.cancelledUserId,
          'seatBookings':
              bookingModel.seatBookings?.map((e) => e.toJson()).toList()
        });

        // Remove from booked users
        transaction.delete(bookedUserRef);
      });

      isSuccess = true;
    } catch (error) {
      print('Error in setCancelledUserBooking: $error');
      isSuccess = false;
    }

    return isSuccess;
  }

  static Future<List<DocumentModel>> getDocumentList() async {
    List<DocumentModel> documentList = [];
    await fireStore
        .collection(CollectionName.documents)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        DocumentModel documentModel = DocumentModel.fromJson(element.data());
        documentList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return documentList;
  }

  static Future<UserVerificationModel?> getDocumentOfDriver() async {
    UserVerificationModel? driverDocumentModel;
    await fireStore
        .collection(CollectionName.userVerification)
        .doc(getCurrentUid())
        .get()
        .then((value) async {
      if (value.exists) {
        driverDocumentModel = UserVerificationModel.fromJson(value.data()!);
      }
    });
    return driverDocumentModel;
  }

  static Future<bool> uploadDriverDocument(Documents documents) async {
    bool isAdded = false;
    UserVerificationModel driverDocumentModel = UserVerificationModel();
    List<Documents> documentsList = [];
    await fireStore
        .collection(CollectionName.userVerification)
        .doc(getCurrentUid())
        .get()
        .then((value) async {
      if (value.exists) {
        UserVerificationModel newDriverDocumentModel =
            UserVerificationModel.fromJson(value.data()!);
        documentsList = newDriverDocumentModel.documents!;
        var contain = newDriverDocumentModel.documents!
            .where((element) => element.documentId == documents.documentId);
        if (contain.isEmpty) {
          documentsList.add(documents);

          driverDocumentModel.id = getCurrentUid();
          driverDocumentModel.documents = documentsList;
        } else {
          var index = newDriverDocumentModel.documents!.indexWhere(
              (element) => element.documentId == documents.documentId);

          driverDocumentModel.id = getCurrentUid();
          documentsList.removeAt(index);
          documentsList.insert(index, documents);
          driverDocumentModel.documents = documentsList;
          isAdded = false;
          ShowToastDialog.showToast("Document is under verification");
        }
      } else {
        documentsList.add(documents);
        driverDocumentModel.id = getCurrentUid();
        driverDocumentModel.documents = documentsList;
      }
    });

    await fireStore
        .collection(CollectionName.userVerification)
        .doc(getCurrentUid())
        .set(driverDocumentModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
      log(error.toString());
    });

    return isAdded;
  }

  static Future<bool?> setWalletTransaction(
      WalletTransactionModel walletTransactionModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.walletTransaction)
        .doc(walletTransactionModel.id)
        .set(walletTransactionModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    List<WalletTransactionModel> walletTransactionModel = [];

    await fireStore
        .collection(CollectionName.walletTransaction)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
        .orderBy('createdDate', descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        WalletTransactionModel taxModel =
            WalletTransactionModel.fromJson(element.data());
        walletTransactionModel.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return walletTransactionModel;
  }

  static Future<bool?> setReport(ReportModel recentSearchModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.report)
        .doc(recentSearchModel.id)
        .set(recentSearchModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<NotificationModel?> getNotificationContent(String type) async {
    NotificationModel? notificationModel;
    await fireStore
        .collection(CollectionName.dynamicNotification)
        .where('type', isEqualTo: type)
        .get()
        .then((value) {
      print("------>");
      if (value.docs.isNotEmpty) {
        print(value.docs.first.data());
        notificationModel = NotificationModel.fromJson(value.docs.first.data());
      } else {
        notificationModel = NotificationModel(
            id: "",
            message: "Notification setup is pending",
            subject: "setup notification",
            type: "");
      }
    });
    return notificationModel;
  }

  static Future<ReviewModel?> getReview(
      {required String bookingId, required String senderId}) async {
    ReviewModel? reviewModel;
    await fireStore
        .collection(CollectionName.review)
        .where('booking_id', isEqualTo: bookingId)
        .where(
          'sender_id',
          isEqualTo: senderId,
        )
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        reviewModel = ReviewModel.fromJson(value.docs.first.data());
      }
    });
    return reviewModel;
  }

  static Future<ReviewModel?> getReviewByReceiverId(
      {required String bookingId, required String receiverId}) async {
    ReviewModel? reviewModel;
    await fireStore
        .collection(CollectionName.review)
        .where('booking_id', isEqualTo: bookingId)
        .where(
          'receiver_id',
          isEqualTo: receiverId,
        )
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        reviewModel = ReviewModel.fromJson(value.docs.first.data());
      }
    });
    return reviewModel;
  }

  static Future<bool?> setReview(ReviewModel reviewModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.review)
        .doc(reviewModel.id)
        .set(reviewModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<WithdrawMethodModel?> getWithdrawMethod() async {
    WithdrawMethodModel? withdrawMethodModel;
    await fireStore
        .collection(CollectionName.withdrawMethod)
        .where("userId", isEqualTo: getCurrentUid())
        .get()
        .then((value) async {
      if (value.docs.isNotEmpty) {
        withdrawMethodModel =
            WithdrawMethodModel.fromJson(value.docs.first.data());
      }
    });
    return withdrawMethodModel;
  }

  static Future<WithdrawMethodModel?> setWithdrawMethod(
      WithdrawMethodModel withdrawMethodModel) async {
    if (withdrawMethodModel.id == null) {
      withdrawMethodModel.id = Constant.getUuid();
      withdrawMethodModel.userId = getCurrentUid();
    }
    await fireStore
        .collection(CollectionName.withdrawMethod)
        .doc(withdrawMethodModel.id)
        .set(withdrawMethodModel.toJson())
        .then((value) async {});
    return withdrawMethodModel;
  }

  static Future<bool?> setWithdrawRequest(WithdrawModel withdrawModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.withdrawalHistory)
        .doc(withdrawModel.id)
        .set(withdrawModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<WithdrawModel>?> getWithDrawRequest() async {
    List<WithdrawModel> withdrawalList = [];
    await fireStore
        .collection(CollectionName.withdrawalHistory)
        .where('userId', isEqualTo: getCurrentUid())
        .orderBy('createdDate', descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        WithdrawModel documentModel = WithdrawModel.fromJson(element.data());
        withdrawalList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return withdrawalList;
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
      log('Error fetching advertise banners: $error', stackTrace: stackTrace);
    }
    return [];
  }

  static late StreamSubscription<QuerySnapshot> adminChatSeenSubscription;
  static void setSeen() {
    final currentUserId = FireStoreUtils.getCurrentUid();

    adminChatSeenSubscription = FirebaseFirestore.instance
        .collection(CollectionName.adminChat)
        .doc(currentUserId)
        .collection("thread")
        .where('senderId', isEqualTo: Constant.adminType)
        .where('seen', isEqualTo: false)
        .snapshots()
        .listen((querySnapshot) async {
      for (final doc in querySnapshot.docs) {
        try {
          await doc.reference.update({'seen': true});
        } catch (e) {
          log(e.toString());
        }
      }
    }, onError: (error) {
      log(error.toString());
    });
  }

  static void stopSeenListener() {
    adminChatSeenSubscription.cancel();
  }

  static Future addInAdminBox(InboxAdminModel inboxModel) async {
    return await fireStore
        .collection(CollectionName.adminChat)
        .doc(FireStoreUtils.getCurrentUid())
        .set(inboxModel.toJson())
        .then((document) {
      return inboxModel;
    });
  }

  static Future addAdminChat(ConversationAdminModel conversationModel) async {
    return await fireStore
        .collection(CollectionName.adminChat)
        .doc(conversationModel.senderId)
        .collection("thread")
        .doc(conversationModel.id)
        .set(conversationModel.toJson())
        .then((document) {
      return conversationModel;
    });
  }

  static Future<SosModel?> getSOS(
      {required String bookingId,
      required String driverId,
      required String customerId}) async {
    SosModel? sosModel;
    try {
      await fireStore
          .collection(CollectionName.sos)
          .where("bookingId", isEqualTo: bookingId)
          .where("customerId", isEqualTo: customerId)
          .where("driverId", isEqualTo: driverId)
          .get()
          .then((value) {
        sosModel = SosModel.fromJson(value.docs.first.data());
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return sosModel;
  }

  static Future<bool?> setSOS(SosModel sosModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.sos)
        .doc(sosModel.id)
        .set(sosModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<BookingModel>?> getCancelledBookings() async {
    List<BookingModel>? bookingList = [];
    await fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: FireStoreUtils.getCurrentUid())
        .where("status", isEqualTo: Constant.canceled)
        .orderBy("createdAt", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        BookingModel documentModel = BookingModel.fromJson(element.data());
        bookingList.add(documentModel);
      }
    }).catchError((error) {
      log("Failed to get cancelled bookings: $error");
    });
    return bookingList;
  }

  static Future<List<BookingModel>?> getCompletedBookings() async {
    List<BookingModel>? bookingList = [];
    await fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: FireStoreUtils.getCurrentUid())
        .where("status", isEqualTo: Constant.completed)
        .orderBy("createdAt", descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        BookingModel documentModel = BookingModel.fromJson(element.data());
        bookingList.add(documentModel);
      }
    }).catchError((error) {
      log("Failed to get completed bookings: $error");
    });
    return bookingList;
  }

  // Real-time stream methods for live data updates

  static Stream<List<BookingModel>> getMyBookingStream() {
    String currentUid = getCurrentUid();
    return fireStore
        .collection(CollectionName.booking)
        .where("bookedUserId", arrayContains: currentUid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      List<BookingModel> bookingList = [];
      for (var doc in snapshot.docs) {
        BookingModel documentModel = BookingModel.fromJson(doc.data());
        documentModel.id = doc.id;
        bookingList.add(documentModel);
      }
      return bookingList;
    });
  }

  static Stream<List<BookingModel>> getPublishesStream() {
    String currentUid = getCurrentUid();
    return fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: currentUid)
        .where("status", whereNotIn: [Constant.completed, Constant.canceled])
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          List<BookingModel> bookingList = [];
          for (var doc in snapshot.docs) {
            BookingModel documentModel = BookingModel.fromJson(doc.data());
            documentModel.id = doc.id;
            bookingList.add(documentModel);
          }
          return bookingList;
        });
  }

  static Stream<List<BookingModel>> getCancelledBookingsStream() {
    String currentUid = getCurrentUid();

    // Driver cancelled bookings
    Stream<List<BookingModel>> driverStream = fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: currentUid)
        .where("status", isEqualTo: Constant.canceled)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      List<BookingModel> bookingList = [];
      for (var doc in snapshot.docs) {
        BookingModel documentModel = BookingModel.fromJson(doc.data());
        documentModel.id = doc.id;
        bookingList.add(documentModel);
      }
      return bookingList;
    });

    // Passenger cancelled bookings
    Stream<List<BookingModel>> passengerStream = fireStore
        .collection(CollectionName.booking)
        .where("bookedUserId", arrayContains: currentUid)
        .where("status", isEqualTo: Constant.canceled)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      List<BookingModel> bookingList = [];
      for (var doc in snapshot.docs) {
        BookingModel documentModel = BookingModel.fromJson(doc.data());
        documentModel.id = doc.id;
        bookingList.add(documentModel);
      }
      return bookingList;
    });

    // Combine and deduplicate the streams
    return Rx.combineLatest2(driverStream, passengerStream,
        (List<BookingModel> driverBookings,
            List<BookingModel> passengerBookings) {
      Set<String> addedIds = {};
      List<BookingModel> allBookings = [];

      // Add driver bookings
      for (var booking in driverBookings) {
        if (!addedIds.contains(booking.id)) {
          allBookings.add(booking);
          addedIds.add(booking.id!);
        }
      }

      // Add passenger bookings (avoid duplicates)
      for (var booking in passengerBookings) {
        if (!addedIds.contains(booking.id)) {
          allBookings.add(booking);
          addedIds.add(booking.id!);
        }
      }

      // Sort by creation date
      allBookings.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return allBookings;
    });
  }

  static Stream<List<BookingModel>> getCompletedBookingsStream() {
    String currentUid = getCurrentUid();

    // Combine both driver and passenger completed bookings
    Stream<List<BookingModel>> driverStream = fireStore
        .collection(CollectionName.booking)
        .where("createdBy", isEqualTo: currentUid)
        .where("status", isEqualTo: Constant.completed)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      List<BookingModel> bookingList = [];
      for (var doc in snapshot.docs) {
        BookingModel documentModel = BookingModel.fromJson(doc.data());
        documentModel.id = doc.id;
        bookingList.add(documentModel);
      }
      return bookingList;
    });

    Stream<List<BookingModel>> passengerStream = fireStore
        .collection(CollectionName.booking)
        .where("bookedUserId", arrayContains: currentUid)
        .where("status", isEqualTo: Constant.completed)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      List<BookingModel> bookingList = [];
      for (var doc in snapshot.docs) {
        BookingModel documentModel = BookingModel.fromJson(doc.data());
        documentModel.id = doc.id;
        bookingList.add(documentModel);
      }
      return bookingList;
    });

    // Combine and deduplicate the streams
    return Rx.combineLatest2(driverStream, passengerStream,
        (List<BookingModel> driverBookings,
            List<BookingModel> passengerBookings) {
      Set<String> addedIds = {};
      List<BookingModel> allBookings = [];

      // Add driver bookings
      for (var booking in driverBookings) {
        if (!addedIds.contains(booking.id)) {
          allBookings.add(booking);
          addedIds.add(booking.id!);
        }
      }

      // Add passenger bookings (avoid duplicates)
      for (var booking in passengerBookings) {
        if (!addedIds.contains(booking.id)) {
          allBookings.add(booking);
          addedIds.add(booking.id!);
        }
      }

      // Sort by creation date
      allBookings.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return allBookings;
    });
  }

  // Real-time stream for BookedUserModel - checks both bookedUser and cancelledUser
  static Stream<BookedUserModel?> getMyBookingUserStream(
      BookingModel bookingModel) {
    String currentUserId = getCurrentUid();

    // Check bookedUser collection first
    Stream<BookedUserModel?> bookedUserStream = fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .collection("bookedUser")
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return BookedUserModel.fromJson(snapshot.data()!);
      }
      return null;
    });

    // Check cancelledUser collection
    Stream<BookedUserModel?> cancelledUserStream = fireStore
        .collection(CollectionName.booking)
        .doc(bookingModel.id)
        .collection("cancelledUser")
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return BookedUserModel.fromJson(snapshot.data()!);
      }
      return null;
    });

    // Combine both streams - return bookedUser if exists, otherwise cancelledUser
    return Rx.combineLatest2(bookedUserStream, cancelledUserStream,
        (BookedUserModel? bookedUser, BookedUserModel? cancelledUser) {
      return bookedUser ?? cancelledUser;
    });
  }
}
