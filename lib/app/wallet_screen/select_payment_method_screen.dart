import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/payment/createRazorPayOrderModel.dart';
import 'package:poolmate/app/payment/rozorpayConroller.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/select_payment_method_controller.dart';
import 'package:poolmate/model/wallet_transaction_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/themes/text_field_widget.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/wallet_utils.dart';

class SelectPaymentMethodScreen extends StatelessWidget {
  const SelectPaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: SelectPaymentMethodController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.grey900
                : AppThemeData.grey50,
            appBar: AppBar(
              backgroundColor: themeChange.getThem()
                  ? AppThemeData.grey900
                  : AppThemeData.grey50,
              centerTitle: false,
              titleSpacing: 0,
              leading: InkWell(
                onTap: () {
                  Get.back();
                },
                child: Icon(
                  Icons.chevron_left_outlined,
                  color: themeChange.getThem()
                      ? AppThemeData.grey50
                      : AppThemeData.grey900,
                ),
              ),
              title: Text(
                "Select Payment Method".tr,
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey100
                        : AppThemeData.grey800,
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 16),
              ),
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: Container(
                  color: themeChange.getThem()
                      ? AppThemeData.grey700
                      : AppThemeData.grey200,
                  height: 4.0,
                ),
              ),
            ),
            body: SafeArea(
              child: controller.isLoading.value
                  ? Center(child: Constant.loader())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Column(
                          children: [
                            controller.type.value == "wallet"
                                ? TextFieldWidget(
                                    hintText: 'Enter Amount'.tr,
                                    controller:
                                        controller.amountController.value,
                                    textInputType: kIsWeb
                                        ? TextInputType.number
                                        : Platform.isIOS
                                            ? const TextInputType
                                                .numberWithOptions(
                                                signed: true, decimal: true)
                                            : TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,4}'))
                                    ],
                                    title: 'Enter Amount'.tr,
                                    prefix: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      child: Text(
                                        Constant.currencyModel!.symbol
                                            .toString(),
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                            Visibility(
                              visible: controller.paymentModel.value.wallet !=
                                      null &&
                                  controller
                                          .paymentModel.value.wallet!.enable ==
                                      true &&
                                  (controller.type.value == "booking" ||
                                      controller.type.value == "bookingSelect"),
                              child: cardDecoration(
                                  controller,
                                  controller.paymentModel.value.wallet!.name
                                      .toString(),
                                  themeChange,
                                  "assets/images/ic_wallet_image.png"),
                            ),
                            Visibility(
                              visible: controller.paymentModel.value.strip !=
                                      null &&
                                  controller.paymentModel.value.strip!.enable ==
                                      true &&
                                  // Hide online payment if driver prefers cash
                                  !(controller.driverPaymentMethod.value ==
                                      "Cash"),
                              child: cardDecoration(
                                  controller,
                                  controller.paymentModel.value.strip!.name
                                      .toString(),
                                  themeChange,
                                  "assets/images/stripe.png"),
                            ),
                            Visibility(
                              visible: controller.paymentModel.value.paypal !=
                                      null &&
                                  controller
                                          .paymentModel.value.paypal!.enable ==
                                      true &&
                                  // Hide online payment if driver prefers cash
                                  !(controller.driverPaymentMethod.value ==
                                      "Cash"),
                              child: cardDecoration(
                                  controller,
                                  controller.paymentModel.value.paypal!.name
                                      .toString(),
                                  themeChange,
                                  "assets/images/paypal.png"),
                            ),
                            Visibility(
                              visible: controller.paymentModel.value.payStack !=
                                      null &&
                                  controller.paymentModel.value.payStack!
                                          .enable ==
                                      true &&
                                  // Hide online payment if driver prefers cash
                                  !(controller.driverPaymentMethod.value ==
                                      "Cash"),
                              child: cardDecoration(
                                  controller,
                                  controller.paymentModel.value.payStack!.name
                                      .toString(),
                                  themeChange,
                                  "assets/images/paystack.png"),
                            ),
                            Visibility(
                              visible:
                                  controller.paymentModel.value.mercadoPago !=
                                          null &&
                                      controller.paymentModel.value.mercadoPago!
                                              .enable ==
                                          true,
                              child: cardDecoration(
                                  controller,
                                  controller
                                      .paymentModel.value.mercadoPago!.name
                                      .toString(),
                                  themeChange,
                                  "assets/images/mercado-pago.png"),
                            ),
                            Visibility(
                              visible:
                                  controller.paymentModel.value.flutterWave !=
                                          null &&
                                      controller.paymentModel.value.flutterWave!
                                              .enable ==
                                          true,
                              child: cardDecoration(
                                  controller,
                                  controller
                                      .paymentModel.value.flutterWave!.name
                                      .toString(),
                                  themeChange,
                                  "assets/images/flutterwave_logo.png"),
                            ),
                            Visibility(
                              visible: controller.paymentModel.value.payfast !=
                                      null &&
                                  controller
                                          .paymentModel.value.payfast!.enable ==
                                      true,
                              child: cardDecoration(
                                  controller,
                                  controller.paymentModel.value.payfast!.name
                                      .toString(),
                                  themeChange,
                                  "assets/images/payfast.png"),
                            ),
                            Visibility(
                              visible: controller.paymentModel.value.paytm !=
                                      null &&
                                  controller.paymentModel.value.paytm!.enable ==
                                      true,
                              child: cardDecoration(
                                  controller,
                                  controller.paymentModel.value.paytm!.name
                                      .toString(),
                                  themeChange,
                                  "assets/images/paytm.png"),
                            ),
                            Visibility(
                              visible: controller.paymentModel.value.razorpay !=
                                      null &&
                                  controller.paymentModel.value.razorpay!
                                          .enable ==
                                      true,
                              child: cardDecoration(
                                  controller,
                                  controller.paymentModel.value.razorpay!.name
                                      .toString(),
                                  themeChange,
                                  "assets/images/razorpay.png"),
                            ),
                            Visibility(
                              visible: controller.paymentModel.value.xendit !=
                                      null &&
                                  controller
                                          .paymentModel.value.xendit!.enable ==
                                      true,
                              child: cardDecoration(
                                  controller,
                                  controller.paymentModel.value.xendit!.name
                                      .toString(),
                                  themeChange,
                                  "assets/images/xendit.png"),
                            ),
                            Visibility(
                              visible:
                                  controller.paymentModel.value.orangePay !=
                                          null &&
                                      controller.paymentModel.value.orangePay!
                                              .enable ==
                                          true,
                              child: cardDecoration(
                                  controller,
                                  controller.paymentModel.value.orangePay!.name
                                      .toString(),
                                  themeChange,
                                  "assets/images/orangeMoney.png"),
                            ),
                            Visibility(
                              visible: controller.paymentModel.value.midtrans !=
                                      null &&
                                  controller.paymentModel.value.midtrans!
                                          .enable ==
                                      true,
                              child: cardDecoration(
                                  controller,
                                  controller.paymentModel.value.midtrans!.name
                                      .toString(),
                                  themeChange,
                                  "assets/images/midtrans.png"),
                            ),
                            Visibility(
                              visible: controller.paymentModel.value.cashfree !=
                                      null &&
                                  controller.paymentModel.value.cashfree!
                                          .enable ==
                                      true,
                              child: cardDecoration(
                                  controller,
                                  controller
                                          .paymentModel.value.cashfree?.name ??
                                      "Cashfree",
                                  themeChange,
                                  "assets/images/cashfree_icon.png"),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: RoundedButtonFill(
                  title: "Next".tr,
                  color: AppThemeData.primary300,
                  textColor: AppThemeData.grey50,
                  onPress: () async {
                    if (controller.type.value == "bookingSelect") {
                      // Handle Cashfree payment for seat booking
                      if (controller.selectedPaymentMethod.value ==
                          (controller.paymentModel.value.cashfree?.name ??
                              "Cashfree")) {
                        // Get the amount from arguments
                        dynamic argumentData = Get.arguments;
                        String amount = argumentData?['amount'] ?? "0";
              
                        if (amount.isEmpty || amount == "0") {
                          ShowToastDialog.showToast(
                              "Please enter a valid amount");
                          return;
                        }
              
                        // Process Cashfree payment
                        controller.cashfreePayment(
                            amount: amount, context: context);
                      } else {
                        // For other payment methods, just return the selection
                        Get.back(result: {
                          "paymentType": controller.selectedPaymentMethod.value
                        });
                      }
                    } else if (controller.type.value == "booking") {
                      if (controller.selectedPaymentMethod.value ==
                          controller.paymentModel.value.strip!.name) {
                        controller.stripeMakePayment(
                            amount: controller.amountController.value.text);
                      } else if (controller.selectedPaymentMethod.value ==
                          controller.paymentModel.value.paypal!.name) {
                        controller.paypalPaymentSheet(
                            controller.amountController.value.text, context);
                      } else if (controller.selectedPaymentMethod.value ==
                          controller.paymentModel.value.payStack!.name) {
                        controller.payStackPayment(
                            controller.amountController.value.text);
                      } else if (controller.selectedPaymentMethod.value ==
                          controller.paymentModel.value.mercadoPago!.name) {
                        controller.mercadoPagoMakePayment(
                            context: context,
                            amount: controller.amountController.value.text);
                      } else if (controller.selectedPaymentMethod.value ==
                          controller.paymentModel.value.flutterWave!.name) {
                        controller.flutterWaveInitiatePayment(
                            context: context,
                            amount: controller.amountController.value.text);
                      } else if (controller.selectedPaymentMethod.value ==
                          controller.paymentModel.value.payfast!.name) {
                        controller.payFastPayment(
                            context: context,
                            amount: controller.amountController.value.text);
                      } else if (controller.selectedPaymentMethod.value ==
                          controller.paymentModel.value.paytm!.name) {
                        controller.getPaytmCheckSum(context,
                            amount: double.parse(
                                controller.amountController.value.text));
                      } else if (controller.selectedPaymentMethod.value ==
                          controller.paymentModel.value.xendit!.name) {
                        controller.xenditPayment(context,
                            double.parse(controller.amountController.value.text));
                      } else if (controller.selectedPaymentMethod.value ==
                          controller.paymentModel.value.orangePay!.name) {
                        controller.orangeMakePayment(
                            amount:
                                controller.amountController.value.text.toString(),
                            context: context);
                      } else if (controller.selectedPaymentMethod.value ==
                          controller.paymentModel.value.midtrans!.name) {
                        controller.midtransMakePayment(
                            amount:
                                controller.amountController.value.text.toString(),
                            context: context);
                      } else if (controller.selectedPaymentMethod.value ==
                          (controller.paymentModel.value.cashfree?.name ??
                              "Cashfree")) {
                        controller.cashfreePayment(
                            amount: controller.amountController.value.text,
                            context: context);
                      } else if (controller.selectedPaymentMethod.value ==
                          controller.paymentModel.value.razorpay!.name) {
                        RazorPayController()
                            .createOrderRazorPay(
                                amount: double.parse(
                                        controller.amountController.value.text)
                                    .toStringAsFixed(2),
                                razorpayModel:
                                    controller.paymentModel.value.razorpay)
                            .then((value) {
                          if (value == null) {
                            Get.back();
                            ShowToastDialog.showToast(
                                "Something went wrong, please contact admin.".tr);
                          } else {
                            CreateRazorPayOrderModel result = value;
                            controller.openCheckout(
                                amount: controller.amountController.value.text,
                                orderId: result.id);
                          }
                        });
                      } else if (controller.selectedPaymentMethod.value ==
                          controller.paymentModel.value.wallet!.name) {
                        if (double.parse(controller.userModel.value.walletAmount
                                .toString()) >=
                            double.parse(
                                controller.amountController.value.text)) {
                          WalletTransactionModel transactionModel =
                              WalletTransactionModel(
                                  id: Constant.getUuid(),
                                  amount: controller.amountController.value.text,
                                  createdDate: Timestamp.now(),
                                  paymentType:
                                      controller.selectedPaymentMethod.value,
                                  transactionId: controller.bookingId.value,
                                  type: "customer",
                                  note: "Booking amount debit".tr,
                                  userId: AuthUtils.getCurrentUid(),
                                  isCredit: false);
              
                          await WalletUtils.setWalletTransaction(transactionModel)
                              .then((value) async {
                            if (value == true) {
                              await WalletUtils.updateUserWallet(
                                      amount:
                                          "-${controller.amountController.value.text.toString()}")
                                  .then((value) {
                                ShowToastDialog.showToast("Payment successfully");
                                controller.walletTopUp();
                              });
                            }
                          });
                        } else {
                          ShowToastDialog.showToast(
                              "Wallet Amount Insufficient".tr);
                        }
                      } else {
                        ShowToastDialog.showToast(
                            "Please select payment method".tr);
                      }
                    } else {
                      // Check wallet balance and enforce minimum top-up for negative balances
                      double currentBalance = double.parse(
                          controller.userModel.value.walletAmount ?? "0");
                      double topUpAmount = controller
                              .amountController.value.text.isNotEmpty
                          ? double.parse(controller.amountController.value.text)
                          : 0;
              
                      // If balance is -500 or less, user must top up enough to reach at least 0
                      if (currentBalance <= -500) {
                        double minimumRequired =
                            currentBalance.abs(); // Amount needed to reach zero
                        if (topUpAmount < minimumRequired) {
                          ShowToastDialog.showToast(
                              "Your balance is ${Constant.amountShow(amount: currentBalance.toString())}. Please top up at least ${Constant.amountShow(amount: minimumRequired.toStringAsFixed(2))} to bring your balance to zero or positive."
                                  .tr);
                          return;
                        }
                      }
              
                      if (controller.amountController.value.text.isNotEmpty &&
                          double.parse(controller.amountController.value.text) >=
                              double.parse(
                                  Constant.minimumAmountToDeposit.toString())) {
                        if (controller.selectedPaymentMethod.value ==
                            controller.paymentModel.value.strip!.name) {
                          controller.stripeMakePayment(
                              amount: controller.amountController.value.text);
                        } else if (controller.selectedPaymentMethod.value ==
                            controller.paymentModel.value.paypal!.name) {
                          // controller.paypalPayment(controller.amountController.value.text);
                          controller.paypalPaymentSheet(
                              controller.amountController.value.text, context);
                        } else if (controller.selectedPaymentMethod.value ==
                            controller.paymentModel.value.payStack!.name) {
                          controller.payStackPayment(
                              controller.amountController.value.text);
                        } else if (controller.selectedPaymentMethod.value ==
                            controller.paymentModel.value.mercadoPago!.name) {
                          controller.mercadoPagoMakePayment(
                              context: context,
                              amount: controller.amountController.value.text);
                        } else if (controller.selectedPaymentMethod.value ==
                            controller.paymentModel.value.flutterWave!.name) {
                          controller.flutterWaveInitiatePayment(
                              context: context,
                              amount: controller.amountController.value.text);
                        } else if (controller.selectedPaymentMethod.value ==
                            controller.paymentModel.value.payfast!.name) {
                          controller.payFastPayment(
                              context: context,
                              amount: controller.amountController.value.text);
                        } else if (controller.selectedPaymentMethod.value ==
                            controller.paymentModel.value.paytm!.name) {
                          controller.getPaytmCheckSum(context,
                              amount: double.parse(
                                  controller.amountController.value.text));
                        } else if (controller.selectedPaymentMethod.value ==
                            controller.paymentModel.value.xendit!.name) {
                          controller.xenditPayment(
                              context, controller.amountController.value.text);
                        } else if (controller.selectedPaymentMethod.value ==
                            controller.paymentModel.value.orangePay!.name) {
                          controller.orangeMakePayment(
                              amount: controller.amountController.value.text
                                  .toString(),
                              context: context);
                        } else if (controller.selectedPaymentMethod.value ==
                            controller.paymentModel.value.midtrans!.name) {
                          controller.midtransMakePayment(
                              amount: controller.amountController.value.text
                                  .toString(),
                              context: context);
                        } else if (controller.selectedPaymentMethod.value ==
                            (controller.paymentModel.value.cashfree?.name ??
                                "Cashfree")) {
                          controller.cashfreePayment(
                              amount: controller.amountController.value.text,
                              context: context);
                        } else if (controller.selectedPaymentMethod.value ==
                            controller.paymentModel.value.razorpay!.name) {
                          RazorPayController()
                              .createOrderRazorPay(
                                  amount: double.parse(
                                          controller.amountController.value.text)
                                      .toStringAsFixed(2),
                                  razorpayModel:
                                      controller.paymentModel.value.razorpay)
                              .then((value) {
                            if (value == null) {
                              Get.back();
                              ShowToastDialog.showToast(
                                  "Something went wrong, please contact admin."
                                      .tr);
                            } else {
                              CreateRazorPayOrderModel result = value;
                              controller.openCheckout(
                                  amount: controller.amountController.value.text,
                                  orderId: result.id);
                            }
                          });
                        } else {
                          ShowToastDialog.showToast(
                              "Please select payment method".tr);
                        }
                      } else {
                        ShowToastDialog.showToast(
                            "Please Enter minimum amount of ${Constant.amountShow(amount: Constant.minimumAmountToDeposit)}"
                                .tr);
                      }
                    }
                  },
                ),
              ),
            ),
          );
        });
  }

  cardDecoration(SelectPaymentMethodController controller, String value,
      themeChange, String image) {
    return Obx(
      () => Column(children: [
        InkWell(
          onTap: () {
            controller.selectedPaymentMethod.value = value;
          },
          child: Row(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Image.asset(
                  image,
                  width: 80,
                  height: 40,
                  fit: BoxFit.contain,
                  color: themeChange.getThem() ? AppThemeData.grey50 : null,
                ),
              ),
              value == controller.paymentModel.value.wallet!.name
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Wallet",
                          style: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey100
                                  : AppThemeData.grey800,
                              fontFamily: AppThemeData.semiBold,
                              fontSize: 16),
                        ),
                        Text(
                          "Balance: ${Constant.amountShow(amount: controller.userModel.value.walletAmount)}",
                          style: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.primary300
                                  : AppThemeData.primary300,
                              fontFamily: AppThemeData.medium,
                              fontSize: 14),
                        ),
                      ],
                    )
                  : const SizedBox(),
              const SizedBox(
                width: 10,
              ),
              const Expanded(
                child: SizedBox(),
              ),
              Radio(
                value: value.toString(),
                groupValue: controller.selectedPaymentMethod.value,
                activeColor: themeChange.getThem()
                    ? AppThemeData.primary300
                    : AppThemeData.primary300,
                onChanged: (value) {
                  controller.selectedPaymentMethod.value = value.toString();
                },
              )
            ],
          ),
        ),
      ]),
    );
  }
}
