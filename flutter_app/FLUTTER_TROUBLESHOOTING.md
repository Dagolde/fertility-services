# Flutter Android v1 Embedding Fix Guide

## Issue: "Build failed due to use of deleted Android v1 embedding"

This error occurs when Flutter tries to use the deprecated v1 embedding instead of the newer v2 embedding. Here's how to fix it:

## Quick Fix Steps

### 1. Run the Fix Script
```bash
cd flutter_app
fix_flutter_build.bat
```

### 2. Manual Fix Steps

#### Step 1: Clean Everything
```bash
flutter clean
flutter pub get
```

#### Step 2: Remove Build Directories
```bash
# Remove all build artifacts
rm -rf build/
rm -rf android/.gradle/
rm -rf android/app/build/
rm -rf android/build/
```

#### Step 3: Update Flutter
```bash
flutter upgrade
flutter doctor
```

#### Step 4: Check Android Configuration

**Verify MainActivity.kt uses v2 embedding:**
```kotlin
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    // v2 embedding code
}
```

**Verify AndroidManifest.xml has correct meta-data:**
```xml
<meta-data
    android:name="io.flutter.embedding.android.NormalTheme"
    android:resource="@style/NormalTheme" />
```

#### Step 5: Check Dependencies
Make sure pubspec.yaml doesn't have conflicting Firebase dependencies without proper Android configuration.

## Common Causes and Solutions

### 1. Firebase Dependencies Mismatch
**Problem:** Firebase dependencies in pubspec.yaml but no Firebase configuration in Android
**Solution:** Either remove Firebase dependencies or add proper Firebase configuration

### 2. Outdated Flutter Version
**Problem:** Using old Flutter version with v1 embedding
**Solution:** 
```bash
flutter upgrade
flutter doctor
```

### 3. Corrupted Build Cache
**Problem:** Old build artifacts causing conflicts
**Solution:**
```bash
flutter clean
flutter pub cache clean
flutter pub get
```

### 4. Android Gradle Issues
**Problem:** Gradle version conflicts
**Solution:** Update android/build.gradle:
```gradle
dependencies {
    classpath 'com.android.tools.build:gradle:7.3.0'
    classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.10"
}
```

### 5. Missing Android Resources
**Problem:** Missing required Android resource files
**Solution:** Ensure these files exist:
- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/drawable/launch_background.xml`
- All launcher icons in mipmap directories

## Verification Steps

### 1. Check Flutter Doctor
```bash
flutter doctor -v
```
Ensure all checkmarks are green, especially:
- Flutter SDK
- Android toolchain
- Android Studio

### 2. Test Build
```bash
flutter build apk --debug
```

### 3. Test Run
```bash
flutter run
```

## Advanced Troubleshooting

### If Error Persists:

#### 1. Create New Flutter Project and Compare
```bash
flutter create test_app
# Compare android/ folder structure
```

#### 2. Check Plugin Compatibility
Some plugins might still use v1 embedding. Check plugin documentation for v2 embedding support.

#### 3. Gradle Wrapper Issues
Update `android/gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-7.5-all.zip
```

#### 4. Android SDK Issues
Ensure you have:
- Android SDK 33 or higher
- Android Build Tools 33.0.0 or higher
- Android Platform Tools

### Environment Variables
Make sure these are set correctly:
```bash
ANDROID_HOME=C:\Users\[USERNAME]\AppData\Local\Android\Sdk
JAVA_HOME=C:\Program Files\Android\Android Studio\jre
```

## Files Modified to Fix v1 Embedding

### 1. pubspec.yaml
- Removed Firebase dependencies that weren't properly configured

### 2. android/app/build.gradle
- Updated to use explicit SDK versions
- Removed Firebase dependencies
- Simplified configuration

### 3. android/build.gradle
- Removed Firebase classpath dependencies

### 4. AndroidManifest.xml
- Removed Firebase service references
- Simplified configuration
- Kept v2 embedding meta-data

### 5. MainActivity.kt
- Already using v2 embedding (FlutterActivity)
- No changes needed

## Prevention

To avoid this issue in the future:

1. **Always use latest Flutter version**
2. **Don't mix v1 and v2 embedding configurations**
3. **Properly configure all dependencies**
4. **Test builds regularly during development**
5. **Keep Android SDK and tools updated**

## Success Indicators

You'll know the fix worked when:
- `flutter doctor` shows no issues
- `flutter build apk --debug` completes successfully
- `flutter run` launches the app without errors
- No v1 embedding warnings in console

## Additional Resources

- [Flutter Android Embedding v2](https://docs.flutter.dev/development/platform-integration/android/android-embedding)
- [Flutter Upgrade Guide](https://docs.flutter.dev/development/tools/sdk/upgrading)
- [Android Studio Setup](https://docs.flutter.dev/get-started/install/windows#android-setup)
