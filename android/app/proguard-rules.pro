##############################################
# Flutter core
##############################################
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

##############################################
# Stripe SDK
##############################################
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**
-keep class com.stripe.android.pushProvisioning.** { *; }

##############################################
# Razorpay SDK
##############################################
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

##############################################
# PayPal SDK
##############################################
-keep class com.paypal.** { *; }
-dontwarn com.paypal.**
-keep class com.braintreepayments.api.** { *; }
-dontwarn com.braintreepayments.api.**

##############################################
# Paystack SDK
##############################################
-keep class co.paystack.android.** { *; }
-dontwarn co.paystack.android.**

##############################################
# Mercado Pago SDK
##############################################
-keep class com.mercadopago.** { *; }
-dontwarn com.mercadopago.**

##############################################
# Flutterwave SDK
##############################################
-keep class com.flutterwave.** { *; }
-dontwarn com.flutterwave.**

##############################################
# PayFast SDK
##############################################
-keep class za.co.payfast.** { *; }
-dontwarn za.co.payfast.**

##############################################
# Paytm SDK
##############################################
-keep class com.paytm.** { *; }
-dontwarn com.paytm.**
-keep class net.one97.paytm.** { *; }
-dontwarn net.one97.paytm.**

##############################################
# Xendit SDK
##############################################
-keep class com.xendit.** { *; }
-dontwarn com.xendit.**

##############################################
# OrangePay SDK
##############################################
-keep class com.orangepay.** { *; }
-dontwarn com.orangepay.**

##############################################
# Midtrans SDK
##############################################
-keep class com.midtrans.** { *; }
-dontwarn com.midtrans.**

##############################################
# ProGuard Annotations
##############################################
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }

##############################################
# Gson / JSON libraries (often used by payment SDKs)
##############################################
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

##############################################
# OkHttp / Retrofit (networking, used by many SDKs)
##############################################
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**

##############################################
# Google Play Core (Fix for R8 missing classes)
##############################################
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

##############################################
# Firebase
##############################################
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

##############################################
# Cashfree SDK
##############################################
-keep class com.cashfree.** { *; }
-dontwarn com.cashfree.**

##############################################
# GetX (Flutter State Management)
##############################################
-keep class get.** { *; }
-dontwarn get.**

##############################################
# Awesome Notifications
##############################################
-keep class me.carda.awesome_notifications.** { *; }
-dontwarn me.carda.awesome_notifications.**

##############################################
# Google Maps
##############################################
-keep class com.google.android.libraries.maps.** { *; }
-dontwarn com.google.android.libraries.maps.**

##############################################
# Flutter InAppWebView
##############################################
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

##############################################
# Keep all model classes (Firestore/JSON serialization)
##############################################
-keep class com.alok.poolmate.model.** { *; }

##############################################
# Prevent R8 from stripping native methods
##############################################
-keepclasseswithmembernames class * {
    native <methods>;
}

##############################################
# Keep annotations
##############################################
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions
