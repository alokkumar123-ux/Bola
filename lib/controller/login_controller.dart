import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:poolmate/app/auth_screen/information_screen.dart';
import 'package:poolmate/app/auth_screen/otp_screen.dart';
import 'package:poolmate/app/dashboard_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/services/whatsapp_auth_service.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/services/fcm_token_manager.dart';
import 'package:poolmate/services/deep_link_service.dart';
// GOOGLE PLAY REVIEW LOGIN
import 'package:poolmate/services/google_play_review_config.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginController extends GetxController {
  Rx<TextEditingController> phoneNumber = TextEditingController().obs;
  Rx<TextEditingController> countryCodeController =
      TextEditingController(text: "+91").obs;

  RxBool isLogin = false.obs;

  @override
  void onInit() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      isLogin.value = argumentData['isLogin'];
    }
    super.onInit();
  }

  /// Send OTP via WhatsApp Authentication
  sendCode() async {
    ShowToastDialog.showLoader("please wait...".tr);

    // -------------------------------------------------------
    // GOOGLE PLAY REVIEW LOGIN: Intercept the review number.
    // If this is the dedicated review account, skip WhatsApp
    // entirely and navigate directly to OTP screen.
    // -------------------------------------------------------
    if (GooglePlayReviewConfig.isReviewNumber(
      countryCode: countryCodeController.value.text,
      phoneNumber: phoneNumber.value.text,
    )) {
      debugPrint(
        '[GOOGLE PLAY REVIEW LOGIN] Review number detected in sendCode(). '
        'Skipping WhatsApp OTP — navigating directly to OTP screen.',
      );
      ShowToastDialog.closeLoader();

      // Navigate to OTP screen with the static review OTP pre-stored.
      // The 'isReviewMode' flag tells OtpController to use bypass auth.
      Get.to(const OtpScreen(), arguments: {
        'countryCode': countryCodeController.value.text,
        'phoneNumber': phoneNumber.value.text,
        'otp': GooglePlayReviewConfig.reviewOtp,
        'isLogin': true,         // reviewer is always treated as an existing user
        'isReviewMode': true,    // GOOGLE PLAY REVIEW LOGIN flag
      });
      return; // <-- early return: WhatsApp is never called
    }
    // -------------------------------------------------------
    // Normal flow continues below for all real users
    // -------------------------------------------------------

    // Check if user exists in Firebase before sending OTP
    bool userExists = await AuthUtils.userExistByPhoneNumber(
      countryCodeController.value.text,
      phoneNumber.value.text,
    );

    // If isLogin is true (user wants to login) but user doesn't exist, show error
    if (isLogin.value && !userExists) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Account not found. Please sign up first.".tr);
      return;
    }

    // If isLogin is false (user wants to sign up) but user already exists, show error
    if (!isLogin.value && userExists) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
          "Account already exists. Please login instead.".tr);
      return;
    }

    // Generate OTP
    String otp = WhatsAppAuthService.generateOTP();

    // Send OTP via WhatsApp
    final result = await WhatsAppAuthService.sendOTP(
      countryCode: countryCodeController.value.text,
      phoneNumber: phoneNumber.value.text,
      otp: otp,
    );

    ShowToastDialog.closeLoader();

    if (result['success'] == true) {
      // Navigate to OTP screen with the generated OTP for local verification
      Get.to(const OtpScreen(), arguments: {
        "countryCode": countryCodeController.value.text,
        "phoneNumber": phoneNumber.value.text,
        "otp": otp, // Pass OTP for local verification
        "isLogin": isLogin.value, // Pass login/signup state
      });
    } else {
      ShowToastDialog.showToast(result['message'] ?? "Failed to send OTP".tr);
    }
  }

  loginWithGoogle() async {
    ShowToastDialog.showLoader("please wait...".tr);
    await signInWithGoogle().then((value) async {
      ShowToastDialog.closeLoader();
      if (value != null) {
        if (value.additionalUserInfo!.isNewUser) {
          UserModel userModel = UserModel();
          userModel.id = value.user!.uid;
          userModel.email = value.user!.email;
          userModel.firstName = value.user!.displayName;
          userModel.profilePic = value.user!.photoURL;
          userModel.loginType = Constant.googleLoginType;

          ShowToastDialog.closeLoader();
          Get.to(const InformationScreen(), arguments: {
            "userModel": userModel,
          });
        } else {
          await AuthUtils.userExistOrNot(value.user!.uid)
              .then((userExit) async {
            ShowToastDialog.closeLoader();
            if (userExit == true) {
              UserModel? userModel =
                  await UserUtils.getUserProfile(value.user!.uid);
              if (userModel != null) {
                if (userModel.isActive == true) {
                  // Save user ID to local storage
                  await AuthUtils.setCurrentUid(userModel.id!);

                  // Initialize FCM token manager and save token
                  try {
                    await FcmTokenManager.saveCurrentToken();
                    debugPrint("FCM token saved for existing user");
                  } catch (e) {
                    debugPrint("Failed to save FCM token: $e");
                    // Continue with login even if FCM token update fails
                  }

                  Get.offAll(const DashBoardScreen());
                  // Handle pending deep link after Google login
                  await DeepLinkService.handlePendingLink();
                } else {
                  await FirebaseAuth.instance.signOut();
                  ShowToastDialog.showToast(
                      "This user is disable please contact administrator".tr);
                }
              }
            } else {
              UserModel userModel = UserModel();
              userModel.id = value.user!.uid;
              userModel.email = value.user!.email;
              userModel.firstName = value.user!.displayName;
              userModel.profilePic = value.user!.photoURL;
              userModel.loginType = Constant.googleLoginType;

              Get.to(const InformationScreen(), arguments: {
                "userModel": userModel,
              });
            }
          });
        }
      }
    });
  }

  loginWithApple() async {
    ShowToastDialog.showLoader("please wait...".tr);
    await signInWithApple().then((value) {
      ShowToastDialog.closeLoader();
      print(value);
      if (value != null) {
        Map<String, dynamic> map = value;
        AuthorizationCredentialAppleID appleCredential = map['appleCredential'];
        UserCredential userCredential = map['userCredential'];
        if (userCredential.additionalUserInfo!.isNewUser) {
          UserModel userModel = UserModel();
          userModel.id = userCredential.user!.uid;
          userModel.email = appleCredential.email ?? userCredential.user?.email;
          userModel.firstName = appleCredential.givenName;
          userModel.lastName = appleCredential.familyName;
          userModel.profilePic = "";
          userModel.loginType = Constant.appleLoginType;

          ShowToastDialog.closeLoader();
          Get.to(const InformationScreen(), arguments: {
            "userModel": userModel,
          });
        } else {
          AuthUtils.userExistOrNot(userCredential.user!.uid)
              .then((userExit) async {
            ShowToastDialog.closeLoader();

            if (userExit == true) {
              UserModel? userModel =
                  await UserUtils.getUserProfile(userCredential.user!.uid);
              if (userModel != null) {
                if (userModel.isActive == true) {
                  // Save user ID to local storage
                  await AuthUtils.setCurrentUid(userModel.id!);

                  // Initialize FCM token manager and save token
                  try {
                    await FcmTokenManager.saveCurrentToken();
                    debugPrint("FCM token saved for existing Apple user");
                  } catch (e) {
                    debugPrint("Failed to save FCM token: $e");
                    // Continue with login even if FCM token update fails
                  }

                  Get.offAll(const DashBoardScreen());
                  // Handle pending deep link after Apple login
                  await DeepLinkService.handlePendingLink();
                } else {
                  await FirebaseAuth.instance.signOut();
                  ShowToastDialog.showToast(
                      "This user is disable please contact administrator".tr);
                }
              }
            } else {
              UserModel userModel = UserModel();
              userModel.id = userCredential.user!.uid;
              userModel.profilePic = "";
              userModel.email =
                  appleCredential.email ?? userCredential.user?.email;
              userModel.firstName = appleCredential.givenName;
              userModel.lastName = appleCredential.familyName;
              userModel.loginType = Constant.googleLoginType;

              Get.to(const InformationScreen(), arguments: {
                "userModel": userModel,
              });
            }
          });
        }
      }
    });
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // For web platform
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        // Sign in using popup for web
        return await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // For mobile platforms
        final GoogleSignInAccount? googleUser =
            await GoogleSignIn().signIn().catchError((error) {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("something_went_wrong".tr);
          return null;
        });

        if (googleUser == null) return null;

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Once signed in, return the UserCredential
        return await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
    // Trigger the authentication flow
  }

  Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);
      // Request credential for the currently signed in Apple account.
      AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        // webAuthenticationOptions: WebAuthenticationOptions(clientId: clientID, redirectUri: Uri.parse(redirectURL)),
      );
      print(appleCredential);

      // Create an `OAuthCredential` from the credential returned by Apple.
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      // Sign in the user with Firebase. If the nonce we generated earlier does
      // not match the nonce in `appleCredential.identityToken`, sign in will fail.
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      return {
        "appleCredential": appleCredential,
        "userCredential": userCredential
      };
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
