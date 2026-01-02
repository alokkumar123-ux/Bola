import 'dart:convert';
import 'dart:io' show Platform;

import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/splash_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/controller/global_setting_controller.dart';
import 'package:poolmate/firebase_options.dart';
import 'package:poolmate/model/language_model.dart';
import 'package:poolmate/services/aadhaar_verification_service.dart';
import 'package:poolmate/services/localization_service.dart';
import 'package:poolmate/themes/styles.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:poolmate/utils/preferences.dart';
import 'package:poolmate/services/sos_audio_service.dart';
import 'package:poolmate/utils/notification_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web-specific initialization
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Skip Firebase App Check for web during development
    // await FirebaseAppCheck.instance.activate(
    //   webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    // );
  } else {
    if (Platform.isIOS) {
      await Firebase.initializeApp(
        name: "PoolMate",
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Wrap App Check in try-catch - PlayIntegrity can fail on some devices
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
    } catch (e) {
      print('Firebase App Check failed to initialize: $e');
      // Continue without App Check - better than black screen
    }
  }

  // Wrap Preferences init in try-catch
  try {
    await Preferences.initPref();
  } catch (e) {
    print('Preferences init failed: $e');
  }

  if (!kIsWeb) {
    // Initialize Awesome Notifications for mobile platforms
    try {
      await AwesomeNotifications().initialize(
        null, // Use default app icon
        [
          NotificationChannel(
            channelKey: 'default',
            channelName: 'Default Notifications',
            channelDescription: 'Default notification channel',
            defaultColor: const Color(0xFF060606),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            playSound: true,
          ),
          // This channel matches FCM's channel_id for regular notifications
          NotificationChannel(
            channelKey: 'high_importance_channel',
            channelName: 'High Importance',
            channelDescription: 'High importance notifications',
            defaultColor: const Color(0xFF060606),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            playSound: true,
          ),
          NotificationChannel(
            channelGroupKey: 'sos_channel_group',
            channelKey: 'sos_channel',
            channelName: 'SOS Alerts',
            channelDescription: 'Notification channel for SOS emergency alerts',
            defaultColor: const Color(0xFFFF0000),
            ledColor: Colors.red,
            importance: NotificationImportance.Max,
            criticalAlerts: true,
            playSound: false, // suppress channel sound; we play alarm ourselves
            enableVibration: true,
          ),
          NotificationChannel(
            channelKey: 'ride_alert_channel',
            channelName: 'Ride Alerts',
            channelDescription:
                'Notifications for new rides matching your search',
            defaultColor: const Color(0xFF060606),
            ledColor: Colors.blue,
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
          ),
        ],
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: 'sos_channel_group',
            channelGroupName: 'SOS Group',
          ),
        ],
        debug: false, // Set to false for production!
      );
    } catch (e) {
      print('Awesome Notifications failed to initialize: $e');
    }

    // Request notification permissions if not already granted
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  // Configure Cashfree credentials before any Aadhaar API usage
  AadhaarVerificationService.configure(
    clientId: Constant.cashfreeClientId,
    clientSecret: Constant.cashfreeClientSecret,
    publicKeyPem: Constant.cashfreePublicKey,
    useSandbox: Constant.useCashfreeSandbox,
    // Set to false if you have whitelisted your server/device IP in Cashfree
    useSignature: false,
  );
  // Debug once at startup to confirm signature and headers generation
  AadhaarVerificationService.debugPrintHeaders();
  // Optional: self-test logging
  // AadhaarVerificationService.testSignatureGeneration();

  // Initialize SOS Audio Service
  if (!kIsWeb) {
    Get.put(SosAudioService(), permanent: true);

    // Register Firebase background message handler BEFORE runApp
    // This is critical for receiving messages when app is killed/background
    FirebaseMessaging.onBackgroundMessage(firebaseMessageBackgroundHandle);

    // Set up Awesome Notifications listeners for background/foreground
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: awesomeOnActionReceivedMethod,
      onNotificationCreatedMethod: awesomeOnNotificationCreatedMethod,
      onNotificationDisplayedMethod: awesomeOnNotificationDisplayedMethod,
      onDismissActionReceivedMethod: awesomeOnDismissActionReceivedMethod,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  @override
  void initState() {
    getCurrentAppTheme();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Preferences.getString(Preferences.languageCodeKey)
          .toString()
          .isNotEmpty) {
        LanguageModel languageModel = Constant.getLanguage();
        LocalizationService().changeLocale(languageModel.code.toString());
      } else {
        LanguageModel languageModel =
            LanguageModel(id: "cdc", code: "en", isRtl: false, name: "English");
        Preferences.setString(
            Preferences.languageCodeKey, jsonEncode(languageModel.toJson()));
      }
    });
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        return themeChangeProvider;
      },
      child: Consumer<DarkThemeProvider>(
        builder: (context, value, child) {
          return GetMaterialApp(
            title: 'Bola'.tr,
            debugShowCheckedModeBanner: false,
            theme: Styles.themeData(
                themeChangeProvider.darkTheme == 0
                    ? true
                    : themeChangeProvider.darkTheme == 1
                        ? false
                        : themeChangeProvider.getSystemThem(),
                context),
            localizationsDelegates: const [
              CountryLocalizations.delegate,
            ],
            locale: LocalizationService.locale,
            fallbackLocale: LocalizationService.locale,
            translations: LocalizationService(),
            builder: EasyLoading.init(),
            home: GetBuilder<GlobalSettingController>(
              init: GlobalSettingController(),
              builder: (context) {
                return const SplashScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
