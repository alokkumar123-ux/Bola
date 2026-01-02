import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:poolmate/services/aadhaar_verification_service.dart';
import 'package:poolmate/model/aadhaar_verification_model.dart';

class AadhaarVerificationProvider extends ChangeNotifier {
  // States
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isVerified = false;

  // Data
  String? _aadhaarNumber;
  String? _refId;
  Map<String, dynamic>? _verifiedData;
  String? _errorMessage;

  // Rate limiting
  int _otpAttempts = 0;
  DateTime? _lastOtpTime;
  Timer? _retryTimer;
  int _retryCountdown = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get isOtpSent => _isOtpSent;
  bool get isVerified => _isVerified;
  String? get aadhaarNumber => _aadhaarNumber;
  String? get refId => _refId;
  Map<String, dynamic>? get verifiedData => _verifiedData;
  String? get errorMessage => _errorMessage;
  int get otpAttempts => _otpAttempts;
  int get retryCountdown => _retryCountdown;
  bool get canRetryOtp => _retryCountdown <= 0 && !_isLoading;

  /// Step 1: Generate OTP for Aadhaar verification
  Future<bool> generateOtp(String aadhaarNumber) async {
    try {
      // Check rate limits
      if (_isRateLimited()) {
        _setError(
            'Please wait ${_getRemainingWaitTime()} seconds before trying again');
        return false;
      }

      if (AadhaarVerificationService.isOtpGenerationLimitReached(
          _otpAttempts)) {
        _setError('Maximum OTP attempts reached. Please try again later.');
        return false;
      }

      _setLoading(true);
      _clearError();

      // Call the service
      final AadhaarOtpResponse result =
          await AadhaarVerificationService.generateOtp(aadhaarNumber);

      if (result.isSuccess) {
        _aadhaarNumber = aadhaarNumber;
        _refId = result.refId;
        _isOtpSent = true;
        _otpAttempts++;
        _lastOtpTime = DateTime.now();

        print('✅ OTP generated successfully');
        _setLoading(false);
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ Error in generateOtp: $e');
      _setError('Something went wrong. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Step 2: Verify the OTP received on mobile
  Future<bool> verifyOtp(String otp) async {
    try {
      if (_refId == null) {
        _setError('No reference ID found. Please request OTP again.');
        return false;
      }

      _setLoading(true);
      _clearError();

      // Call the service
      final AadhaarVerifyResponse result =
          await AadhaarVerificationService.verifyOtp(_refId!, otp);

      if (result.isSuccess) {
        _verifiedData = {
          'name': result.data?.name,
          'dob': result.data?.dateOfBirth,
          'gender': result.data?.gender,
          'address': result.data?.address?.fullAddress,
          'aadhaar_number': result.data?.aadhaarNumber,
        };
        _isVerified = true;

        print('✅ Aadhaar verified successfully');
        _setLoading(false);
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ Error in verifyOtp: $e');
      _setError('Something went wrong. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Resend OTP (reuses generateOtp)
  Future<bool> resendOtp() async {
    if (_aadhaarNumber == null) {
      _setError('No Aadhaar number found. Please start again.');
      return false;
    }
    return await generateOtp(_aadhaarNumber!);
  }

  /// Reset everything and start fresh
  void resetVerification() {
    _isOtpSent = false;
    _isVerified = false;
    _aadhaarNumber = null;
    _refId = null;
    _verifiedData = null;
    _errorMessage = null;
    _otpAttempts = 0;
    _lastOtpTime = null;
    _stopRetryTimer();
    notifyListeners();
  }

  /// Get masked Aadhaar for display (XXXX-XXXX-1234)
  String getMaskedAadhaar() {
    if (_aadhaarNumber == null) return '';
    return AadhaarVerificationService.getMaskedAadhaarNumber(_aadhaarNumber!);
  }

  /// Check if verification is complete and valid
  bool get isVerificationComplete => _isVerified && _verifiedData != null;

  /// Get user-friendly summary of verified data
  String get verificationSummary {
    if (!isVerificationComplete || _verifiedData == null) return '';

    final data = _verifiedData!;
    List<String> summary = [];

    // Extract data based on Cashfree's response format
    if (data['name'] != null) summary.add('Name: ${data['name']}');
    if (data['dob'] != null) summary.add('DOB: ${data['dob']}');
    if (data['gender'] != null) summary.add('Gender: ${data['gender']}');
    if (data['address'] != null) summary.add('Address: ${data['address']}');

    return summary.join('\n');
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool _isRateLimited() {
    if (_lastOtpTime == null) return false;

    final timeSince = DateTime.now().difference(_lastOtpTime!);
    final waitTime = AadhaarVerificationService.getOtpRetryWaitTime();

    if (timeSince < waitTime) {
      _startRetryCountdown((waitTime - timeSince).inSeconds);
      return true;
    }

    return false;
  }

  int _getRemainingWaitTime() {
    if (_lastOtpTime == null) return 0;

    final timeSince = DateTime.now().difference(_lastOtpTime!);
    final waitTime = AadhaarVerificationService.getOtpRetryWaitTime();

    return (waitTime - timeSince).inSeconds;
  }

  void _startRetryCountdown(int seconds) {
    _retryCountdown = seconds;
    _stopRetryTimer();

    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _retryCountdown--;
      notifyListeners();

      if (_retryCountdown <= 0) {
        _stopRetryTimer();
      }
    });
  }

  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCountdown = 0;
  }

  @override
  void dispose() {
    _stopRetryTimer();
    super.dispose();
  }
}
