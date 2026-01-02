import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class AadhaarWebViewScreen extends StatefulWidget {
  final String userId;
  final String name;
  const AadhaarWebViewScreen(
      {super.key, required this.userId, required this.name});

  @override
  State<AadhaarWebViewScreen> createState() => _AadhaarWebViewScreenState();
}

class _AadhaarWebViewScreenState extends State<AadhaarWebViewScreen> {
  StreamSubscription<DocumentSnapshot>? _sub;
  bool _completed = false;
  late String _url;

  @override
  void initState() {
    super.initState();
    _url =
        'https://bolaletsgo.com/aadhar/?user=${widget.userId}&name=${Uri.encodeComponent(widget.name)}';
    print('WebView URL: $_url');

    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      final isValid = (data != null && (data['aadharVerified'] == true));
      if (isValid && !_completed) {
        _completed = true;
        Get.back(result: true);
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
        title: const Text('Aadhaar Verification'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(result: false),
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          useHybridComposition: true,
        ),
        onWebViewCreated: (controller) {
          print('WebView created');
        },
        onLoadStart: (controller, url) {
          print('Loading: $url');
        },
        onLoadStop: (controller, url) {
          print('Loaded: $url');
        },
        onReceivedError: (controller, request, error) {
          print('WebView error: ${error.description}');
        },
      ),
    );
  }
}
