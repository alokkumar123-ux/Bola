import 'package:get/get.dart';
import 'package:poolmate/model/review_model.dart';
import 'package:poolmate/utils/firestore/review_utils.dart';

class RatingViewController extends GetxController {
  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  RxList<ReviewModel> ratingList = <ReviewModel>[].obs;

  RxBool isLoading = true.obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    var receiverUserId = argumentData['receiverUserId'];
    if (receiverUserId != null) {
      await getRating(receiverUserId: receiverUserId);
    }
  }

  getRating({required String receiverUserId}) async {
    await ReviewUtils.getRating(receiverUserId).then(
      (value) {
        if (value != null) {
          ratingList.value = value;
        }
      },
    );
    isLoading.value = false;
  }
}
