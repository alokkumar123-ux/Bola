import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:asn1lib/asn1lib.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:get/get.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:location/location.dart' as loc;
import 'package:pointycastle/export.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/admin_commission.dart';
import 'package:poolmate/model/chat_video_container.dart';
import 'package:poolmate/model/conversation_admin_model.dart';
import 'package:poolmate/model/currency_model.dart';
import 'package:poolmate/model/language_model.dart';
import 'package:poolmate/model/map/geometry.dart';
import 'package:poolmate/model/tax_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/utils/preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class Constant {
  static const String phoneLoginType = "phone";
  static const String googleLoginType = "google";
  static const String appleLoginType = "apple";

  static String mapAPIKey = "AIzaSyDAIpqyeb9GfM3YiztaLTDLcajOelWyqR8";
  static String distanceType = "";

  static String senderId = '';
  static String jsonNotificationFileURL = '';

  static String priceVariation = "5";
  static String radius = "5";
  static String intervalHoursForPublishNewRide = "0";

  static String appBannerImageDark = "";
  static String appBannerImageLight = "";
  static String termsAndConditions = "";
  static String privacyPolicy = "";
  static String supportURL = "";
  static String minimumAmountToDeposit = "0.0";
  static String minimumAmountToWithdrawal = "0.0";
  static String? referralAmount = "0.0";
  static bool? verifyPublish = false;
  static bool? verifyBooking = false;

  static List<TaxModel>? taxList;
  static String? country;
  static AdminCommission? adminCommission;

  static CurrencyModel? currencyModel;

  static const String placed = "placed";
  static const String onGoing = "onGoing";
  static const String completed = "completed";
  static const String canceled = "canceled";

  static String? adminType = "admin";

  static String globalUrl = "";

  // Cashfree Aadhaar Verification API Configuration
  static const String cashfreeClientId = "CF271586D337NM7VKOUC73C863DG";
  static const String cashfreeClientSecret =
      "cfsk_ma_prod_7055d0e9c68f5d29fd56c379787d7390_dfb50f8d";
  static const String cashfreeSandboxBaseUrl =
      "https://sandbox.cashfree.com/verification/offline-aadhaar";
  static const String cashfreeProductionBaseUrl =
      "https://api.cashfree.com/verification/offline-aadhaar";
  static const bool useCashfreeSandbox = false; // Set to false for production

  // Cashfree Public Key for 2FA Signature Generation
  static const String cashfreePublicKey =
      "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAs3Mh+ZDqsp2g8Gph8fHf2mhhhz0rivDlvIuDVWOmFf5UYrIbLWj8MRCVtcAQjCrcKOVCK9FtAoXvjczx9h0+ZxpdYaXPbTTyL5/xkwwEdX1UDBz5qfRHJDBLJT6L5yn0tqAg3JUsLT8wCotdjD/cRVTD+MgejqfdSO1ZjcK/TjfiZRwgzErtKRXWvJ4DT9Js/6JVVeMuRHt7TFaWS/AxWStJcLG84P9Vht7eS1AWigpR7wlUe1EPmQkL4Q34TIq+fxS8j8gevxui72CwD5i13wjvO8hLDXYqAIGN+BdO5vArAVEC7M8xnojqFlj+l8XYK6Xk9MSL2MJ/RJJP1oNOnQIDAQAB";

  /// Generate Cashfree 2FA signature for API authentication
  /// This method follows the Cashfree documentation for signature generation:
  /// 1. Create clientId.timestamp string
  /// 2. Encrypt using RSA with the provided public key
  /// 3. Return base64 encoded signature
  static String generateCashfreeSignature() {
    try {
      // Step 1: Create clientId with current UNIX timestamp
      final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final String dataToEncrypt = '$cashfreeClientId.$timestamp';

      print('Generating signature for: $dataToEncrypt');

      // Step 2: Parse the public key
      final RSAPublicKey publicKey = _parsePublicKey(cashfreePublicKey);
      print('RSA public key parsed successfully');

      // Step 3: Encrypt using RSA/ECB/OAEPWithSHA-1AndMGF1Padding (as per Cashfree docs)
      // Note: pointycastle's OAEPEncoding uses SHA-1 by default, which matches Cashfree's requirement
      final encrypter = OAEPEncoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

      // Convert string to bytes
      final Uint8List dataBytes =
          Uint8List.fromList(utf8.encode(dataToEncrypt));
      print('Data bytes length: ${dataBytes.length}');

      // Encrypt the data
      final Uint8List encryptedBytes = encrypter.process(dataBytes);
      print('Encrypted bytes length: ${encryptedBytes.length}');

      // Step 4: Return base64 encoded signature
      final String signature = base64.encode(encryptedBytes);
      print('Generated signature length: ${signature.length}');

      return signature;
    } catch (e) {
      print('Error in generateCashfreeSignature: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to generate Cashfree signature: $e');
    }
  }

  /// Get headers for Cashfree API requests with 2FA signature
  /// Usage example:
  /// ```dart
  /// final headers = Constant.getCashfreeHeaders();
  /// final response = await http.post(
  ///   Uri.parse('${Constant.cashfreeProductionBaseUrl}/verify'),
  ///   headers: headers,
  ///   body: jsonEncode(requestData),
  /// );
  /// ```
  static Map<String, String> getCashfreeHeaders() {
    try {
      final signature = generateCashfreeSignature();
      print('Generated X-Cf-Signature: ${signature.substring(0, 50)}...');

      final headers = {
        'Content-Type': 'application/json',
        'X-Client-Id': cashfreeClientId,
        'X-Client-Secret': cashfreeClientSecret,
        'X-Cf-Signature': signature,
      };

      print('Headers keys: ${headers.keys.toList()}');
      return headers;
    } catch (e) {
      print('Error generating Cashfree headers: $e');
      // Return headers without signature as fallback
      return {
        'Content-Type': 'application/json',
        'X-Client-Id': cashfreeClientId,
        'X-Client-Secret': cashfreeClientSecret,
      };
    }
  }

  /// Test method to verify signature generation
  /// Call this method to test if the signature generation is working
  static void testSignatureGeneration() {
    try {
      print('Testing Cashfree signature generation...');
      final headers = getCashfreeHeaders();
      print(
          'Test successful! Headers generated with keys: ${headers.keys.toList()}');

      if (headers.containsKey('X-Cf-Signature')) {
        final signature = headers['X-Cf-Signature']!;
        print('✅ X-Cf-Signature generated successfully');
        print('   Length: ${signature.length} characters');
        print(
            '   Preview: ${signature.substring(0, signature.length > 50 ? 50 : signature.length)}...');
      } else {
        print('❌ X-Cf-Signature NOT found in headers');
      }
    } catch (e) {
      print('❌ Test failed: $e');
    }
  }

  /// Parse RSA public key from base64 string
  /// Fixed to handle the public key format correctly
  static RSAPublicKey _parsePublicKey(String publicKeyString) {
    try {
      // The public key is already in DER format (base64 encoded)
      final Uint8List keyBytes = base64.decode(publicKeyString);

      print('Key bytes length: ${keyBytes.length}');
      print('First few bytes: ${keyBytes.take(10).toList()}');

      // Parse the DER encoded public key
      final parser = ASN1Parser(keyBytes);
      final ASN1Sequence publicKeySeq = parser.nextObject() as ASN1Sequence;

      // The structure should be: SEQUENCE { algorithm, publicKey }
      // Skip the algorithm identifier for now
      final ASN1BitString publicKeyBitString =
          publicKeySeq.elements[1] as ASN1BitString;

      // Extract the actual public key data
      final Uint8List publicKeyData = publicKeyBitString.valueBytes();

      // Parse the RSA public key structure
      final keyParser = ASN1Parser(publicKeyData);
      final ASN1Sequence rsaKeySeq = keyParser.nextObject() as ASN1Sequence;

      // RSA public key: SEQUENCE { modulus, exponent }
      final ASN1Integer modulus = rsaKeySeq.elements[0] as ASN1Integer;
      final ASN1Integer exponent = rsaKeySeq.elements[1] as ASN1Integer;

      print('Modulus length: ${modulus.valueAsBigInteger.bitLength}');
      print('Exponent: ${exponent.valueAsBigInteger}');

      return RSAPublicKey(
          modulus.valueAsBigInteger, exponent.valueAsBigInteger);
    } catch (e, stackTrace) {
      print('Error parsing RSA public key: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to parse RSA public key: $e');
    }
  }

  static const userPlaceHolder = 'assets/images/user_placeholder.png';
  static const getStartedImage =
      'assets/images/ic_logo.png';

  static const chattiness = [
    'I love to chat',
    'I’m chatty when I feel comfortable',
    'I’m the quite type'
  ];
  static const smoking = [
    'I’m fine with smoking',
    'Cigarette breaks outside the car are ok',
    'No smoking, Please'
  ];
  static const music = [
    'It’s all about the playlist!',
    'I’ll jam depending on the moon',
    'Silence is golden'
  ];
  static const pets = [
    'Pet welcome. woof!',
    'I’ll travel with pets depending on the animal',
    'I’d prefer not to travel with pet'
  ];

  static const booking_confirmed = "booking_confirmed";
  static const payment_successful = "payment_successful";
  static const ride_arrive = "ride_arrive";
  static const booking_confirmed_by_passager = "booking_confirmed_by_passager";

  static String orderId({String orderId = ''}) {
    return "#${(orderId).substring(orderId.length - 6)}";
  }

  static String orderIdwithoutHash({String orderId = ''}) {
    return (orderId).substring(orderId.length - 6);
  }

  static String amountShow({required String? amount}) {
    if (Constant.currencyModel!.symbolAtRight == true) {
      return "${double.parse(amount.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!)}${Constant.currencyModel!.symbol.toString()}";
    } else {
      return "${Constant.currencyModel!.symbol.toString()} ${double.parse(amount.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!)}";
    }
  }

  static distanceCalculate(String value) {
    String distance = "0.0";
    if (Constant.distanceType.toLowerCase() == "Km".toLowerCase()) {
      distance = (double.parse(value) / 1000).toStringAsFixed(0);
    } else {
      distance = (double.parse(value) / 1609.34).toStringAsFixed(0);
    }
    return distance;
  }

  double calculateTax({String? amount, TaxModel? taxModel}) {
    double taxAmount = 0.0;
    if (taxModel != null && taxModel.enable == true) {
      if (taxModel.type == "fix") {
        taxAmount = double.parse(taxModel.tax.toString());
      } else {
        taxAmount = (double.parse(amount.toString()) *
                double.parse(taxModel.tax!.toString())) /
            100;
      }
    }
    return taxAmount;
  }

  static double calculateOrderAdminCommission(
      {String? amount, AdminCommission? adminCommission}) {
    double taxAmount = 0.0;
    if (adminCommission != null) {
      if (adminCommission.type == "fix") {
        taxAmount = double.parse(adminCommission.amount.toString());
      } else {
        taxAmount = (double.parse(amount.toString()) *
                double.parse(adminCommission.amount!.toString())) /
            100;
      }
    }
    return taxAmount;
  }

  static getCityName(themeChange, Location location, {TextStyle? style}) {
    // Check if coordinates are valid before making the API call
    if (location.lat == null ||
        location.lng == null ||
        location.lat == 0.0 ||
        location.lng == 0.0) {
      return Text(
        "Location",
        maxLines: 1,
        style: style ??
            TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey100
                    : AppThemeData.grey800,
                fontFamily: AppThemeData.bold,
                fontSize: 14),
      );
    }

    // For web platform, geocoding doesn't work reliably - return placeholder
    if (kIsWeb) {
      return Text(
        "Location",
        maxLines: 1,
        style: style ??
            TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey100
                    : AppThemeData.grey800,
                fontFamily: AppThemeData.bold,
                fontSize: 14),
      );
    }

    return FutureBuilder<List<geocoding.Placemark>?>(
        future: geocoding
            .placemarkFromCoordinates(location.lat!, location.lng!)
            .catchError((error) {
          // Catch any errors from geocoding and return empty list
          return <geocoding.Placemark>[];
        }),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const SizedBox();
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Text(
                  "Location",
                  maxLines: 1,
                  style: style ??
                      TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey100
                              : AppThemeData.grey800,
                          fontFamily: AppThemeData.bold,
                          fontSize: 14),
                );
              } else {
                // Add null safety checks for web compatibility
                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  // Fallback: show coordinates or a placeholder
                  return Text(
                    "Location",
                    maxLines: 1,
                    style: style ??
                        TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey100
                                : AppThemeData.grey800,
                            fontFamily: AppThemeData.bold,
                            fontSize: 14),
                  );
                }

                // Check if locality is available, otherwise use other placemark data
                final placemark = snapshot.data!.first;
                final cityName = placemark.locality ??
                    placemark.subLocality ??
                    placemark.administrativeArea ??
                    "Location";

                return Text(
                  cityName,
                  maxLines: 1,
                  style: style ??
                      TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey100
                              : AppThemeData.grey800,
                          fontFamily: AppThemeData.bold,
                          fontSize: 14),
                );
              }
            default:
              return Text('Error'.tr);
          }
        });
  }

  static double getPlusPercentageAmount(String amount) {
    return double.parse(amount) +
        ((double.parse(amount.toString()) *
                double.parse(Constant.priceVariation)) /
            100);
  }

  static double getMinusPercentageAmount(String amount) {
    return double.parse(amount) -
        (double.parse(amount.toString()) *
                double.parse(Constant.priceVariation)) /
            100;
  }

  static String calculateReview(
      {required String? reviewCount, required String? reviewSum}) {
    if (reviewCount == null && reviewSum == null) {
      return "0";
    }
    if (reviewCount == "0.0" && reviewSum == "0.0") {
      return "0";
    }
    return (double.parse(reviewSum.toString()) /
            double.parse(reviewCount.toString()))
        .toStringAsFixed(1);
  }

  static String getUuid() {
    return const Uuid().v4();
  }

  static Widget loader() {
    return Center(
        child: LoadingAnimationWidget.flickr(
            leftDotColor: Colors.grey, rightDotColor: Colors.black, size: 60));
  }

  static Widget showEmptyView(
      {required String message, required bool isDarkMode}) {
    return Center(
      child: Text(message,
          style: TextStyle(
              color: isDarkMode ? AppThemeData.grey50 : AppThemeData.grey700,
              fontFamily: AppThemeData.medium,
              fontSize: 18)),
    );
  }

  static String getReferralCode() {
    var rng = math.Random();
    return (rng.nextInt(900000) + 100000).toString();
  }

  static LanguageModel getLanguage() {
    final String user = Preferences.getString(Preferences.languageCodeKey);
    Map<String, dynamic> userMap = jsonDecode(user);
    return LanguageModel.fromJson(userMap);
  }

  String? validateRequired(String? value, String type) {
    if (value!.isEmpty) {
      return '$type required';
    }
    return null;
  }

  static bool? validateEmail(String? value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = RegExp(pattern);
    if (value == null || value.isEmpty) {
      return false;
    } else if (!regExp.hasMatch(value)) {
      return false;
    } else {
      return true;
    }
  }

  bool hasValidUrl(String value) {
    String pattern =
        r'(http|https)://[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:/~+#-]*[\w@?^=%&amp;/~+#-])?';
    RegExp regExp = RegExp(pattern);
    if (value.isEmpty) {
      return false;
    } else if (!regExp.hasMatch(value)) {
      return false;
    }
    return true;
  }

  static Future<String> uploadUserImageToFireStorage(
      File image, String filePath, String fileName) async {
    Reference upload =
        FirebaseStorage.instance.ref().child('$filePath/$fileName');
    UploadTask uploadTask = upload.putFile(image);
    var downloadUrl =
        await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  static Future<void> makePhoneCall(String phoneNumber) async {
    try {
      print(phoneNumber);
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      await launchUrl(launchUri);
    } catch (e) {
      print(e);
    }
  }

  launchURL(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  static Future<TimeOfDay?> selectTime(context) async {
    FocusScope.of(context).requestFocus(FocusNode()); //remove focus
    TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (newTime != null) {
      return newTime;
    }
    return null;
  }

  static dateCustomizationShow(DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    final aDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    if (aDate == today) {
      return "Today";
    } else if (aDate == tomorrow) {
      return "Tomorrow";
    } else {
      return DateFormat('MMMM dd,yyyy').format(selectedDate);
    }
  }

  static Future<DateTime?> selectDate(context) async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppThemeData.primary300, // header background color
                onPrimary: AppThemeData.grey900, // header text color
                onSurface: AppThemeData.grey900, // body text color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppThemeData.grey900, // button text color
                ),
              ),
            ),
            child: child!,
          );
        },
        initialDate: DateTime.now(),
        //get today's date
        firstDate: DateTime(2000),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime(2101));
    return pickedDate;
  }

  static Future<DateTime?> selectFeatureDate(context, DateTime? date) async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppThemeData.primary300, // header background color
                onPrimary: AppThemeData.grey900, // header text color
                onSurface: AppThemeData.grey900, // body text color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppThemeData.grey900, // button text color
                ),
              ),
            ),
            child: child!,
          );
        },
        initialDate: date,
        //get today's date
        firstDate: DateTime.now(),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime(2101));
    return pickedDate;
  }

  static Future<DateTime?> selectPastDate(context) async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppThemeData.primary300, // header background color
                onPrimary: AppThemeData.grey900, // header text color
                onSurface: AppThemeData.grey900, // body text color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppThemeData.grey900, // button text color
                ),
              ),
            ),
            child: child!,
          );
        },
        initialDate: DateTime(2008),
        //get today's date
        firstDate: DateTime(1800),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime(2008));
    return pickedDate;
  }

  static String timestampToDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM dd,yyyy').format(dateTime);
  }

  static String timestampToDateTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM dd,yyyy hh:mm aa').format(dateTime);
  }

  static String dateToString(DateTime timestamp) {
    return DateFormat('MMM dd,yyyy hh:mm aa').format(timestamp);
  }

  static String timestampToTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm aa').format(dateTime);
  }

  static String timestampToDateChat(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  static double calculateAdminCommission(
      {String? amount, AdminCommission? adminCommission}) {
    double taxAmount = 0.0;
    if (adminCommission != null && adminCommission.enable == true) {
      if (adminCommission.type == "fix") {
        taxAmount = double.parse(adminCommission.amount.toString());
      } else {
        taxAmount = (double.parse(amount.toString()) *
                double.parse(adminCommission.amount!.toString())) /
            100;
      }
    }
    return taxAmount;
  }

  static String maskingString(String documentId, int maskingDigit) {
    String maskedDigits = documentId;
    for (int i = 0; i < documentId.length - maskingDigit; i++) {
      maskedDigits = maskedDigits.replaceFirst(documentId[i], "*");
    }
    return maskedDigits;
  }

  static double calculateDistance(Location start, Location end) {
    var p =
        0.017453292519943295; //conversion factor from radians to decimal degrees, exactly math.pi/180
    var c = cos;
    var a = 0.5 -
        c((end.lat! - start.lat!) * p) / 2 +
        c(start.lat! * p) *
            c(end.lat! * p) *
            (1 - c((end.lng! - start.lng!) * p)) /
            2;
    var radiusOfEarth = 6371;
    return radiusOfEarth * 2 * asin(sqrt(a));
  }

  static List<LatLng> decodePolyline(String poly) {
    List<LatLng> polylineCoordinates = [];
    int index = 0, len = poly.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylineCoordinates
          .add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }

    return polylineCoordinates;
  }

  String getDurationString(int totalMinutes) {
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    String hourPart = hours > 0 ? '$hours hour${hours > 1 ? 's' : ''}' : '';
    String minutePart =
        minutes > 0 ? '$minutes min${minutes > 1 ? 's' : ''}' : '';
    if (hourPart.isNotEmpty && minutePart.isNotEmpty) {
      return '$hourPart $minutePart';
    } else if (hourPart.isNotEmpty) {
      return hourPart;
    } else {
      return minutePart;
    }
  }

  String getDistanceString(int totalMinutes) {
    double kilometers = totalMinutes / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  }

  Duration stringConvertIntoDuration(String time) {
    try {
      String timeString = time;
      List<String> timeParts = timeString.split(' ');
      int hours = int.parse(timeParts[0]);
      int minutes = int.parse(timeParts[2]);
      return Duration(hours: hours, minutes: minutes);
    } catch (e) {
      return Duration();
    }
  }

  static String dateAndTimeFormatTimestamp(Timestamp? timestamp) {
    var format = DateFormat('dd MMM yyyy hh:mm aa'); // <- use skeleton here
    return format.format(timestamp!.toDate());
  }

  Future<Url> uploadChatImageToFireStorage(File image) async {
    ShowToastDialog.showLoader('Uploading image...');
    var uniqueID = const Uuid().v4();
    Reference upload =
        FirebaseStorage.instance.ref().child('/chat/images/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(image);
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    ShowToastDialog.closeLoader();
    return Url(
        mime: metaData.contentType ?? 'image', url: downloadUrl.toString());
  }

  Future<ChatVideoContainer?> uploadChatVideoToFireStorage(File video) async {
    try {
      ShowToastDialog.showLoader("Uploading video...");
      final String uniqueID = const Uuid().v4();
      final Reference videoRef =
          FirebaseStorage.instance.ref('videos/$uniqueID.mp4');
      final UploadTask uploadTask = videoRef.putFile(
        video,
        SettableMetadata(contentType: 'video/mp4'),
      );
      await uploadTask;
      final String videoUrl = await videoRef.getDownloadURL();
      ShowToastDialog.showLoader("Generating thumbnail...");
      final Uint8List thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: video.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        maxWidth: 200,
        quality: 75,
      );

      if (thumbnailBytes == null || thumbnailBytes.isEmpty) {
        throw Exception("Failed to generate thumbnail.");
      }

      final String thumbnailID = const Uuid().v4();
      final Reference thumbnailRef =
          FirebaseStorage.instance.ref('thumbnails/$thumbnailID.jpg');
      final UploadTask thumbnailUploadTask = thumbnailRef.putData(
        thumbnailBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await thumbnailUploadTask;
      final String thumbnailUrl = await thumbnailRef.getDownloadURL();
      // ignore: unused_local_variable
      var metaData = await thumbnailRef.getMetadata();
      ShowToastDialog.closeLoader();

      return ChatVideoContainer(
          videoUrl: Url(url: videoUrl.toString(), mime: 'video/mp4'),
          thumbnailUrl: thumbnailUrl);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: ${e.toString()}");
      return null;
    }
  }

  static Future<loc.LocationData?> getCurrentLocation() async {
    loc.Location location = loc.Location();

    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }
}

class PointLatLng {
  double latitude;
  double longitude;

  PointLatLng(this.latitude, this.longitude);
}
