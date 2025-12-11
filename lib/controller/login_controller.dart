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
import 'package:poolmate/utils/fire_store_utils.dart';
import 'package:poolmate/utils/notification_service.dart';
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

    // Check if user exists in Firebase before sending OTP
    bool userExists = await FireStoreUtils.userExistByPhoneNumber(
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
          await FireStoreUtils.userExistOrNot(value.user!.uid)
              .then((userExit) async {
            ShowToastDialog.closeLoader();
            if (userExit == true) {
              UserModel? userModel =
                  await FireStoreUtils.getUserProfile(value.user!.uid);
              if (userModel != null) {
                if (userModel.isActive == true) {
                  // Save user ID to local storage
                  await FireStoreUtils.setCurrentUid(userModel.id!);

                  // Update FCM token for existing user on login with error handling
                  try {
                    String fcmToken = await NotificationService.getToken();
                    userModel.fcmToken = fcmToken;
                    await FireStoreUtils.updateUser(userModel);
                    debugPrint(
                        "FCM token updated for existing user: $fcmToken");
                  } catch (e) {
                    debugPrint(
                        "Failed to update FCM token for existing user: $e");
                    // Continue with login even if FCM token update fails
                  }

                  Get.offAll(const DashBoardScreen());
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
          FireStoreUtils.userExistOrNot(userCredential.user!.uid)
              .then((userExit) async {
            ShowToastDialog.closeLoader();

            if (userExit == true) {
              UserModel? userModel =
                  await FireStoreUtils.getUserProfile(userCredential.user!.uid);
              if (userModel != null) {
                if (userModel.isActive == true) {
                  // Save user ID to local storage
                  await FireStoreUtils.setCurrentUid(userModel.id!);

                  // Update FCM token for existing user on Apple login with error handling
                  try {
                    String fcmToken = await NotificationService.getToken();
                    userModel.fcmToken = fcmToken;
                    await FireStoreUtils.updateUser(userModel);
                    debugPrint(
                        "FCM token updated for existing Apple user: $fcmToken");
                  } catch (e) {
                    debugPrint(
                        "Failed to update FCM token for existing Apple user: $e");
                    // Continue with login even if FCM token update fails
                  }

                  Get.offAll(const DashBoardScreen());
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
        final GoogleSignInAuthentication? googleAuth =
            await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
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
