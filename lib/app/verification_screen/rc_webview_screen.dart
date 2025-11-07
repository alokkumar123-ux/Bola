import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RcWebViewScreen extends StatefulWidget {
  final String userId;
  final String vehicleNumber;
  const RcWebViewScreen({
    super.key,
    required this.userId,
    required this.vehicleNumber,
  });

  @override
  State<RcWebViewScreen> createState() => _RcWebViewScreenState();
}

class _RcWebViewScreenState extends State<RcWebViewScreen> {
  late final WebViewController _controller;
  StreamSubscription? _sub;
  bool _completed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final String url =
        'https://bolaletsgo.com/aadhar/rc.php?user=${widget.userId}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    // Listen to Firebase for RC verification status in users collection
    // Specifically monitor for the vehicle number that was entered
    final vehicleNumberToCheck = widget.vehicleNumber.trim().toUpperCase();

    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && !_completed) {
        final data = snapshot.data();
        if (data != null && data.containsKey('rcinfo')) {
          final rcinfo = data['rcinfo'] as Map<String, dynamic>?;
          if (rcinfo != null && rcinfo.containsKey(vehicleNumberToCheck)) {
            // The specific vehicle number has been verified
            _completed = true;
            final rcData =
                rcinfo[vehicleNumberToCheck] as Map<String, dynamic>?;
            Get.back(result: {
              'verified': true,
              'vehicleNumber': vehicleNumberToCheck,
              'rcData': rcData,
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify RC'.tr),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(result: false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
