import 'package:get/get.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';

class ProfileController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<UserModel> userModel = UserModel().obs;
  bool hasShownSosDialog = false;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  getData() async {
    await UserUtils.getUserProfile(AuthUtils.getCurrentUid()).then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });

    isLoading.value = false;
  }
}
