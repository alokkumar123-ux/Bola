import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/payment_method_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/model/wallet_transaction_model.dart';
import 'package:poolmate/model/withdraw_method_model.dart';
import 'package:poolmate/model/withdraw_model.dart';
import 'package:poolmate/utils/firestore/payment_utils.dart';
import 'package:poolmate/utils/firestore/withdraw_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/wallet_utils.dart';

class WalletController extends GetxController {
  RxBool isLoading = true.obs;

  Rx<TextEditingController> withdrawalAmountController =
      TextEditingController().obs;
  Rx<TextEditingController> noteController = TextEditingController().obs;

  RxInt selectedValue = 0.obs;

  Rx<PaymentModel> paymentModel = PaymentModel().obs;

  RxInt selectedTabIndex = 0.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getUserData();
    getTraction();
    super.onInit();
  }

  Rx<UserModel> userModel = UserModel().obs;
  RxList transactionList = <WalletTransactionModel>[].obs;
  RxList withdrawList = <WithdrawModel>[].obs;

  Rx<WithdrawMethodModel> withdrawMethodModel = WithdrawMethodModel().obs;

  getUserData() async {
    await PaymentUtils().getPayment().then((value) {
      if (value != null) {
        paymentModel.value = value;
      }
    });

    await WithdrawUtils.getWithdrawMethod().then(
      (value) {
        if (value != null) {
          withdrawMethodModel.value = value;
        }
      },
    );

    isLoading.value = false;
  }

  getTraction() async {
    await UserUtils.getUserProfile(AuthUtils.getCurrentUid()).then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });

    await WalletUtils.getWalletTransaction().then((value) {
      if (value != null) {
        transactionList.value = value;
      }
    });

    await WithdrawUtils.getWithDrawRequest().then((value) {
      if (value != null) {
        withdrawList.value = value;
      }
    });
  }

  RxString amount = "0.0".obs;
  RxString paymentType = "".obs;

  walletTopUp() async {
    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: amount.value,
        createdDate: Timestamp.now(),
        paymentType: paymentType.value,
        transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: AuthUtils.getCurrentUid(),
        isCredit: true,
        note: "Wallet Topup");

    await WalletUtils.setWalletTransaction(transactionModel)
        .then((value) async {
      if (value == true) {
        await WalletUtils.updateUserWallet(amount: amount.value).then((value) {
          getUserData();
          getTraction();
        });
      }
    });

    ShowToastDialog.showToast("Amount added in your wallet.");
  }
}
