# Quick Start: Android NDK Setup on macOS

Your build failed because **Android NDK is not installed**. Follow these steps:

## Step 1: Install Android Studio (if not already done)

1. Download from: https://developer.android.com/studio
2. Run the installer
3. Follow the setup wizard (accept defaults)

## Step 2: Install Android NDK via Android Studio

After Android Studio is installed and running:

### Option A: Using Android Studio UI (Easiest)

1. Open **Android Studio**
2. Click menu: **Android Studio** → **Preferences** (or **Settings** on Windows/Linux)
3. Navigate to: **Languages & Frameworks** → **Android SDK**
4. Click the **SDK Tools** tab
5. Check the box for **NDK (Side by side)**
6. Click **Apply** and wait for installation (5-10 minutes)

### Option B: Using Command Line (Faster)

If you have Android SDK Command-line Tools installed:

```bash
# Find your Android SDK location
ls ~/Library/Android/sdk/

# Install NDK (choose one version)
~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager "ndk;27.0.12077973"
```

## Step 3: Verify NDK Installation

```bash
ls ~/Library/Android/sdk/ndk/
```

You should see output like:
```
25.2.9519653
27.0.12077973
```

## Step 4: Build libwhisper_bridge.so

Once NDK is installed, from the project root:

```bash
# Set the NDK path (use your installed version)
export ANDROID_NDK_ROOT="$HOME/Library/Android/sdk/ndk/27.0.12077973"

# Verify it's set
echo $ANDROID_NDK_ROOT

# Create build directory
mkdir -p native/build_android
cd native/build_android

# Run CMake with Android toolchain
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE=Release

# Compile (takes 5-10 minutes first time)
make -j$(sysctl -n hw.ncpu)

# Verify build
ls -lh libwhisper_bridge.so
```

You should see output like:
```
-rw-r--r--  1 user  group  5.2M Feb 24 10:30 libwhisper_bridge.so
```

## Step 5: Copy Library to APK

From the project root:

```bash
# Create the jniLibs directory structure
mkdir -p app/android/app/src/main/jniLibs/arm64-v8a

# Copy the compiled library
cp native/build_android/libwhisper_bridge.so \
   app/android/app/src/main/jniLibs/arm64-v8a/libwhisper_bridge.so

# Verify
ls -lh app/android/app/src/main/jniLibs/arm64-v8a/libwhisper_bridge.so
```

## Step 6: Build APK

From the `app/` directory:

```bash
cd app

# Clean old builds
flutter clean

# Build APK
flutter build apk --debug

# Build is complete at:
# app/build/app/outputs/apk/debug/app-debug.apk
```

## Step 7: Install and Test

```bash
cd ..  # Back to project root

# List devices
adb devices

# Install APK
adb install app/build/app/outputs/apk/debug/app-debug.apk

# Or use flutter
cd app
flutter run -d <device-id>
```

## Troubleshooting

### CMake error: "toolchain.cmake not found"
- **Cause:** NDK path is wrong or not installed
- **Fix:**
  ```bash
  # Verify NDK path
  ls $ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake

  # If not found, check installed versions
  ls ~/Library/Android/sdk/ndk/
  ```

### Error: "android-ndk-r25..." command not found
- **Cause:** Wrong NDK version or install incomplete
- **Fix:** Reinstall NDK from Android Studio > SDK Tools

### "libwhisper_bridge.so" file not found during copy
- **Cause:** Build didn't complete successfully
- **Fix:** Check CMake output above for errors, especially:
  - "whisper.cpp not found" → Run: `git submodule update --init`
  - CMake configuration errors → Check NDK path

### Android device not recognized
- **Cause:** USB debugging not enabled
- **Fix:**
  1. On Android device: Settings → Developer options → USB debugging
  2. Plug in via USB
  3. On Mac: `adb devices` should show your device

## I'm Stuck!

If you hit issues:

1. **Check detailed build output:**
   ```bash
   cd native/build_android
   cmake --build . --verbose
   ```

2. **Check device compatibility:**
   ```bash
   adb shell getprop ro.product.cpu.abi
   # Should show: arm64-v8a (for modern phones)
   ```

3. **Clean everything and retry:**
   ```bash
   cd native
   rm -rf build_android
   # Then start from "Create build directory" in Step 4
   ```

4. **See the full ANDROID_BUILD.md** for more details and options
