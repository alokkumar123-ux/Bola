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
import 'package:poolmate/utils/notification_service.dart';

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
    String token = await NotificationService.getToken();
    FireStoreUtils.fireStore.collection(CollectionName.users).doc(FireStoreUtils.getCurrentUid()).snapshots().listen(
      (event) async {
        if (event.exists) {
          senderUserModel.value = UserModel.fromJson(event.data()!);
          if (senderUserModel.value.isActive == false) {
            await FirebaseAuth.instance.signOut();
            Get.offAll(const GetStartedScreen());
          }
          senderUserModel.value.fcmToken = token;
          await FireStoreUtils.updateUser(senderUserModel.value);
        }
      },
    );


    FireStoreUtils.fireStore
        .collection(CollectionName.chat)
        .doc(senderUserModel.value.id)
        .collection("inbox")
        .where("seen", isEqualTo: false)
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen(
      (event) {
        print("======>");
        print(event.docs.length);
        count.value = event.docs.length.toString();
      },
    );
  }
}
