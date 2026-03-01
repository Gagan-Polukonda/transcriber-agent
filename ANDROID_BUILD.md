# Android Build Guide for Voice-to-Text Transcriber

## Problem
The Flutter app crashes on Android with: `Failed to load dynamic library 'libwhisper_bridge.so'`

This is because the native C++ library hasn't been compiled for ARM64 Android.

## Prerequisites

1. **Android NDK** installed via Android Studio
2. **CMake** (already installed on macOS)
3. **Android SDK** (comes with Android Studio)

### Install Android NDK (if not already installed)

1. Open **Android Studio**
2. Go to **Settings** → **Languages & Frameworks** → **Android SDK**
3. Click the **SDK Tools** tab
4. Check **NDK (Side by side)** and click **OK**
5. Wait for installation to complete

**Verify NDK installation:**
```bash
ls ~/Library/Android/sdk/ndk/
# You should see version folders like: 25.2.9519653, 27.0.12077973, etc.
```

## Step 1: Build whisper_bridge.so for ARM64

From the **project root** (`/Users/gagan/GIT\ repositories/transcriber-agent/`), run:

```bash
# Set NDK environment variable (replace version with your installed NDK version)
export ANDROID_NDK_ROOT="$HOME/Library/Android/sdk/ndk/27.0.12077973"
# or if you have a different version:
# export ANDROID_NDK_ROOT="$HOME/Library/Android/sdk/ndk/25.2.9519653"

# Create build directory
mkdir -p native/build_android
cd native/build_android

# Run CMake with Android NDK toolchain
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE=Release

# Build
make -j$(nproc)

# Check output
ls -lh libwhisper_bridge.so
```

**Expected output:**
```
-rw-r--r--  1 user  group  5.2M Feb 24 10:30 libwhisper_bridge.so
```

## Step 2: Copy the Library to the APK Build Directory

From the project root:

```bash
# Create the jniLibs directory structure
mkdir -p app/android/app/src/main/jniLibs/arm64-v8a

# Copy the compiled library
cp native/build_android/libwhisper_bridge.so \
   app/android/app/src/main/jniLibs/arm64-v8a/libwhisper_bridge.so

# Verify it's there
ls -lh app/android/app/src/main/jniLibs/arm64-v8a/libwhisper_bridge.so
```

## Step 3: Rebuild the APK

From the `app/` directory:

```bash
cd app

# Build a debug APK for testing
flutter build apk --debug

# OR: Build a release APK (smaller, optimized)
flutter build apk --release
```

**Output location:**
- Debug: `app/build/app/outputs/apk/debug/app-debug.apk`
- Release: `app/build/app/outputs/apk/release/app-release.apk`

## Step 4: Install and Test

### Option A: Using Flutter Run (Easiest)

```bash
cd app

# List connected devices
flutter devices

# Run on a specific device (replace with your device ID)
flutter run -d <device-id>
```

### Option B: Manual APK Installation

```bash
# List connected devices
adb devices

# Install the APK
adb install app/build/app/outputs/apk/debug/app-debug.apk

# Or force reinstall if already installed
adb install -r app/build/app/outputs/apk/debug/app-debug.apk
```

## Step 5: Push Whisper Model to Device

The app needs the Whisper model file (140 MB). Push it to the device:

```bash
# First, verify the model file exists
ls -lh models/ggml-base.bin

# Push to device
adb push models/ggml-base.bin \
    /sdcard/Android/data/com.example.voice_to_text_local/files/ggml-base.bin

# Or push to a simpler location
adb push models/ggml-base.bin /sdcard/Download/ggml-base.bin
```

**Note:** If the app-specific directory doesn't exist, create it:
```bash
adb shell mkdir -p /sdcard/Android/data/com.example.voice_to_text_local/files/
```

## Step 6: Test the App

1. Open the app on your Android device
2. You should see the recording UI
3. Tap the record button
4. Speak for a few seconds
5. Tap stop — the app should transcribe the audio

**Expected behavior:**
- ✅ No crash about `libwhisper_bridge.so` not found
- ✅ Microphone permission prompt appears
- ✅ Recording works
- ✅ Text appears after transcription

## Troubleshooting

### Error: "libwhisper_bridge.so not found"
- **Cause:** Library not copied to jniLibs directory
- **Fix:** Verify step 2 was completed:
  ```bash
  ls -lh app/android/app/src/main/jniLibs/arm64-v8a/libwhisper_bridge.so
  ```

### Error: "Model file not found"
- **Cause:** Whisper model (.bin file) not on device
- **Fix:** Push the model using adb (Step 5)

### Build fails with "whisper.cpp not found"
- **Cause:** whisper.cpp submodule not initialized
- **Fix:**
  ```bash
  git submodule update --init --recursive
  ```

### CMake error: "Android toolchain not found"
- **Cause:** `ANDROID_NDK_ROOT` not set or wrong path
- **Fix:** Verify NDK is installed and set the correct path

### App crashes on launch
- **Check logcat:**
  ```bash
  adb logcat | grep -i whisper
  # or
  flutter logs
  ```

## Building for Multiple ABIs

To support x86_64 and ARM v7 as well, build multiple times:

```bash
# ARM64 (most common for modern phones)
cmake .. -DANDROID_ABI=arm64-v8a ...

# ARM v7 (older phones)
cmake .. -DANDROID_ABI=armeabi-v7a ...

# x86_64 (emulators)
cmake .. -DANDROID_ABI=x86_64 ...

# Then copy all to jniLibs:
mkdir -p app/android/app/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64}
# copy respective .so files to each directory
```

## Next Steps

After successfully building and testing on Android:

1. Commit these changes to git:
   ```bash
   git add -A
   git commit -m "Add Android native library build and jniLibs directory"
   git push origin claude/local-voice-to-text-plan-cwAVc
   ```

2. Consider automating the build in `build.sh` to detect platform and build accordingly

3. Test on multiple Android devices/versions for compatibility
