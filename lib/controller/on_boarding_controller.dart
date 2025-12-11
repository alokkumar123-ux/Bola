import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/model/on_boarding_model.dart';
import 'package:poolmate/utils/fire_store_utils.dart';

class OnBoardingController extends GetxController {
  var selectedPageIndex = 0.obs;

  bool get isLastPage => selectedPageIndex.value == onBoardingList.length - 1;
  var pageController = PageController();

  @override
  void onInit() {
    getOnBoardingData();
    super.onInit();
  }

  RxBool isLoading = true.obs;
  RxList<OnBoardingModel> onBoardingList = <OnBoardingModel>[].obs;

  getOnBoardingData() async {
    try {
      final value = await FireStoreUtils.getOnBoardingList();
      if (value.isNotEmpty) {
        onBoardingList.assignAll(value);
      } else {
        onBoardingList.assignAll(_defaultSlides);
      }
    } catch (e) {
      onBoardingList.assignAll(_defaultSlides);
    } finally {
    isLoading.value = false;
    update();
  }
  }

  List<OnBoardingModel> get _defaultSlides => [
        OnBoardingModel(
          title: "Welcome to JourneyMate",
          description: "Your Trusted Companion for Hassle-Free Travel",
          id: "slide_1",
          image: "assets/images/onboarding_1.png",
        ),
        OnBoardingModel(
          title: "Discover Ride sharing",
          description: "Find or Offer Rides to Your Destination",
          id: "slide_2",
          image: "assets/images/onboarding_2.png",
        ),
        OnBoardingModel(
          title: "Connect with Fellow Travelers",
          description: "Share Your Journey, Share the Fun",
          id: "slide_3",
          image: "assets/images/onboarding_3.png",
        ),
      ];
}
