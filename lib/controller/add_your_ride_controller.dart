import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_map;
import 'package:poolmate/app/dashboard_screen.dart';
import 'package:poolmate/app/wallet_screen/wallet_screen.dart';
import 'package:poolmate/controller/dashboard_controller.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/map/city_list_model.dart';
import 'package:poolmate/model/map/direction_api_model.dart';
import 'package:poolmate/model/map/geometry.dart';
import 'package:poolmate/model/ride_alert_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/model/vehicle_information_model.dart';
import 'package:poolmate/constant/send_notification.dart';
import 'package:poolmate/firebase_options.dart';
import 'package:poolmate/services/whatsapp_service.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/booking_utils.dart';
import 'package:poolmate/utils/firestore/ridealert_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/vehicle_utils.dart';
import 'package:poolmate/utils/notification_service.dart';
import '../themes/app_them_data.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AddYourRideController extends GetxController {
  Rx<TextEditingController> pickUpLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> dropLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> selectedVehicleController =
      TextEditingController().obs;
  Rx<TextEditingController> dateController = TextEditingController().obs;
  Rx<TextEditingController> additionalRequirementsController =
      TextEditingController().obs;

  RxInt luggageAllowed = 1.obs;
  RxInt numberOfSheet = 1.obs;
  RxBool womenOnly = false.obs;
  RxBool onlyVerifiedPassenger = false.obs;
  RxBool twoPassengerMaxInBack = false.obs;
  RxList<int> selectedSeats = <int>[].obs;
  RxString driverPaymentMethod =
      "".obs; // New field for driver's payment preference

  Rx<DateTime> selectedDate = DateTime.now().obs;

  Rx<CityModel> pickUpLocation = CityModel().obs;
  Rx<CityModel> dropLocation = CityModel().obs;
  Rx<UserModel> userModel = UserModel().obs;

  @override
  void onInit() {
    getUserData();
    getVehicleInformation();
    super.onInit();
  }

  RxList<VehicleInformationModel> userVehicleList =
      <VehicleInformationModel>[].obs;
  Rx<VehicleInformationModel> selectedUserVehicle =
      VehicleInformationModel().obs;

  getVehicleInformation({String? selectedId}) async {
    await VehicleUtils.getUserVehicleInformation().then((value) {
      if (value != null) {
        userVehicleList.value = value;
        if (selectedId != null) {
          selectedUserVehicle.value = userVehicleList.firstWhere(
              (vehicleInformationModel) =>
                  vehicleInformationModel.id == selectedId);
          selectedVehicleController.value.text =
              "${selectedUserVehicle.value.vehicleBrand!.name} ${selectedUserVehicle.value.vehicleModel!.name} (${selectedUserVehicle.value.licensePlatNumber})";
        }
      }
    });
  }

  getUserData() async {
    await UserUtils.getUserProfile(AuthUtils.getCurrentUid()).then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });
  }

  var polylines = <google_map.Polyline>{}.obs;

  google_map.GoogleMapController? mapController;
  final RxList<Routes> routes = <Routes>[].obs;
  final RxInt selectedRouteIndex = (0).obs;

  void setMapController(google_map.GoogleMapController controller) {
    mapController = controller;
    fetchRoutes();
  }

  void fetchRoutes() async {
    // On web, skip the API call due to CORS restrictions
    if (kIsWeb) {
      print("Directions API not available on web due to CORS restrictions");
      // You would need to implement a server-side proxy or use Google Maps JavaScript API
      return;
    }

    try {
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${pickUpLocation.value.geometry!.location!.lat},${pickUpLocation.value.geometry!.location!.lng}&destination=${dropLocation.value.geometry!.location!.lat},${dropLocation.value.geometry!.location!.lng}&alternatives=true&key=${Constant.mapAPIKey}'));
      print("===>${response.request}");
      if (response.statusCode == 200) {
        print("======>");
        log(response.body);
        final data = json.decode(response.body);
        DirectionAPIModel directionAPIModel = DirectionAPIModel.fromJson(data);

        routes.clear();
        polylines.clear();
        routes.value = directionAPIModel.routes!;
        selectRoute(0);
        // for (int i = 0; i < directionAPIModel.routes!.length; i++) {
        //   Routes route = directionAPIModel.routes![i];
        //   final overviewPolyline = route.overviewPolyline!.points;
        //   final polylineCoordinates = Constant.decodePolyline(overviewPolyline!);
        //
        //   final polyline = google_map.Polyline(
        //     polylineId: google_map.PolylineId('route_$i'),
        //     color:  AppThemeData.grey400, // Highlight first route
        //     points: polylineCoordinates,
        //     width: 5,
        //   );
        //
        //   polylines.add(polyline);
        // }
      }
    } catch (e) {
      print('Error fetching routes: $e');
    }
  }

  void selectRoute(int index) {
    var newPolylines = <google_map.Polyline>{};
    // Add all non-selected routes first
    // Add all non-selected routes first
    // for (int i = 0; i < routes.length; i++) {
    //   if (i != index) {
    //     Routes route = routes[i];
    //     final overviewPolyline = route.overviewPolyline!.points;
    //     final polylineCoordinates = Constant.decodePolyline(overviewPolyline!);
    //     newPolylines.add(google_map.Polyline(
    //       polylineId: google_map.PolylineId('route_$i'),
    //       points: polylineCoordinates,
    //       color: Colors.grey,
    //       width: 5,
    //     ));
    //   }
    // }

    Routes route = routes[index];
    final overviewPolyline = route.overviewPolyline!.points;
    final polylineCoordinates = Constant.decodePolyline(overviewPolyline!);

    // Add the selected route last to ensure it's on top
    newPolylines.add(google_map.Polyline(
      polylineId: google_map.PolylineId('route_$index'),
      points: polylineCoordinates,
      color: Colors.blue,
      width: 5,
    ));

    // ignore: invalid_use_of_protected_member
    polylines.value = newPolylines;
    selectedRouteIndex.value = index;
  }

  RxList<CityModel> cityList = <CityModel>[].obs;
  RxList<CityModel> selectedCityList = <CityModel>[].obs;
  RxList<CityModel> filterSelectedCityList = <CityModel>[].obs;
  RxList<CityModel> allSelectedCityList = <CityModel>[].obs;

  Future<String?> getPopularCity(
      double lat1, double lng1, double lat2, double lng2) async {
    selectedCityList.clear();
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${(lat1 + lat2) / 2},${(lng1 + lng2) / 2}&radius=50000&type=locality&key=${Constant.mapAPIKey}');
    final response = await http.get(url);
    print("==========>");
    log(response.body);
    cityList.clear();
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      data['results'].forEach((v) {
        cityList.add(CityModel.fromJson(v));
      });
    } else {
      throw Exception('Failed to load cities');
    }
    return null;
  }

  final RxList<google_map.Polyline> wayPointPolyLines =
      <google_map.Polyline>[].obs;
  google_map.GoogleMapController? wayPointMapController;

  void setWayMapController(google_map.GoogleMapController controller) {
    wayPointMapController = controller;
  }

  RxInt distance = 0.obs;
  RxString estimatedTime = "".obs;

  RxList<StopOverModel> stopOverList = <StopOverModel>[].obs;

  wayPointFilter() async {
    allSelectedCityList.clear();
    filterSelectedCityList.clear();
    wayPointPolyLines.clear();
    stopOverList.clear();

    // On web, skip the API call due to CORS restrictions
    if (kIsWeb) {
      print(
          "Waypoint directions not available on web due to CORS restrictions");
      return;
    }

    try {
      final waypointsString = selectedCityList
          .map((point) =>
              '${point.geometry!.location!.lat},${point.geometry!.location!.lng}')
          .join('|');
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${pickUpLocation.value.geometry!.location!.lat},${pickUpLocation.value.geometry!.location!.lng}&destination=${dropLocation.value.geometry!.location!.lat},${dropLocation.value.geometry!.location!.lng}&alternatives=true&waypoints=optimize:true|$waypointsString&key=${Constant.mapAPIKey}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        DirectionAPIModel directionAPIModel = DirectionAPIModel.fromJson(data);

        Routes route = directionAPIModel.routes!.length == 1
            ? directionAPIModel.routes!.first
            : directionAPIModel.routes![selectedRouteIndex.value];
        for (var element in route.legs!) {
          String price = (double.parse(Constant.distanceCalculate(
                      element.distance!.value.toString())) *
                  double.parse(selectedUserVehicle
                      .value.vehicleType!.perKmCharges
                      .toString()))
              .toString();
          String recommendedPrice = (double.parse(Constant.distanceCalculate(
                      element.distance!.value.toString())) *
                  double.parse(selectedUserVehicle
                      .value.vehicleType!.perKmCharges
                      .toString()))
              .toString();
          stopOverList.add(StopOverModel(
              duration: element.duration,
              distance: element.distance,
              endAddress: element.endAddress,
              endLocation: element.endLocation,
              price: price,
              recommendedPrice: recommendedPrice,
              startAddress: element.startAddress,
              startLocation: element.startLocation));
        }
        final overviewPolyline = route.overviewPolyline!.points;
        final polylineCoordinates = Constant.decodePolyline(overviewPolyline!);
        final polyline = google_map.Polyline(
          polylineId: const google_map.PolylineId("0"),
          color: AppThemeData.primary300, // Highlight first route
          points: polylineCoordinates,
          width: 5,
        );

        wayPointPolyLines.add(polyline);
        for (int i = 0; i < selectedCityList.length; i++) {
          filterSelectedCityList.add(selectedCityList[directionAPIModel.routes!
              .first.waypointOrder![i]]); // 2 replace with waypoint order
        }
      }

      allSelectedCityList.add(pickUpLocation.value);
      allSelectedCityList.addAll(filterSelectedCityList);
      allSelectedCityList.add(dropLocation.value);
    } catch (e) {
      print('Error in wayPointFilter: $e');
    }
  }

  RxDouble price = 0.0.obs;
  RxDouble recommendedPrice = 0.0.obs;

  calculatePrice() {
    recommendedPrice.value = (double.parse(
            Constant.distanceCalculate(distance.value.toString())) *
        double.parse(
            selectedUserVehicle.value.vehicleType!.perKmCharges.toString()));
    price.value = (double.parse(
            Constant.distanceCalculate(distance.value.toString())) *
        double.parse(
            selectedUserVehicle.value.vehicleType!.perKmCharges.toString()));
  }

  changePriceVariant(bool isIncrement) {
    if (isIncrement) {
      price.value += 10.0;
    } else {
      if (price.value > 0) {
        price.value -= 10.0;
        if (price.value < 0) price.value = 0.0;
      }
    }
  }

  changeStopOverPrice(int index, bool isIncrement) {
    StopOverModel stopOverModel = stopOverList[index];
    double currentPrice =
        double.parse((stopOverModel.price ?? '0.0').toString());

    if (isIncrement) {
      stopOverModel.price = (currentPrice + 10.0).toString();
    } else {
      if (currentPrice > 0) {
        double newPrice = currentPrice - 10.0;
        stopOverModel.price = (newPrice < 0 ? 0.0 : newPrice).toString();
      }
    }
    stopOverList.removeAt(index);
    stopOverList.insert(index, stopOverModel);
    update();
  }

  publishRide() async {
    // Check wallet balance before publishing ride
    double walletBalance =
        double.tryParse(userModel.value.walletAmount ?? "0.0") ?? 0.0;
    const double minAllowedBalance = -500.0;

    if (walletBalance < minAllowedBalance) {
      _showWalletTopUpDialog();
      return;
    }

    BookingModel bookingModel = BookingModel();
    bookingModel.id = Constant.getUuid();
    bookingModel.createdBy = AuthUtils.getCurrentUid();
    bookingModel.totalSeat = numberOfSheet.value.toString();
    bookingModel.pricePerSeat = price.value.toString();
    bookingModel.pickUpAddress = pickUpLocationController.value.text;
    bookingModel.dropAddress = dropLocationController.value.text;
    bookingModel.pickupLocation = pickUpLocation.value;
    bookingModel.dropLocation = dropLocation.value;
    bookingModel.stopOver = filterSelectedCityList;
    bookingModel.vehicleInformation = selectedUserVehicle.value;
    bookingModel.departureDateTime = Timestamp.fromDate(selectedDate.value);
    bookingModel.distance = distance.value.toString();
    bookingModel.estimatedTime = estimatedTime.value;
    bookingModel.createdAt = Timestamp.now();
    bookingModel.twoPassengerMaxInBack = twoPassengerMaxInBack.value;
    bookingModel.womenOnly = womenOnly.value;
    bookingModel.onlyVerifiedPassenger = onlyVerifiedPassenger.value;
    bookingModel.luggageAllowed = luggageAllowed.value.toString();
    bookingModel.additionalRequirements =
        additionalRequirementsController.value.text.trim().isEmpty
            ? null
            : additionalRequirementsController.value.text.trim();
    bookingModel.stopOverList = stopOverList;
    bookingModel.status = Constant.placed;
    bookingModel.travelPreference = userModel.value.travelPreference;
    bookingModel.driverVerify = (userModel.value.aadharVerified == true) &&
        (userModel.value.panVerified == true);
    bookingModel.publish = true;
    bookingModel.driverPaymentMethod =
        driverPaymentMethod.value; // Set driver's payment preference
    // Add selected seats information
    bookingModel.selectedSeats =
        selectedSeats.map((seat) => seat.toString()).toList();

    await BookingUtils.setBooking(bookingModel).then((value) async {
      // Send WhatsApp notification to driver about ride published
      if (userModel.value.phoneNumber != null &&
          userModel.value.phoneNumber!.isNotEmpty) {
        await WhatsAppService.sendDriverRidePublished(
            phoneNumber: userModel.value.phoneNumber!,
            rideDetails: [
              {
                "type": "body",
                "parameters": [
                  {"type": "text", "text": bookingModel.pickUpAddress ?? ''},
                  {"type": "text", "text": bookingModel.dropAddress ?? ''},
                  {
                    "type": "text",
                    "text": Constant.dateCustomizationShow(
                            bookingModel.departureDateTime!.toDate()) ??
                        ''
                  },
                  {
                    "type": "text",
                    "text": DateFormat('hh:mm aa')
                            .format(bookingModel.departureDateTime!.toDate()) ??
                        ''
                  },
                ]
              }
            ]);
      }
      print(
          'whatsapp message sent successfully to ${userModel.value.phoneNumber}');

      // Send push notification to ride publisher
      String? publisherFcmToken = userModel.value.fcmToken;
      if (publisherFcmToken != null && publisherFcmToken.isNotEmpty) {
        String formattedDate = Constant.dateCustomizationShow(
            bookingModel.departureDateTime!.toDate());
        String formattedTime = DateFormat('hh:mm aa')
            .format(bookingModel.departureDateTime!.toDate());

        String notificationTitle = '🚗 Ride Published Successfully! 🎉';
        String notificationBody =
            '📍 ${bookingModel.pickUpAddress} ➡️ ${bookingModel.dropAddress}\n'
            '📅 $formattedDate at 🕐 $formattedTime\n\n'
            '✨ We will update you once someone books any seats! 🙌';

        Map<String, dynamic> notificationData = {
          'type': 'ride_published',
          'bookingId': bookingModel.id ?? '',
          'pickUpAddress': bookingModel.pickUpAddress ?? '',
          'dropAddress': bookingModel.dropAddress ?? '',
          'departureTime':
              bookingModel.departureDateTime?.toDate().toIso8601String() ?? '',
        };

        await _sendFCMMessage(
          publisherFcmToken,
          notificationTitle,
          notificationBody,
          notificationData,
        );
        await _sendFCMMessage(
          publisherFcmToken,
          notificationTitle,
          notificationBody,
          notificationData,
        );
        print('📤 Ride published notification sent to driver');
      }

      // Schedule local reminder for driver (30 mins before ride)
      if (bookingModel.departureDateTime != null) {
        DateTime rideTime = bookingModel.departureDateTime!.toDate();
        DateTime scheduleTime = rideTime.subtract(const Duration(minutes: 30));

        // Generate a unique ID for notification based on booking ID hash
        int notificationId = bookingModel.id.hashCode;

        await NotificationService.scheduleNotification(
          id: notificationId,
          title: '🚗 Ride Starting Soon!',
          body: 'You are about to start the trip from '
              '${bookingModel.pickUpAddress} to ${bookingModel.dropAddress} at '
              '${DateFormat('hh:mm a').format(rideTime)}.\n\n'
              'Please be ready and contact the rider 📞.\n\n'
              'Please remember the following points while riding:\n\n'
              '1. 👉 Press the Start button before riding and ask the rider to share the OTP before boarding to verify the passenger.\n'
              '2. 📍 Always keep your mobile location ON during the trip.\n'
              '3. 🆘 Make sure your SOS number is updated in the app and use it in case of any emergency.\n'
              '4. ⭐ After completing the trip, press the Complete button and leave a review for the rider. Also, please share a review for the app on the Google Play Store.\n\n'
              'Happy journey 🛣️\n'
              'Bola – let’s move together 🤝',
          scheduledTime: scheduleTime,
        );
      }

      // Send FCM notifications to users with matching ride alerts
      _sendRideAlertNotifications(bookingModel);

      final dashboardController = Get.put(DashboardScreenController());
      Get.offAll(
        const DashBoardScreen(),
        arguments: {
          'goToMyRidePublished': true,
          'publishedRideId': bookingModel.id,
        },
      );
      // Switch to MyRide tab after navigation
      Future.delayed(const Duration(milliseconds: 100), () {
        dashboardController.selectedIndex.value = 1;
      });
    });
  }

  void _showWalletTopUpDialog() {
    String currentBalance =
        Constant.amountShow(amount: userModel.value.walletAmount ?? "0.0");
    // String minBalance = Constant.amountShow(amount: "-500.0");

    Get.dialog(
      AlertDialog(
        title: Text("Wallet Balance Low".tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your current wallet balance is $currentBalance",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              "You need to top up the wallet to make it zero before publishing any ride.",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text("Cancel".tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.to(
                const WalletScreen(),
                arguments: {"type": "wallet"},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.primary300,
            ),
            child: Text(
              "Top up Wallet".tr,
              style: const TextStyle(color: AppThemeData.grey50),
            ),
          ),
        ],
      ),
    );
  }

  var newPublishRideActive = <BookingModel>[].obs;
  var OldPublishRideActive = <BookingModel>[].obs;

  Future<List<BookingModel>> checkPublishRideBetweenIntervalTime() async {
    return await BookingUtils.checkAtivePublishes() ?? <BookingModel>[];
  }

  Future<Duration> getDuration(
      {required Location startLocation, required Location endLocation}) async {
    // On web, return a default duration due to CORS restrictions
    if (kIsWeb) {
      print(
          "Duration calculation not available on web due to CORS restrictions");
      return Duration(minutes: 30); // Default estimate
    }

    try {
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${startLocation.lat},${startLocation.lng}&destination=${endLocation.lat},${endLocation.lng}&alternatives=true&key=${Constant.mapAPIKey}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        DirectionAPIModel directionAPIModel = DirectionAPIModel.fromJson(data);

        if (directionAPIModel.routes != null &&
            directionAPIModel.routes!.isNotEmpty) {
          Routes route = directionAPIModel.routes!.first;
          int? durationInSeconds = route.legs!.first.duration?.value;

          if (durationInSeconds != null) {
            Duration duration = Duration(seconds: durationInSeconds);
            return duration;
          } else {
            print("Duration data not found in the response");
            return Duration();
          }
        } else {
          print("No routes found in the response");
          return Duration();
        }
      } else {
        print("Failed to fetch data. Status code: ${response.statusCode}");
        return Duration();
      }
    } catch (e) {
      print('Error getting duration: $e');
      return Duration();
    }
  }

  /// Send FCM notifications to users with matching ride alerts
  Future<void> _sendRideAlertNotifications(BookingModel booking) async {
    try {
      print('🔔 Checking for matching ride alerts...');

      // Get the departure date from the booking
      if (booking.departureDateTime == null) {
        print('⚠️ Booking has no departure date');
        return;
      }

      DateTime bookingDate = booking.departureDateTime!.toDate();
      print('📅 Booking departure: $bookingDate');
      print('📍 Route: ${booking.pickUpAddress} → ${booking.dropAddress}');

      // Get matching alerts from Firestore
      List<RideAlertModel> matchingAlerts =
          await RideAlertUtils.getMatchingRideAlerts(booking);

      print('✅ Found ${matchingAlerts.length} matching alerts');

      // Send notification to each user with matching alert
      for (var alert in matchingAlerts) {
        // Skip if the user is the one who published the ride
        if (alert.userId == booking.createdBy) {
          print('⏭️ Skipping alert for ride publisher');
          continue;
        }

        String title =
            '🚗 Ride: ${booking.pickUpAddress} → ${booking.dropAddress}';
        String message =
            'A new ride matching your search is now available! Departure: ${Constant.dateCustomizationShow(booking.departureDateTime!.toDate())}';

        // Replace placeholders in the message
        message = message
            .replaceAll(
                '{pickup}', alert.pickUpAddress ?? 'your pickup location')
            .replaceAll('{drop}', alert.dropAddress ?? 'your drop location')
            .replaceAll(
                '{date}',
                Constant.dateCustomizationShow(
                    booking.departureDateTime!.toDate()));

        // Prepare notification payload
        Map<String, dynamic> data = {
          'type': 'ride_alert',
          'title': title,
          'message': message,
          'bookingId': booking.id ?? '',
          'alertId': alert.id ?? '',
          'pickUpAddress': booking.pickUpAddress ?? '',
          'dropAddress': booking.dropAddress ?? '',
          'departureTime':
              booking.departureDateTime?.toDate().toIso8601String() ?? '',
        };

        // Get user's FCM token from their profile
        UserModel? alertUser =
            await UserUtils.getUserProfile(alert.userId ?? '');
        String? fcmToken = alertUser?.fcmToken;

        // Send FCM notification
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _sendFCMMessage(fcmToken, title, message, data);
          print('📤 Notification sent to user: ${alert.userId}');
        } else {
          print('⚠️ No FCM token for user: ${alert.userId}');
        }
      }
    } catch (e) {
      print('❌ Error sending ride alert notifications: $e');
    }
  }

  /// Send FCM notification directly with custom title/body
  Future<void> _sendFCMMessage(
    String fcmToken,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      final String accessToken = await SendNotification.getAccessToken();
      if (accessToken.isEmpty) {
        print('❌ Failed to get FCM access token');
        return;
      }

      String projectId = Constant.senderId.isNotEmpty
          ? Constant.senderId
          : DefaultFirebaseOptions.currentPlatform.projectId;

      final notificationPayload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'body': body,
            'title': title,
          },
          'data': data,
          'android': {
            'notification': {
              'channel_id': 'ride_alert_channel',
              'sound': 'default',
              'icon': 'ic_notification',
              'color': '#FF6B00',
            },
            'priority': 'HIGH',
          },
          'apns': {
            'headers': {
              'apns-push-type': 'alert',
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'alert': {
                  'title': title,
                  'body': body,
                },
                'sound': 'default',
              },
            },
          },
        }
      };

      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(notificationPayload),
      );

      if (response.statusCode == 200) {
        print('✅ FCM sent successfully');
      } else {
        print('❌ FCM failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending FCM: $e');
    }
  }
}
