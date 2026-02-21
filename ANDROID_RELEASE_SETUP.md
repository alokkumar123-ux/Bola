# Android Release Build Setup Guide

## The Problem
Your release build was failing with a NullPointerException because the signing configuration was incomplete or missing.

## What I Fixed
1. Created a `key.properties` template file
2. Updated `build.gradle` to handle missing signing configurations gracefully
3. The app will now build without crashing, but you need to configure signing for production releases

## To Create a Production Release, Follow These Steps:

### Option 1: Generate a New Keystore (First Time Setup)

Run this command in PowerShell from the `z:\Bola\android` directory:

```powershell
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted for:
- Keystore password (choose a strong password)
- Key password (can be the same as keystore password)
- Your name, organization, city, state, country

This creates a file called `upload-keystore.jks` in the android directory.

### Option 2: Use an Existing Keystore

If you already have a keystore file (`.jks` or `.keystore`), place it in the `android` directory.

### Step 2: Update key.properties

Edit `z:\Bola\android\key.properties` with your actual values:

```properties
storePassword=YOUR_ACTUAL_STORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

**Important Security Notes:**
- ✅ `key.properties` is already in `.gitignore` - it won't be committed
- ✅ Keep your keystore file safe - you can't recover it if lost
- ✅ Never share your passwords or keystore publicly
- ✅ Back up your keystore file securely

### Step 3: Build Release

After configuring the keystore, you can build a release:

```powershell
# For APK
flutter build apk --release

# For App Bundle (recommended for Play Store)
flutter build appbundle --release
```

## For Testing Without Signing

If you just want to test and don't need a signed release:

```powershell
# Build debug version
flutter build apk --debug

# Or run directly on device
flutter run
```

## Troubleshooting

### If you see "keytool is not recognized"
You need Java JDK installed. The keytool comes with Java.

### If build still fails
1. Verify all values in `key.properties` are correct
2. Check that the `storeFile` path points to your actual keystore file
3. Ensure passwords match what you set when creating the keystore

### Lost your keystore?
- For existing Play Store apps: You cannot update the app without the original keystore
- For new apps: Generate a new keystore and use it for all future releases
