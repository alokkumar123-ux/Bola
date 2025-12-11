import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/controller/booking_payment_controller.dart';
import 'package:poolmate/themes/app_them_data.dart';

class BookingPaymentScreen extends StatelessWidget {
  const BookingPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BookingPaymentController>(
      init: BookingPaymentController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppThemeData.grey50,
          appBar: AppBar(
            title: Text(
              "Select Payment Method".tr,
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
            ),
          ),
          body: SafeArea(
            child: controller.isLoading.value
                ? Constant.loader()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Payment Summary Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Payment Summary".tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Number of Seats".tr,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    controller.numberOfSeats.value.toString(),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Price per Seat".tr,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    Constant.amountShow(
                                        amount: controller.pricePerSeat.value
                                            .toString()),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Amount".tr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    Constant.amountShow(
                                        amount: controller.totalAmount.value
                                            .toString()),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Select Payment Method".tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Payment Methods List
                        Expanded(
                          child: ListView(
                            children: [
                              // Wallet Payment Option
                              _buildPaymentOption(
                                context: context,
                                controller: controller,
                                title: "Wallet",
                                icon: Icons.account_balance_wallet,
                                paymentMethod: "Wallet",
                                subtitle: controller.walletBalance.value <
                                        controller.totalAmount.value
                                    ? "Insufficient Balance: ${Constant.amountShow(amount: controller.walletBalance.value.toString())}"
                                    : "Balance: ${Constant.amountShow(amount: controller.walletBalance.value.toString())}",
                                isDisabled: controller.walletBalance.value <
                                    controller.totalAmount.value,
                              ),
            
                              // Cashfree Payment Option
                              if (controller
                                      .paymentModel.value.cashfree?.enable ==
                                  true)
                                _buildPaymentOption(
                                  context: context,
                                  controller: controller,
                                  title: controller
                                          .paymentModel.value.cashfree?.name ??
                                      "Cashfree",
                                  icon: Icons.payment,
                                  paymentMethod: "Cashfree",
                                ),
            
                              // Add more payment methods as needed
                              // You can add Stripe, PayPal, etc. here
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: controller.selectedPaymentMethod.value.isEmpty
                  ? null
                  : () => controller.processPayment(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary300,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _getButtonText(controller),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required BookingPaymentController controller,
    required String title,
    required IconData icon,
    required String paymentMethod,
    String? subtitle,
    bool isDisabled = false,
  }) {
    final isSelected = controller.selectedPaymentMethod.value == paymentMethod;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              controller.selectedPaymentMethod.value = paymentMethod;
              controller.update();
            },
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled
                  ? Colors.grey.shade400
                  : (isSelected
                      ? AppThemeData.primary300
                      : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected && !isDisabled
                ? [
                    BoxShadow(
                      color: AppThemeData.primary300.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppThemeData.primary300.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppThemeData.primary300 : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppThemeData.primary300
                            : Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected && !isDisabled)
                Icon(
                  Icons.check_circle,
                  color: AppThemeData.primary300,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText(BookingPaymentController controller) {
    if (controller.selectedPaymentMethod.value.isEmpty) {
      return "Select Payment Method";
    }

    final amount =
        Constant.amountShow(amount: controller.totalAmount.value.toString());

    switch (controller.selectedPaymentMethod.value) {
      case "Wallet":
        if (controller.walletBalance.value < controller.totalAmount.value) {
          return "Insufficient Balance";
        }
        return "Pay with Wallet - $amount";
      case "Cashfree":
        return "Pay with Cashfree - $amount";
      default:
        return "Pay $amount";
    }
  }
}
