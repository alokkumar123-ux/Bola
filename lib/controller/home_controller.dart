import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:poolmate/app/home_screen/search_screen.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/map/direction_api_model.dart';
import 'package:poolmate/model/map/geometry.dart';
import 'package:poolmate/model/recent_search_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/fire_store_utils.dart';
import 'package:http/http.dart' as http;

class HomeController extends GetxController {
  // Seat Management
  RxList<String> selectedSeatsNumbers = <String>[].obs;
  RxInt numberOfSelectedSeats = 1.obs;

  // Text Controllers
  Rx<TextEditingController> pickUpLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> dropLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> personController =
      TextEditingController(text: "1").obs;
  Rx<TextEditingController> dateController = TextEditingController().obs;

  RxInt numberOfSheet = 1.obs;

  Rx<DateTime> selectedDate = DateTime.now().obs;

  Rx<Location> pickUpLocation = Location().obs;
  Rx<Location> dropLocation = Location().obs;

  RxList<RecentSearchModel> recentSearch = <RecentSearchModel>[].obs;

  RxBool isLoading = true.obs;
  Rx<UserModel> userModel = UserModel().obs;

  @override
  void onInit() {
    dateController.value.text =
        Constant.dateCustomizationShow(selectedDate.value).toString();
    selectedSeatsNumbers.clear();
    numberOfSelectedSeats.value = 1;
    getAdvertisement();
    getSearchHistory();
    addDepartureTime();
    // Reset search state
    searchedBookingList.clear();
    selectedDepartureTime.clear();
    verifyDriver.value = false;
    isWoman.value = false;
    super.onInit();
  }

  getSearchHistory() async {
    await FireStoreUtils.getSearchHistory().then((value) {
      if (value != null) {
        recentSearch.value = value;
      }
    });
    isLoading.value = false;
  }

  RxList<BookingModel> searchedBookingList = <BookingModel>[].obs;

  searchRide() async {
    try {
      ShowToastDialog.showLoader("Please wait");
      searchedBookingList.clear();
      selectedDepartureTime.clear();
      verifyDriver.value = false;
      isWoman.value = false;
      selectedSeatsNumbers.clear();

      // Get current user's details for filtering
      UserModel? currentUser =
          await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());

      // Only use geocoding on non-web platforms
      if (!kIsWeb && pickUpLocation.value.lat != null) {
        try {
          List<geocoding.Placemark> placeMarks =
              await geocoding.placemarkFromCoordinates(
                  pickUpLocation.value.lat!, pickUpLocation.value.lng!);
          if (placeMarks.isNotEmpty && placeMarks.first.country != null) {
            Constant.country = placeMarks.first.country;
          }
        } catch (e) {
          print('Geocoding error: $e');
          // Continue without country code on web or if geocoding fails
        }
      }

      await FireStoreUtils().getTaxList().then((value) {
        if (value != null) {
          Constant.taxList = value;
        }
      });
      Timestamp startTime;
      if (Constant.dateCustomizationShow(selectedDate.value) == "Today") {
        startTime = Timestamp.fromDate(DateTime.now());
      } else {
        startTime = Timestamp.fromDate(DateTime(selectedDate.value.year,
            selectedDate.value.month, selectedDate.value.day, 0, 0, 0));
      }
      Timestamp endTime = Timestamp.fromDate(DateTime(selectedDate.value.year,
          selectedDate.value.month, selectedDate.value.day, 23, 59, 0));
      await FireStoreUtils.fireStore
          .collection(CollectionName.booking)
          .where('departureDateTime', isGreaterThanOrEqualTo: startTime)
          .where('departureDateTime', isLessThanOrEqualTo: endTime)
          .where('status', isEqualTo: Constant.placed)
          .where('publish', isEqualTo: true)
          .where('createdBy', isNotEqualTo: FireStoreUtils.getCurrentUid())
          .get()
          .then((value) {
        for (var element in value.docs) {
          BookingModel bookingModel = BookingModel.fromJson(element.data());
          bool isPickupSame = pickupIsSame(bookingModel);

          if (isPickupSame) {
            // Calculate available seats
            int totalSeats = int.tryParse(bookingModel.totalSeat ?? '0') ?? 0;
            int bookedSeatsCount = 0;

            if (bookingModel.seatBookings != null) {
              bookedSeatsCount = bookingModel.seatBookings!
                  .where((seat) => seat.isBooked == true)
                  .length;
            }

            // Add to search results if seats are available
            if ((totalSeats - bookedSeatsCount) > 0) {
              // Apply additional filtering based on ride requirements
              bool canViewRide =
                  _canUserViewRideSync(bookingModel, currentUser);
              if (canViewRide) {
                searchedBookingList.add(bookingModel);
              }
            }
          }
        }
      });

      ShowToastDialog.closeLoader();
      Get.to(const SearchScreen())?.then((v) async {
        await getSearchHistory();
      });
    } catch (e) {
      print('Error in searchRide: $e');
      ShowToastDialog.closeLoader();
      Get.to(const SearchScreen())?.then((v) async {
        await getSearchHistory();
      });
    }
  }

  bool pickupIsSame(BookingModel bookingModel) {
    bool isPickUp = false;
    bool isDropOff = false;

    for (var element in bookingModel.stopOverList!) {
      double distancePickup = Constant.calculateDistance(
          Location(
              lat: element.startLocation!.lat, lng: element.startLocation!.lng),
          pickUpLocation.value);
      double distanceDrop = Constant.calculateDistance(
          Location(
              lat: element.endLocation!.lat, lng: element.endLocation!.lng),
          dropLocation.value);

      if (distancePickup <= int.parse(Constant.radius)) {
        isPickUp = true;
      }
      if (distanceDrop <= int.parse(Constant.radius)) {
        isDropOff = true;
      }

      if (isPickUp) {
        if (isDropOff) {
          return true;
        }
      }

      if (isDropOff) {
        if (!isPickUp) {
          return false;
        }
      }
    }

    return false;
  }

  Future<StopOverModel?> getPrice(BookingModel bookingModel) async {
    StopOverModel stopOverModel = StopOverModel();
    List<LocationDistance> pickUpDistanceData = [];
    List<LocationDistance> dropUpDistanceData = [];
    for (var element in bookingModel.stopOverList!) {
      double distancePickup = Constant.calculateDistance(
          Location(
              lat: element.startLocation!.lat, lng: element.startLocation!.lng),
          pickUpLocation.value);
      double distanceDrop = Constant.calculateDistance(
          Location(
              lat: element.endLocation!.lat, lng: element.endLocation!.lng),
          dropLocation.value);
      log("DistanceData :: pickUp :: ${element.startAddress} :: $distancePickup");
      log("DistanceData :: droff ::${element.endAddress} :: $distanceDrop");
      pickUpDistanceData.add(LocationDistance(
          radius: distancePickup,
          location: LatLng(element.startLocation?.lat ?? 0.0,
              element.startLocation?.lng ?? 0.0)));
      dropUpDistanceData.add(LocationDistance(
          radius: distanceDrop,
          location: LatLng(element.endLocation?.lat ?? 0.0,
              element.endLocation?.lng ?? 0.0)));
    }
    pickUpDistanceData.sort((pickUpDistanceItem1, pickUpDistanceItem2) =>
        pickUpDistanceItem1.radius.compareTo(pickUpDistanceItem2.radius));
    dropUpDistanceData.sort((dropUpDistanceData1, dropUpDistanceData2) =>
        dropUpDistanceData1.radius.compareTo(dropUpDistanceData2.radius));

    stopOverModel.startLocation = (Northeast(
        lat: pickUpDistanceData.first.location.latitude,
        lng: pickUpDistanceData.first.location.longitude));
    stopOverModel.endLocation = (Northeast(
        lat: dropUpDistanceData.first.location.latitude,
        lng: dropUpDistanceData.first.location.longitude));
    stopOverModel.startAddress = pickUpLocationController.value.text;
    stopOverModel.endAddress = dropLocationController.value.text;

    return await getStopOverData(
        bookingModel: bookingModel, stopOverModel: stopOverModel);
  }

  setSearchHistory({String? serachHistoryId}) async {
    RecentSearchModel recentSearchModel = RecentSearchModel();
    recentSearchModel.pickUpAddress = pickUpLocationController.value.text;
    recentSearchModel.dropAddress = dropLocationController.value.text;
    recentSearchModel.pickUpLocation = pickUpLocation.value;
    recentSearchModel.dropLocation = dropLocation.value;
    recentSearchModel.person = personController.value.text;
    recentSearchModel.bookedDate = Timestamp.fromDate(selectedDate.value);
    recentSearchModel.userId = FireStoreUtils.getCurrentUid();
    recentSearchModel.createdAt = Timestamp.now();
    if (serachHistoryId != null) {
      recentSearchModel.id = serachHistoryId;
    } else {
      recentSearchModel.id = Constant.getUuid();
    }
    await FireStoreUtils.setSearchHistory(recentSearchModel);
  }

  setSearchDatatoFields(
      {required RecentSearchModel recentSearchModel,
      required DateTime? date}) async {
    pickUpLocationController.value.text = recentSearchModel.pickUpAddress ?? '';
    dropLocationController.value.text = recentSearchModel.dropAddress ?? '';
    pickUpLocation.value =
        recentSearchModel.pickUpLocation ?? Location(lat: 0.0, lng: 0.0);
    dropLocation.value =
        recentSearchModel.dropLocation ?? Location(lat: 0.0, lng: 0.0);
    personController.value.text = recentSearchModel.person ?? '0';
    if (date != null) {
      selectedDate.value = date;
      dateController.value.text = Constant.dateCustomizationShow(date);
    } else {
      dateController.value.text = recentSearchModel.bookedDate != null
          ? Constant.dateCustomizationShow(
              recentSearchModel.bookedDate!.toDate())
          : Constant.dateCustomizationShow(DateTime.now());
    }
    setSearchHistory(serachHistoryId: recentSearchModel.id);
    await searchRide();
  }

  RxList<TimeSlot> departureTime = <TimeSlot>[].obs;
  RxList<TimeSlot> selectedDepartureTime = <TimeSlot>[].obs;
  RxBool verifyDriver = false.obs;
  RxBool isWoman = false.obs;

  Rx<RangeValues> currentRangeValues = const RangeValues(1, 10000).obs;
  Rx<TextEditingController> minPriceController =
      TextEditingController(text: "1").obs;
  Rx<TextEditingController> maxPriceController =
      TextEditingController(text: "10000").obs;

  addDepartureTime() {
    departureTime.add(TimeSlot(
        title: "Select All",
        start: DateTime(selectedDate.value.year, selectedDate.value.month,
            selectedDate.value.day, 0, 0, 0),
        end: DateTime(selectedDate.value.year, selectedDate.value.month,
            selectedDate.value.day, 23, 59, 0)));
    departureTime.add(TimeSlot(
        title: "Before 6:00 AM",
        start: DateTime(selectedDate.value.year, selectedDate.value.month,
            selectedDate.value.day, 0, 0, 0),
        end: DateTime(selectedDate.value.year, selectedDate.value.month,
            selectedDate.value.day, 06, 00, 0)));
    departureTime.add(TimeSlot(
        title: "06:00 AM - 12:00 noon",
        start: DateTime(selectedDate.value.year, selectedDate.value.month,
            selectedDate.value.day, 06, 00, 00),
        end: DateTime(selectedDate.value.year, selectedDate.value.month,
            selectedDate.value.day, 11, 59, 00)));
    departureTime.add(TimeSlot(
        title: "12:00 noon - 06:00 PM",
        start: DateTime(selectedDate.value.year, selectedDate.value.month,
            selectedDate.value.day, 12, 01, 00),
        end: DateTime(selectedDate.value.year, selectedDate.value.month,
            selectedDate.value.day, 18, 00, 00)));
    departureTime.add(TimeSlot(
        title: "after 06:00 PM",
        start: DateTime(selectedDate.value.year, selectedDate.value.month,
            selectedDate.value.day, 18, 00, 00),
        end: DateTime(selectedDate.value.year, selectedDate.value.month,
            selectedDate.value.day, 23, 59, 00)));
  }

  filterBookings({
    List<TimeSlot>? timeSlots,
    bool? verifyDrivers,
    bool? womenOnly,
    double? minPrice,
    double? maxPrice,
  }) async {
    print("===> ${searchedBookingList.length}");
    // Apply filters to existing results without reloading
    if (searchedBookingList.isEmpty) {
      await searchRide();
    }
    List<BookingModel> filterList = searchedBookingList.where((booking) {
      bool matches = true;

      // Filter by multiple time slots
      if (timeSlots != null && timeSlots.isNotEmpty) {
        bool withinTimeSlot = false;
        for (var slot in timeSlots) {
          if (booking.departureDateTime != null &&
              booking.departureDateTime!.toDate().isAfter(slot.start) &&
              booking.departureDateTime!.toDate().isBefore(slot.end)) {
            withinTimeSlot = true;
            break;
          }
        }
        if (!withinTimeSlot) {
          matches = false;
        }
      }

      // Verify drivers (assuming createdBy is not null or meets some criteria)
      if (verifyDrivers != null && verifyDrivers) {
        if (booking.driverVerify != true) {
          matches = false;
        }
      }

      // Filter by women only
      if (womenOnly != null && womenOnly) {
        if (booking.womenOnly != true) {
          matches = false;
        }
      }

      // Filter by price range
      if (minPrice != null || maxPrice != null) {
        double price = double.tryParse(booking.pricePerSeat ?? '0') ?? 0;
        if ((minPrice != null && price < minPrice) ||
            (maxPrice != null && price > maxPrice)) {
          matches = false;
        }
      }
      return matches;
    }).toList();
    searchedBookingList.value = filterList;
    Get.back();
  }

  RxList<String> bannerList = <String>[].obs;

  getAdvertisement() async {
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      userModel.value = value!;
    });

    await FireStoreUtils.getAdvertiseBannersData().then((modelList) {
      bannerList.value = modelList;
    });
  }

  Future<StopOverModel?> getStopOverData(
      {required BookingModel bookingModel,
      required StopOverModel stopOverModel}) async {
    // On web, skip the API call due to CORS restrictions
    // Return the stopOverModel with existing data or calculate estimated values
    if (kIsWeb) {
      // For web, we can't use the Directions API directly
      // You could either:
      // 1. Use a proxy server
      // 2. Calculate straight-line distance as estimate
      // 3. Return existing data from the booking

      // For now, return the stopOverModel as-is with a basic calculation
      // or use existing data from the booking
      return stopOverModel;
    }

    try {
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${stopOverModel.startLocation?.lat},${stopOverModel.startLocation?.lng}&destination=${stopOverModel.endLocation?.lat},${stopOverModel.endLocation?.lng}&alternatives=true&key=${Constant.mapAPIKey}'));
      print("===>${response.request}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        DirectionAPIModel directionAPIModel = DirectionAPIModel.fromJson(data);
        Routes route = directionAPIModel.routes!.first;
        String price = (double.parse(Constant.distanceCalculate(
                    route.legs![0].distance!.value.toString())) *
                double.parse(bookingModel
                        .vehicleInformation?.vehicleType?.perKmCharges ??
                    '0'))
            .toString();
        String recommendedPrice = (double.parse(Constant.distanceCalculate(
                    route.legs![0].distance!.value.toString())) *
                double.parse(bookingModel
                        .vehicleInformation?.vehicleType?.perKmCharges ??
                    '0'))
            .toString();
        stopOverModel.distance = route.legs!.first.distance;
        stopOverModel.duration = route.legs!.first.duration;
        stopOverModel.price = price;
        stopOverModel.recommendedPrice = recommendedPrice;
        return stopOverModel;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching directions: $e');
      // On error, return stopOverModel with existing data
      return stopOverModel;
    }
  }

  // Helper method to get the correct price for a stopOverModel
  // Checks if it's a full route or matches a preset stopover
  double getCorrectPrice(
      BookingModel bookingModel, StopOverModel stopOverModel) {
    // First check if it's a full route
    final bookingPickupLat =
        bookingModel.pickupLocation?.geometry?.location?.lat;
    final bookingPickupLng =
        bookingModel.pickupLocation?.geometry?.location?.lng;
    final bookingDropLat = bookingModel.dropLocation?.geometry?.location?.lat;
    final bookingDropLng = bookingModel.dropLocation?.geometry?.location?.lng;

    final stopOverStartLat = stopOverModel.startLocation?.lat;
    final stopOverStartLng = stopOverModel.startLocation?.lng;
    final stopOverEndLat = stopOverModel.endLocation?.lat;
    final stopOverEndLng = stopOverModel.endLocation?.lng;

    if (bookingPickupLat != null &&
        bookingPickupLng != null &&
        bookingDropLat != null &&
        bookingDropLng != null &&
        stopOverStartLat != null &&
        stopOverStartLng != null &&
        stopOverEndLat != null &&
        stopOverEndLng != null) {
      // Check if it's a full route (start and end match booking's pickup and drop)
      bool startMatches = (bookingPickupLat - stopOverStartLat).abs() < 0.001 &&
          (bookingPickupLng - stopOverStartLng).abs() < 0.001;
      bool endMatches = (bookingDropLat - stopOverEndLat).abs() < 0.001 &&
          (bookingDropLng - stopOverEndLng).abs() < 0.001;

      if (startMatches && endMatches) {
        // It's a full route, use bookingModel.pricePerSeat
        return double.tryParse(bookingModel.pricePerSeat ?? '0') ?? 0.0;
      }

      // Check if this matches any preset stopover in stopOverList
      final stopOverList = bookingModel.stopOverList;
      if (stopOverList != null && stopOverList.isNotEmpty) {
        for (var presetStopOver in stopOverList) {
          final presetStartLat = presetStopOver.startLocation?.lat;
          final presetStartLng = presetStopOver.startLocation?.lng;
          final presetEndLat = presetStopOver.endLocation?.lat;
          final presetEndLng = presetStopOver.endLocation?.lng;

          if (presetStartLat != null &&
              presetStartLng != null &&
              presetEndLat != null &&
              presetEndLng != null) {
            // Check if locations match (within small tolerance)
            bool presetStartMatches =
                (presetStartLat - stopOverStartLat).abs() < 0.001 &&
                    (presetStartLng - stopOverStartLng).abs() < 0.001;
            bool presetEndMatches =
                (presetEndLat - stopOverEndLat).abs() < 0.001 &&
                    (presetEndLng - stopOverEndLng).abs() < 0.001;

            if (presetStartMatches && presetEndMatches) {
              // Found matching preset stopover, use its price (not recommendedPrice)
              return double.tryParse(presetStopOver.price ?? '0') ?? 0.0;
            }
          }
        }
      }
    }

    // No matching preset found, use the calculated stopOverModel price
    return double.tryParse(stopOverModel.price ?? '0') ?? 0.0;
  }

  @override
  void dispose() {
    // Clear all state when disposing
    searchedBookingList.clear();
    selectedDepartureTime.clear();
    verifyDriver.value = false;
    isWoman.value = false;
    pickUpLocationController.value.dispose();
    dropLocationController.value.dispose();
    personController.value.dispose();
    dateController.value.dispose();
    super.dispose();
  }

  // Check if the current user can view a ride based on basic requirements
  bool _canUserViewRideSync(BookingModel bookingModel, UserModel? currentUser) {
    try {
      if (currentUser == null) {
        return false; // If user not found, deny access
      }

      // NOTE: Removed verification check from here - unverified users can now see rides
      // The verification check will be done at booking time with a dialog prompt

      // Check women only requirement (existing logic)
      if (bookingModel.womenOnly == true) {
        // If ride is women only, check if current user is female
        if (currentUser.gender?.toLowerCase() != 'female' &&
            currentUser.gender?.toLowerCase() != 'woman') {
          return false; // User is not female, cannot see this ride
        }
      }

      return true; // User can view this ride
    } catch (e) {
      print('Error checking user ride access: $e');
      return false; // On error, deny access
    }
  }

  // Check if user can book a ride (to be called before booking)
  bool canUserBookRide(BookingModel bookingModel, UserModel? currentUser) {
    try {
      if (currentUser == null) {
        return false;
      }

      // Check if ride requires only verified passengers
      if (bookingModel.onlyVerifiedPassenger == true) {
        if (currentUser.aadharVerified != true) {
          return false; // User is not verified, cannot book
        }
      }

      // Check women only requirement
      if (bookingModel.womenOnly == true) {
        if (currentUser.gender?.toLowerCase() != 'female' &&
            currentUser.gender?.toLowerCase() != 'woman') {
          return false; // User is not female, cannot book
        }
      }

      return true; // User can book this ride
    } catch (e) {
      print('Error checking user booking access: $e');
      return false;
    }
  }
}

class TimeSlot {
  String title;
  DateTime start;
  DateTime end;

  TimeSlot({required this.title, required this.start, required this.end});
}

class LocationDistance {
  double radius;
  LatLng location;

  LocationDistance({required this.radius, required this.location});
}
