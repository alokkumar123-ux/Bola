import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:poolmate/model/fcm_token_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/fcm_token_utils.dart';
import 'package:poolmate/utils/notification_service.dart';

/// Comprehensive FCM Token Manager
/// Handles token lifecycle, refresh, and multi-device support
class FcmTokenManager extends GetxService {
  static FcmTokenManager get instance {
    if (!Get.isRegistered<FcmTokenManager>()) {
      Get.put(FcmTokenManager(), permanent: true);
    }
    return Get.find<FcmTokenManager>();
  }

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _currentToken;
  String? _deviceId;
  bool _isInitialized = false;

  /// Get the current FCM token
  String? get currentToken => _currentToken;

  /// Get the device ID (used as document ID in fcm_tokens subcollection)
  String get deviceId => _deviceId ?? _generateDeviceId();

  /// Initialize FCM token manager
  /// Should be called after user authentication
  Future<void> initialize() async {
    if (kIsWeb) {
      print('🔔 FcmTokenManager: Skipping initialization on web');
      return;
    }

    if (_isInitialized) {
      print('🔔 FcmTokenManager: Already initialized');
      return;
    }

    print('🔔 FcmTokenManager: Initializing...');

    try {
      // Request permission first
      final permissionGranted = await _requestPermission();
      if (!permissionGranted) {
        print(
            '⚠️ FcmTokenManager: Permission not granted, skipping token fetch');
        return;
      }

      // Generate device ID
      _deviceId = _generateDeviceId();
      print('🔔 Device ID: $_deviceId');

      // Get initial token
      await _fetchAndSaveToken();

      // Set up token refresh listener
      _setupTokenRefreshListener();

      // Initialize notification service for foreground handling
      await NotificationService().initInfo();

      _isInitialized = true;
      print('✅ FcmTokenManager: Initialization complete');
    } catch (e) {
      print('❌ FcmTokenManager: Initialization error: $e');
    }
  }

  /// Request notification permission
  /// Returns true if authorized or provisional, false otherwise
  Future<bool> _requestPermission() async {
    try {
      print('🔔 Requesting notification permission...');

      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true, // For SOS alerts
        provisional: false,
        sound: true,
      );

      final status = settings.authorizationStatus;
      print('🔔 Permission status: $status');

      switch (status) {
        case AuthorizationStatus.authorized:
          print('✅ Notification permission: AUTHORIZED');
          return true;
        case AuthorizationStatus.provisional:
          print('⚠️ Notification permission: PROVISIONAL');
          return true;
        case AuthorizationStatus.denied:
          print('❌ Notification permission: DENIED');
          return false;
        case AuthorizationStatus.notDetermined:
          print('⚠️ Notification permission: NOT DETERMINED');
          return false;
      }
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Fetch FCM token and save to Firestore
  Future<void> _fetchAndSaveToken() async {
    try {
      print('🔔 Fetching FCM token...');

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        print('❌ Failed to get FCM token - token is null or empty');
        return;
      }

      _currentToken = token;
      print('🔔 FCM Token obtained: ${token.substring(0, 30)}...');

      // Save to Firestore if user is authenticated
      await _saveTokenToFirestore(token);
    } catch (e) {
      print('❌ Error fetching FCM token: $e');
    }
  }

  /// Set up listener for token refresh
  void _setupTokenRefreshListener() {
    print('🔔 Setting up token refresh listener...');

    _messaging.onTokenRefresh.listen((newToken) async {
      print('🔄 FCM Token REFRESHED: ${newToken.substring(0, 30)}...');
      _currentToken = newToken;

      // Update token in Firestore
      await _saveTokenToFirestore(newToken);
    }, onError: (error) {
      print('❌ Token refresh listener error: $error');
    });

    print('✅ Token refresh listener set up');
  }

  /// Save token to Firestore for the current user
  Future<void> _saveTokenToFirestore(String token) async {
    final userId = AuthUtils.getCurrentUid();
    if (userId.isEmpty) {
      print('⚠️ Cannot save FCM token - user not authenticated');
      return;
    }

    final tokenModel = FcmTokenModel(
      token: token,
      deviceId: deviceId,
      platform: _getPlatform(),
      createdAt: Timestamp.now(),
      lastUsedAt: Timestamp.now(),
      isActive: true,
    );

    await FcmTokenUtils.saveToken(userId: userId, tokenModel: tokenModel);
  }

  /// Get current platform string
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Generate a unique device ID
  /// Uses a combination of timestamp and random string for uniqueness
  String _generateDeviceId() {
    final platform = _getPlatform();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Create a simple hash-like string from timestamp
    final hash = timestamp.toRadixString(36);
    return '${platform}_$hash';
  }

  /// Deactivate token for current device (for logout)
  Future<void> deactivateCurrentDeviceToken() async {
    final userId = AuthUtils.getCurrentUid();
    if (userId.isEmpty) {
      print('⚠️ Cannot deactivate token - user not authenticated');
      return;
    }

    print('🔔 Deactivating FCM token for current device...');
    await FcmTokenUtils.deactivateToken(userId: userId, deviceId: deviceId);
    _currentToken = null;
  }

  /// Deactivate all tokens for user (for logout from all devices)
  Future<void> deactivateAllTokens() async {
    final userId = AuthUtils.getCurrentUid();
    if (userId.isEmpty) return;

    print('🔔 Deactivating all FCM tokens...');
    await FcmTokenUtils.deactivateAllTokens(userId);
    _currentToken = null;
  }

  /// Re-initialize token after login
  /// Call this when user logs in to ensure token is up-to-date
  Future<void> reinitializeAfterLogin() async {
    print('🔔 Re-initializing FCM after login...');
    _isInitialized = false;
    await initialize();
  }

  /// Get the current token value (for backward compatibility)
  static Future<String> getToken() async {
    if (kIsWeb) return '';

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('🔔 FCM Token retrieved: ${token.substring(0, 30)}...');
        return token;
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
    return '';
  }

  /// Static helper to save current token (for use in login flows)
  /// This is a lightweight version that just fetches and saves the token
  /// without triggering full initialization
  static Future<void> saveCurrentToken() async {
    if (kIsWeb) return;

    try {
      print('🔔 Saving current FCM token...');

      final manager = FcmTokenManager.instance;

      // Just fetch and save the token without full initialization
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        print('❌ Failed to get FCM token for saving');
        return;
      }

      print('🔔 FCM Token obtained: ${token.substring(0, 30)}...');
      manager._currentToken = token;

      // Generate device ID if not already set
      manager._deviceId ??= manager._generateDeviceId();

      // Save to Firestore
      await manager._saveTokenToFirestore(token);

      // Set up token refresh listener if not already done
      if (!manager._isInitialized) {
        manager._setupTokenRefreshListener();
        manager._isInitialized = true;
      }

      print('✅ FCM token saved successfully');
    } catch (e) {
      print('❌ Error saving current token: $e');
    }
  }
}
