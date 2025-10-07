import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/report_model.dart';
import 'package:poolmate/utils/fire_store_utils.dart';

class ReportHelpController extends GetxController {
  RxBool isLoading = true.obs;

  RxString reportedBy = "".obs;
  RxString reportedTo = "".obs;
  RxString bookingId = "".obs;

  List<dynamic> customerList = <dynamic>[].obs;
  List<dynamic> publisherList = <dynamic>[].obs;

  RxString selectedReasons = "".obs;
  Rx<TextEditingController> descriptionController = TextEditingController().obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();

    super.onInit();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      reportedBy.value = argumentData['reportedBy'];
      reportedTo.value = argumentData['reportedTo'];
      bookingId.value = argumentData['bookingId'];
    }
    await getReportList();
  }

  getReportList() async {
    await FireStoreUtils.fireStore.collection(CollectionName.settings).doc("reasons").get().then((event) {
      if (event.exists) {
        customerList = event.data()!["customer"];
        publisherList = event.data()!["publisher"];
        update();
      }
    });
    isLoading.value = false;

  }

  publishReport() async {
    ReportModel reportModel = ReportModel();
    reportModel.id = Constant.getUuid();
    reportModel.title = selectedReasons.value;
    reportModel.description = descriptionController.value.text;
    reportModel.reportedFrom = FireStoreUtils.getCurrentUid();
    reportModel.reportedTo = reportedTo.value;
    reportModel.status = "Pending";
    reportModel.bookingId = bookingId.value;

    await FireStoreUtils.setReport(reportModel).then((value) {
      ShowToastDialog.showToast("Report place successfully");
      Get.back();
    },);
  }
}
