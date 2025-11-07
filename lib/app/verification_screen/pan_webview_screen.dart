import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PanWebViewScreen extends StatefulWidget {
  final String userId;
  final String name;
  const PanWebViewScreen({super.key, required this.userId, required this.name});

  @override
  State<PanWebViewScreen> createState() => _PanWebViewScreenState();
}

class _PanWebViewScreenState extends State<PanWebViewScreen> {
  late final WebViewController _controller;
  StreamSubscription<DocumentSnapshot>? _sub;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    final String url =
        'https://bolaletsgo.com/aadhar/pan.php/?user=${widget.userId}&name=${Uri.encodeComponent(widget.name)}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      final isValid = (data != null && (data['panVerified'] == true));
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
        title: const Text('PAN Verification'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(result: false),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
