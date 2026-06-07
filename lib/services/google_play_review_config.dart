// ============================================================
// GOOGLE PLAY REVIEW LOGIN — Configuration & Detection Service
// ============================================================
// This file is the single source of truth for the Google Play
// review-account bypass. Set [googlePlayReviewMode] to false
// and delete this file after your app is approved.
// ============================================================

import 'package:flutter/foundation.dart';

class GooglePlayReviewConfig {
  // ----------------------------------------------------------
  // FEATURE FLAG — set to false to fully disable bypass after approval
  // ----------------------------------------------------------
  /// GOOGLE PLAY REVIEW LOGIN: Master on/off switch.
  /// Set this to false once your app is approved by Google Play.
  static const bool googlePlayReviewMode = true;

  // ----------------------------------------------------------
  // Review account credentials (NEVER use real user numbers here)
  // ----------------------------------------------------------

  /// GOOGLE PLAY REVIEW LOGIN: The dedicated review phone number (digits only, no country code).
  static const String reviewPhoneNumber = '9999999999';

  /// GOOGLE PLAY REVIEW LOGIN: The country code for the review account.
  static const String reviewCountryCode = '+91';

  /// GOOGLE PLAY REVIEW LOGIN: The full E.164 number for display/matching.
  static const String reviewFullNumber = '+919999999999';

  /// GOOGLE PLAY REVIEW LOGIN: The static OTP the reviewer must enter.
  static const String reviewOtp = '123456';

  /// GOOGLE PLAY REVIEW LOGIN: Stable user ID for the review account in Firestore.
  /// This prevents a new document being created on every review session.
  static const String reviewUserId = 'google_play_review_account_v1';

  // ----------------------------------------------------------
  // Detection helpers
  // ----------------------------------------------------------

  /// Returns true ONLY when review mode is enabled AND the supplied
  /// phone number matches the exact review credentials.
  ///
  /// The check is intentionally strict (both feature flag AND number must match)
  /// so that a misconfiguration can never silently bypass real users.
  static bool isReviewNumber({
    required String countryCode,
    required String phoneNumber,
  }) {
    if (!googlePlayReviewMode) return false;

    // Normalise inputs before comparison
    final cleanCountry = countryCode.trim();
    final cleanPhone = phoneNumber.trim().replaceAll(RegExp(r'\D'), '');

    final match =
        cleanCountry == reviewCountryCode && cleanPhone == reviewPhoneNumber;

    if (match) {
      debugPrint(
        '🔍 [GOOGLE PLAY REVIEW LOGIN] Review number detected. '
        'Review mode is ACTIVE.',
      );
    }
    return match;
  }

  /// Verifies the OTP entered by the reviewer.
  static bool isReviewOtp(String enteredOtp) {
    if (!googlePlayReviewMode) return false;
    final match = enteredOtp.trim() == reviewOtp;
    if (match) {
      debugPrint(
        '✅ [GOOGLE PLAY REVIEW LOGIN] Correct review OTP entered. '
        'Authenticating reviewer.',
      );
    } else {
      debugPrint(
        '❌ [GOOGLE PLAY REVIEW LOGIN] Wrong OTP entered by reviewer: '
        '"$enteredOtp"',
      );
    }
    return match;
  }
}
