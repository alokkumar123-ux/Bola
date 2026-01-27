import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/select_payment_method_controller.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/themes/text_field_widget.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: RoundedButtonFill(
                        title: controller.type.value == "bookingSelect"
                            ? "Proceed".tr
                            : "Next".tr,
                        color: AppThemeData.primary300,
                        textColor: AppThemeData.grey50,
                        onPress: () async {
                          // Check if payment method is selected
                          if (controller.selectedPaymentMethod.value.isEmpty) {
                            ShowToastDialog.showToast(
                                "Please select payment method".tr);
                            return;
                          }

                          // Handle bookingSelect type (seat booking)
                          if (controller.type.value == "bookingSelect") {
                            String walletName =
                                controller.paymentModel.value.wallet?.name ??
                                    "Wallet";
                            String cashfreeName =
                                controller.paymentModel.value.cashfree?.name ??
                                    "Cashfree";

                            if (controller.selectedPaymentMethod.value ==
                                cashfreeName) {
                              // Cashfree selected - trigger payment with provided amount
                              String paymentAmount = controller
                                      .amountController.value.text.isNotEmpty
                                  ? controller.amountController.value.text
                                  : controller.subTotal.value;

                              if (paymentAmount.isEmpty ||
                                  double.parse(paymentAmount) <= 0) {
                                ShowToastDialog.showToast(
                                    "Invalid payment amount".tr);
                                return;
                              }

                              controller.cashfreePayment(
                                  amount: paymentAmount, context: context);
                              // Note: After successful payment, booking is created automatically
                              // and user is navigated to success screen
                            } else if (controller.selectedPaymentMethod.value ==
                                walletName) {
                              // Wallet selected - return payment type for manual booking
                              Get.back(result: {
                                "paymentType":
                                    controller.selectedPaymentMethod.value,
                                "paymentSuccess":
                                    false // Wallet payment happens at booking time
                              });
                            } else {
                              ShowToastDialog.showToast(
                                  "Invalid payment method selected".tr);
                            }
                            return;
                          }

                          // Handle wallet top-up
                          // Check wallet balance and enforce minimum top-up for negative balances
                          double currentBalance = double.parse(
                              controller.userModel.value.walletAmount ?? "0");
                          double topUpAmount =
                              controller.amountController.value.text.isNotEmpty
                                  ? double.parse(
                                      controller.amountController.value.text)
                                  : 0;

                          // If balance is -500 or less, user must top up enough to reach at least 0
                          if (currentBalance <= -500) {
                            double minimumRequired = currentBalance
                                .abs(); // Amount needed to reach zero
                            if (topUpAmount < minimumRequired) {
                              ShowToastDialog.showToast(
                                  "Your balance is ${Constant.amountShow(amount: currentBalance.toString())}. Please top up at least ${Constant.amountShow(amount: minimumRequired.toStringAsFixed(2))} to bring your balance to zero or positive."
                                      .tr);
                              return;
                            }
                          }

                          if (controller
                                  .amountController.value.text.isNotEmpty &&
                              double.parse(
                                      controller.amountController.value.text) >=
                                  double.parse(Constant.minimumAmountToDeposit
                                      .toString())) {
                            if (controller.selectedPaymentMethod.value ==
                                (controller.paymentModel.value.cashfree?.name ??
                                    "Cashfree")) {
                              controller.cashfreePayment(
                                  amount:
                                      controller.amountController.value.text,
                                  context: context);
                            } else {
                              ShowToastDialog.showToast(
                                  "Please select payment method".tr);
                            }
                          } else {
                            ShowToastDialog.showToast(
                                "Please Enter minimum amount of ${Constant.amountShow(amount: Constant.minimumAmountToDeposit)}"
                                    .tr);
                          }
                        }))));
      },
    );
  }
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
