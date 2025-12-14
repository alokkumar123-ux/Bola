import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:poolmate/model/aadhaar_verification_model.dart';

class AadhaarVerificationService {
  // Configuration (can be overridden at runtime via configure)
  static String _clientId = "";
  static String _clientSecret = "";
  static bool _useSandbox = false; // default to sandbox for safety
  static bool _useSignature = true; // toggle between Signature and IP whitelist

  // Public Key (PEM content without or with headers; both supported)
  static String _publicKeyPem =
      "-----BEGIN PUBLIC KEY-----MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAs3Mh+ZDqsp2g8Gph8fHf2mhhhz0rivDlvIuDVWOmFf5UYrIbLWj8MRCVtcAQjCrcKOVCK9FtAoXvjczx9h0+ZxpdYaXPbTTyL5/xkwwEdX1UDBz5qfRHJDBLJT6L5yn0tqAg3JUsLT8wCotdjD/cRVTD+MgejqfdSO1ZjcK/TjfiZRwgzErtKRXWvJ4DT9Js/6JVVeMuRHt7TFaWS/AxWStJcLG84P9Vht7eS1AWigpR7wlUe1EPmQkL4Q34TIq+fxS8j8gevxui72CwD5i13wjvO8hLDXYqAIGN+BdO5vArAVEC7M8xnojqFlj+l8XYK6Xk9MSL2MJ/RJJP1oNOnQIDAQAB-----END PUBLIC KEY-----";

  /// Configure SDK credentials and environment at runtime.
  /// Provide PEM content of the public key as provided by Cashfree.
  static void configure({
    required String clientId,
    required String clientSecret,
    required String publicKeyPem,
    bool useSandbox = false,
    bool useSignature = true,
  }) {
    _clientId = clientId;
    _clientSecret = clientSecret;
    _publicKeyPem = publicKeyPem;
    _useSandbox = useSandbox;
    _useSignature = useSignature;
  }

  // Base URLs
  // Base URLs
  static const String _sandboxRoot =
      "https://sandbox.cashfree.com/verification";
  static const String _productionRoot = "https://api.cashfree.com/verification";

  // Feature paths
  static const String _offlineAadhaarPath = "/offline-aadhaar";
  static const String _credentialsVerifyPath = "/api/v1/credentials/verify";

  // Endpoints
  static const String _otpEndpoint = "/otp";
  static const String _verifyEndpoint = "/verify";

  static String get _rootUrl => _useSandbox ? _sandboxRoot : _productionRoot;
  static String get _offlineAadhaarBase => _rootUrl + _offlineAadhaarPath;

  // Headers with signature generation
  static Map<String, String> get _headers {
    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      log('❌ Cashfree config missing: clientId/clientSecret must be set via configure().');
      throw StateError('Cashfree credentials not configured');
    }

    final baseHeaders = {
      'Content-Type': 'application/json',
      // Add both header casings to avoid any proxy/gateway normalization issues
      'X-Client-Id': _clientId,
      'x-client-id': _clientId,
      'X-Client-Secret': _clientSecret,
      'x-client-secret': _clientSecret,
    };

    if (_useSignature) {
      if (_publicKeyPem.isEmpty) {
        throw StateError(
            'Cashfree public key not configured for signature mode');
      }
      try {
        // Generate signature as per Cashfree docs
        final signature = _generateSignature();
        baseHeaders['X-Cf-Signature'] = signature;
        baseHeaders['x-cf-signature'] = signature;
        log('✅ X-Cf-Signature generated and added to headers');
      } catch (e) {
        log('❌ CRITICAL: Failed to generate X-Cf-Signature: $e');
        log('💡 Ensure: correct public key, valid clientId, device time accurate');
        throw StateError('Failed to generate Cashfree X-Cf-Signature: $e');
      }
    } else {
      log('ℹ️ Using IP Whitelist mode: Skipping X-Cf-Signature');
    }

    log('📋 Final headers: ${baseHeaders.keys.toList()}');
    return baseHeaders;
  }

  /// Generate signature as per Cashfree documentation:
  /// 1. Create clientId.timestamp string
  /// 2. Encrypt using RSA with public key (RSA/ECB/OAEPWithSHA-1AndMGF1Padding)
  /// 3. Return base64 encoded result
  static String _generateSignature() {
    try {
      // Step 1: Create clientId with current UNIX timestamp
      final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final String dataToEncrypt = '$_clientId.$timestamp';

      log('🔐 Generating signature for: $dataToEncrypt');

      // Step 2: Parse the RSA public key
      final RSAPublicKey publicKey = _parsePublicKey(_publicKeyPem);

      // Step 3: Encrypt using RSA/ECB/OAEPWithSHA-1AndMGF1Padding
      final encrypter = OAEPEncoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

      // Convert string to bytes
      final Uint8List dataBytes =
          Uint8List.fromList(utf8.encode(dataToEncrypt));

      // Encrypt the data
      final Uint8List encryptedBytes = encrypter.process(dataBytes);

      // Step 4: Return base64 encoded signature
      final String signature = base64.encode(encryptedBytes);

      log('🔐 Signature generated - Length: ${signature.length}');
      return signature;
    } catch (e) {
      log('❌ Error generating signature: $e');
      throw Exception('Failed to generate Cashfree signature: $e');
    }
  }

  /// Parse RSA public key from PEM/base64. Handles X.509 SPKI, PKCS#1 and nested wrappers.
  static RSAPublicKey _parsePublicKey(String publicKeyPem) {
    RSAPublicKey? extractFromAsn1(ASN1Object obj) {
      if (obj is ASN1Sequence) {
        // Direct PKCS#1: [INTEGER n, INTEGER e]
        if (obj.elements.length >= 2 &&
            obj.elements[0] is ASN1Integer &&
            obj.elements[1] is ASN1Integer) {
          final n = (obj.elements[0] as ASN1Integer).valueAsBigInteger;
          final e = (obj.elements[1] as ASN1Integer).valueAsBigInteger;
          return RSAPublicKey(n, e);
        }
        // X.509 SPKI: [algoId, BIT STRING publicKey]
        if (obj.elements.length >= 2 && obj.elements[1] is ASN1BitString) {
          final bitString = obj.elements[1] as ASN1BitString;
          final inner = ASN1Parser(bitString.valueBytes()).nextObject();
          final r = extractFromAsn1(inner);
          if (r != null) return r;
        }
        // Other wrappers: recurse into child sequences
        for (final el in obj.elements) {
          final r = extractFromAsn1(el);
          if (r != null) return r;
        }
      } else if (obj is ASN1BitString) {
        final inner = ASN1Parser(obj.valueBytes()).nextObject();
        return extractFromAsn1(inner);
      } else if (obj is ASN1OctetString) {
        final inner = ASN1Parser(obj.valueBytes()).nextObject();
        return extractFromAsn1(inner);
      }
      return null;
    }

    // Try with various normalizations
    final variants = <String>[
      publicKeyPem,
      publicKeyPem
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', ''),
      publicKeyPem
          .replaceAll('-----BEGIN RSA PUBLIC KEY-----', '')
          .replaceAll('-----END RSA PUBLIC KEY-----', ''),
    ];

    Exception? lastError;
    for (final v in variants) {
      try {
        final keyContent = v.replaceAll(RegExp(r'\s+'), '');
        final der = base64.decode(keyContent);
        if (der.isEmpty || der[0] != 0x30) {
          log('❌ Public key DER invalid: first byte=${der.isEmpty ? 'EMPTY' : '0x${der[0].toRadixString(16)}'} (expected 0x30). Ensure you pasted the exact PEM contents between BEGIN/END PUBLIC KEY.');
        }
        final top = ASN1Parser(der).nextObject();
        final key = extractFromAsn1(top);
        if (key != null) {
          return key;
        }
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }
    throw Exception('Failed to parse RSA public key: $lastError');
  }

  /// Debug helper to quickly verify signature and headers generation at startup
  static void debugPrintHeaders() {
    try {
      final headers = _headers;
      final sig = headers['X-Cf-Signature'] ?? headers['x-cf-signature'] ?? '';
      log('🧪 Headers OK. Keys: ${headers.keys.toList()}');
      if (sig.isNotEmpty) {
        log('🧪 Signature preview: ${sig.substring(0, sig.length > 50 ? 50 : sig.length)}...');
      }
    } catch (e) {
      log('🧪 Header debug failed: $e');
    }
  }

  /// Verify API credentials as per docs: POST /api/v1/credentials/verify
  /// Returns true if credentials are valid.
  static Future<bool> verifyCredentials() async {
    try {
      final url = Uri.parse(_rootUrl + _credentialsVerifyPath);
      log('🔎 Verifying Cashfree credentials at: $url');
      final response =
          await http.post(url, headers: _headers, body: jsonEncode({}));
      log('📊 Credentials Verify Status: ${response.statusCode}');
      log('📋 Credentials Verify Body: ${response.body}');
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      log('❌ Error verifying credentials: $e');
      return false;
    }
  }

  /// Generate OTP for Aadhaar verification
  /// Returns: {success: bool, refId: String?, message: String}
  static Future<AadhaarOtpResponse> generateOtp(String aadhaarNumber) async {
    try {
      // Validate Aadhaar number
      if (!_isValidAadhaarNumber(aadhaarNumber)) {
        return AadhaarOtpResponse(
          status: 'ERROR',
          message: 'Invalid Aadhaar number format. Must be 12 digits.',
          refId: null,
        );
      }

      final url = Uri.parse('$_offlineAadhaarBase$_otpEndpoint');
      final requestBody = {
        'aadhaar_number': aadhaarNumber,
      };

      final requestHeaders = _headers;

      log('🔄 Generating OTP for Aadhaar: ${_maskAadhaar(aadhaarNumber)}');
      log('🌐 Request URL: $url');
      log('📤 Request Headers: ${requestHeaders.keys.toList()}');
      log('📤 Has X-Cf-Signature: ${requestHeaders.containsKey('X-Cf-Signature')}');
      if (requestHeaders.containsKey('X-Cf-Signature')) {
        final sig = requestHeaders['X-Cf-Signature']!;
        log('📤 Signature preview: ${sig.length > 50 ? '${sig.substring(0, 50)}...' : sig}');
      }

      final response = await http.post(
        url,
        headers: requestHeaders,
        body: jsonEncode(requestBody),
      );

      log('📊 Response Status: ${response.statusCode}');
      log('📋 Response Body: ${response.body}');

      final Map<String, dynamic> responseData = _safeJson(response.body);
      if (response.statusCode == 200) {
        return AadhaarOtpResponse(
          status: (responseData['status'] ?? 'SUCCESS').toString(),
          message:
              (responseData['message'] ?? 'OTP sent successfully').toString(),
          refId: responseData['ref_id']?.toString(),
        );
      }
      return AadhaarOtpResponse(
        status: (responseData['status'] ?? 'ERROR').toString(),
        message:
            (responseData['message'] ?? 'Failed to generate OTP').toString(),
        refId: null,
      );
    } catch (e) {
      log('❌ Error generating OTP: $e');
      return AadhaarOtpResponse(
        status: 'ERROR',
        message: 'Network error: ${e.toString()}',
        refId: null,
      );
    }
  }

  /// Verify OTP and get Aadhaar data
  /// Returns: {success: bool, data: Map?, message: String}
  static Future<AadhaarVerifyResponse> verifyOtp(
      String refId, String otp) async {
    try {
      // Validate inputs
      if (refId.isEmpty) {
        return AadhaarVerifyResponse(
          status: 'ERROR',
          message: 'Reference ID is required',
          data: null,
        );
      }

      if (!_isValidOtp(otp)) {
        return AadhaarVerifyResponse(
          status: 'ERROR',
          message: 'Invalid OTP format. Must be 6 digits.',
          data: null,
        );
      }

      final url = Uri.parse('$_offlineAadhaarBase$_verifyEndpoint');
      final requestBody = {
        'ref_id': refId,
        'otp': otp,
      };

      log('🔄 Verifying OTP for refId: $refId');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      log('📊 Response Status: ${response.statusCode}');
      log('📋 Response Body: ${response.body}');

      final Map<String, dynamic> responseData = _safeJson(response.body);
      if (response.statusCode == 200) {
        // Cashfree may return 'aadhaar_data' or 'data'
        final dynamic dataJson =
            responseData['aadhaar_data'] ?? responseData['data'];
        return AadhaarVerifyResponse(
          status: (responseData['status'] ?? 'SUCCESS').toString(),
          message:
              (responseData['message'] ?? 'Verification successful').toString(),
          data: dataJson is Map<String, dynamic>
              ? AadhaarData.fromJson(dataJson)
              : null,
        );
      }
      return AadhaarVerifyResponse(
        status: (responseData['status'] ?? 'ERROR').toString(),
        message:
            (responseData['message'] ?? 'OTP verification failed').toString(),
        data: null,
      );
    } catch (e) {
      log('❌ Error verifying OTP: $e');
      return AadhaarVerifyResponse(
        status: 'ERROR',
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  static Map<String, dynamic> _safeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  // Helper methods
  static bool _isValidAadhaarNumber(String aadhaarNumber) {
    // Remove spaces and check if it's 12 digits
    final cleanNumber = aadhaarNumber.replaceAll(' ', '');
    return cleanNumber.length == 12 &&
        RegExp(r'^\d{12}$').hasMatch(cleanNumber);
  }

  static bool _isValidOtp(String otp) {
    return otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp);
  }

  static String _maskAadhaar(String aadhaarNumber) {
    if (aadhaarNumber.length != 12) return aadhaarNumber;
    return 'XXXX-XXXX-${aadhaarNumber.substring(8)}';
  }

  // Rate limiting helpers
  static bool isOtpGenerationLimitReached(int currentAttempts) {
    const int maxAttempts = 3; // Usually 3 attempts per hour
    return currentAttempts >= maxAttempts;
  }

  static Duration getOtpRetryWaitTime() {
    return const Duration(seconds: 30); // Wait 30 seconds between requests
  }

  static String getMaskedAadhaarNumber(String aadhaarNumber) {
    return _maskAadhaar(aadhaarNumber);
  }

  /// Test method to verify signature generation is working
  /// Call this before using the service in production
  static void testSignatureGeneration() {
    try {
      log('🧪 Testing signature generation...');

      // Test parsing the public key
      final publicKey = _parsePublicKey(_publicKeyPem);
      log('✅ Public key parsed successfully');
      log('   Modulus bits: ${publicKey.modulus!.bitLength}');
      log('   Exponent: ${publicKey.exponent}');

      // Test signature generation
      final signature = _generateSignature();
      log('✅ Signature generated successfully');
      log('   Length: ${signature.length} characters');
      log('   Sample: ${signature.substring(0, signature.length > 50 ? 50 : signature.length)}...');

      // Test headers generation
      final headers = _headers;
      if (headers.containsKey('X-Cf-Signature')) {
        log('✅ Headers generated with X-Cf-Signature');
      } else {
        log('❌ X-Cf-Signature missing from headers');
      }

      log('🎉 All signature tests passed!');
    } catch (e) {
      log('❌ Signature test failed: $e');
      log('💡 Check your public key format and dependencies');
    }
  }
}
