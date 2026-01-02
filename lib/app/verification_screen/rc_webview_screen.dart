import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

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
  StreamSubscription? _sub;
  bool _completed = false;
  bool _isLoading = true;
  late String _url;

  @override
  void initState() {
    super.initState();
    _url = 'https://bolaletsgo.com/aadhar/rc.php?user=${widget.userId}';

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
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              useHybridComposition: true,
            ),
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
