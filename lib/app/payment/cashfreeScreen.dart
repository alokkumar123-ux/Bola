import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/dashboard_screen.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';

class CashfreeScreen extends StatefulWidget {
  final String orderId;
  final String paymentSessionId;
  final String paymentUrl;
  final bool isSandbox;
  final Function(bool) onPaymentResult;

  const CashfreeScreen({
    super.key,
    required this.orderId,
    required this.paymentSessionId,
    required this.paymentUrl,
    required this.isSandbox,
    required this.onPaymentResult,
  });

  @override
  State<CashfreeScreen> createState() => _CashfreeScreenState();
}

class _CashfreeScreenState extends State<CashfreeScreen> {
  var cfPaymentGatewayService = CFPaymentGatewayService();
  bool isProcessing = true;
  bool hasNavigated = false;

  @override
  void initState() {
    super.initState();
    print("=== CASHFREE NATIVE SDK INITIALIZATION ===");
    print("Order ID: ${widget.orderId}");
    print("Payment Session ID: ${widget.paymentSessionId}");
    print("Is Sandbox: ${widget.isSandbox}");
    print("==========================================");

    // Set payment callbacks
    cfPaymentGatewayService.setCallback(verifyPayment, onError);

    // Start payment automatically
    _startCashfreePayment();
  }

  // ✅ Payment Success Callback
  void verifyPayment(String orderId) {
    print("✅ Payment successful for Order ID: $orderId");
    if (!hasNavigated && mounted) {
      setState(() {
        hasNavigated = true;
        isProcessing = false;
      });

      ShowToastDialog.showToast("Payment Successful!");
      widget.onPaymentResult(true);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Get.back(result: true);
        }
      });
    } else if (!mounted) {
      print(
          "⚠️ Payment success callback received but widget is already disposed");
    }
  }

  // ✅ Payment Error Callback
  void onError(CFErrorResponse errorResponse, String orderId) {
    print("❌ Payment error for Order ID: $orderId");
    print("Error: ${errorResponse.getMessage()}");

    if (!hasNavigated && mounted) {
      setState(() {
        hasNavigated = true;
        isProcessing = false;
      });

      ShowToastDialog.showToast(
          "Payment failed: ${errorResponse.getMessage()}");
      widget.onPaymentResult(false);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Get.back(result: false);
        }
      });
    } else if (!mounted) {
      print(
          "⚠️ Payment error callback received but widget is already disposed");
    }
  }

  // ✅ Create Cashfree Session
  CFSession? createSession() {
    try {
      CFEnvironment environment =
          widget.isSandbox ? CFEnvironment.SANDBOX : CFEnvironment.PRODUCTION;
      print(
          "🌍 Using environment: ${widget.isSandbox ? 'SANDBOX' : 'PRODUCTION'}");
      print("📋 Order ID: ${widget.orderId}");
      print("🔑 Payment Session ID: ${widget.paymentSessionId}");
      var session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(widget.orderId)
          .setPaymentSessionId(widget.paymentSessionId)
          .build();

      print("✅ Cashfree session created successfully");
      return session;
    } on CFException catch (e) {
      print("❌ Error creating Cashfree session: ${e.message}");
      return null;
    }
  }

  // ✅ Start Cashfree Web Checkout Payment
  Future<void> _startCashfreePayment() async {
    try {
      setState(() {
        isProcessing = true;
      });

      // Create session
      var session = createSession();
      if (session == null) {
        _handlePaymentFailure("Failed to create payment session 1");
        return;
      }

      // Create web checkout payment
      var cfWebCheckout =
          CFWebCheckoutPaymentBuilder().setSession(session).build();

      print("🚀 Starting Cashfree payment...");

      // Start payment - this will open the Cashfree payment UI
      await cfPaymentGatewayService.doPayment(cfWebCheckout);
    } on CFException catch (e) {
      print("❌ CFException: ${e.message}");
      _handlePaymentFailure("Payment initialization failed: ${e.message}");
    } catch (e) {
      print("❌ General error: $e");
      _handlePaymentFailure("Unexpected error: $e");
    }
  }

  void _handlePaymentFailure(String errorMessage) {
    if (!hasNavigated) {
      setState(() {
        hasNavigated = true;
        isProcessing = false;
      });

      ShowToastDialog.showToast(errorMessage);
      widget.onPaymentResult(false);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Get.back(result: false);
        }
      });
    }
  }

  void handleBackPress() {
    if (!hasNavigated) {
      _handlePaymentFailure("Payment cancelled by user");
    }
  }

  @override
  void dispose() {
    print("🧹 Disposing CashfreeScreen - cleaning up callbacks");
    // Note: The Cashfree SDK doesn't provide a way to remove callbacks
    // but we've added mounted checks in the callbacks to prevent setState errors
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          handleBackPress();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cashfree Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: handleBackPress,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isProcessing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Initializing Cashfree Payment...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please wait while we prepare your payment',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Details:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Order ID: ${widget.orderId}'),
                        Text(
                            'Environment: ${widget.isSandbox ? "Sandbox" : "Production"}'),
                        const SizedBox(height: 8),
                        const Text(
                          'The Cashfree payment window will open shortly...',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Payment Processed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
