import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/chat/inbox_screen.dart';
import 'package:poolmate/app/home_screen/home_screen.dart';
import 'package:poolmate/app/myride/myride_screen.dart';
import 'package:poolmate/app/on_boarding_screen/get_started_screen.dart';
import 'package:poolmate/app/profile_screen/profile_screen.dart';
import 'package:poolmate/app/wallet_screen/wallet_screen.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/fire_store_utils.dart';

class DashboardScreenController extends GetxController {
  RxInt selectedIndex = 0.obs;

  RxList pageList = [
    const HomeScreen(),
    const MyRideScreen(),
    const WalletScreen(),
    const InboxScreen(),
    const ProfileScreen(),
  ].obs;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  RxString count = "0".obs;
  Rx<UserModel> senderUserModel = UserModel().obs;

  getData() async {
    final currentUid = FireStoreUtils.getCurrentUid();
    // Don't update FCM token on dashboard load - only during login/signup
    if (currentUid.isEmpty) {
      // No user logged in, redirect to get started screen
      Get.offAll(const GetStartedScreen());
      return;
    }

    FireStoreUtils.fireStore
        .collection(CollectionName.users)
        .doc(currentUid)
        .snapshots()
        .listen(
      (event) async {
        if (event.exists) {
          senderUserModel.value = UserModel.fromJson(event.data()!);
          if (senderUserModel.value.isActive == false) {
            // Clear local user ID
            await FireStoreUtils.clearCurrentUid();
            // Sign out from Firebase if signed in
            if (FirebaseAuth.instance.currentUser != null) {
              await FirebaseAuth.instance.signOut();
            }
            Get.offAll(const GetStartedScreen());
          }
        }
      },
    );

    FireStoreUtils.fireStore
        .collection(CollectionName.chat)
        .doc(currentUid)
        .collection("inbox")
        .where("seen", isEqualTo: false)
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen(
      (event) {
        count.value = event.docs.length.toString();
      },
      onError: (e) {
        count.value = "0";
      },
    );
  }
}
