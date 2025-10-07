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
