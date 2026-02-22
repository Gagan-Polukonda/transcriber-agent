# Voice to Text - Local Setup Guide

This is a fully offline voice-to-text transcription app using Flutter and Whisper.cpp. Everything runs locally on your device with zero network access.

## Prerequisites

### Required Tools

1. **Flutter SDK** (3.0+)
   - Download: https://flutter.dev/docs/get-started/install
   - Verify: `flutter --version`

2. **Android Setup** (for mobile)
   - Android SDK (API 21+)
   - Android NDK (for compiling native code)
   - Set `ANDROID_HOME` and `ANDROID_NDK_ROOT` environment variables
   - Android Studio (recommended)

3. **macOS Setup** (for Mac)
   - Xcode Command Line Tools: `xcode-select --install`
   - CocoaPods: `sudo gem install cocoapods`

4. **Linux Setup** (for Desktop)
   - Build essentials: `sudo apt-get install build-essential cmake`
   - GTK development: `sudo apt-get install libgtk-3-dev`

5. **CMake** (for building native code)
   - Install: https://cmake.org/download/
   - Verify: `cmake --version`

## Project Structure

```
voice_to_text_local/
├── app/                    # Flutter app source
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/        # UI screens
│   │   ├── services/       # Business logic
│   │   └── models/         # Data models
│   ├── pubspec.yaml        # Flutter dependencies
│   ├── android/            # Android native setup
│   ├── macos/              # macOS native setup
│   └── linux/              # Linux native setup
├── native/                 # Whisper.cpp native bridge
│   ├── whisper_bridge.cpp  # FFI wrapper
│   └── CMakeLists.txt      # Build configuration
├── models/                 # Whisper model files
├── transcripts/            # Output transcripts folder
└── SETUP.md                # This file
```

## Step 1: Install Flutter & Dependencies

### macOS / Linux

```bash
# Clone Flutter (if not already installed)
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Get dependencies
flutter pub global activate fvm  # (Optional) for Flutter version management

# Verify setup
flutter doctor
```

Fix any issues reported by `flutter doctor` before proceeding.

### Android

1. Install Android Studio from https://developer.android.com/studio
2. Open Android Studio and install SDK/NDK via "SDK Manager"
3. Set environment variables:
   ```bash
   export ANDROID_HOME=$HOME/Android/Sdk
   export ANDROID_NDK_ROOT=$ANDROID_HOME/ndk/[version]
   export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
   ```

## Step 2: Set Up Flutter Project

```bash
# Navigate to the app directory
cd app

# Get Flutter dependencies
flutter pub get

# Generate FFI bindings (for Whisper bridge)
flutter pub run ffigen
```

## Step 3: Download Whisper Models

Models must be placed in `models/` directory. Download from OpenAI's Whisper repository:

```bash
# Create models directory if not exists
mkdir -p models

# Option A: Download with curl
# Tiny model (75 MB) - Fastest, ~1GB RAM
curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin -o models/ggml-tiny.bin

# Base model (140 MB) - Balanced, ~1.5GB RAM
curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin -o models/ggml-base.bin

# Small model (465 MB) - Most accurate, ~2GB RAM
curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin -o models/ggml-small.bin

# Option B: Or download manually from HuggingFace
# Visit: https://huggingface.co/ggerganov/whisper.cpp
```

## Step 4: Compile Native Whisper Bridge

### For Android

```bash
# Build the native library
mkdir -p app/android/app/libs

# You'll need whisper.cpp source. Clone it:
git clone https://github.com/ggerganov/whisper.cpp.git

# Use Android NDK to build
cd native
mkdir build_android
cd build_android

cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-21 \
  -DCMAKE_BUILD_TYPE=Release

make -j4
# Output: libwhisper_bridge.so
```

### For macOS / Linux

```bash
cd native
mkdir build
cd build

cmake ..
make -j4

# Output: libwhisper_bridge.dylib (macOS) or libwhisper_bridge.so (Linux)
```

## Step 5: Run the App

### Android Device/Emulator

```bash
cd app
flutter devices  # List connected devices
flutter run -d <device_id>
```

### macOS

```bash
cd app
flutter run -d macos
```

### Linux

```bash
cd app
flutter run -d linux
```

## Step 6: Grant Permissions

### Android

The app requests microphone permission at runtime. Grant it when prompted.

### macOS

Grant microphone access in System Preferences → Security & Privacy → Microphone

### Linux

Audio should work out of the box on most distributions.

## Troubleshooting

### "libwhisper_bridge.so not found"
- Ensure native library is compiled and placed in correct location
- On Android: Check `app/android/app/libs/arm64-v8a/libwhisper_bridge.so`
- On macOS: Check `app/macos/Runner/libwhisper_bridge.dylib`

### "Microphone permission denied"
- Android: Check app permissions in Settings → Apps
- macOS: System Preferences → Security & Privacy → Microphone
- Linux: Check ALSA/PulseAudio configuration

### "Model file not found"
- Ensure `.bin` files are in `~/Documents/voice_transcripts/whisper_models/` or bundled in app
- Download models from HuggingFace (see Step 3)

### "Recording quality is poor"
- Reduce background noise
- Move closer to microphone
- Use "Small" model for better accuracy at cost of speed

## Performance Tuning

| Model | Size | Speed | Accuracy | RAM |
|-------|------|-------|----------|-----|
| Tiny | 75 MB | Very Fast | Good | 1 GB |
| Base | 140 MB | Fast | Better | 1.5 GB |
| Small | 465 MB | Moderate | Best | 2 GB |

For slow devices, use "Tiny" model. For best results, use "Small" model.

## Privacy Guarantee

✅ **100% Offline** - No internet required
✅ **No Cloud** - Everything stored locally
✅ **No Tracking** - No analytics or telemetry
✅ **No Permissions** - Only microphone access

## Building for Release

### Android Release APK

```bash
cd app
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android Release AAB (for Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### macOS Release

```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/
```

### Linux Release

```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

## Next Steps

1. ✅ Complete the setup steps above
2. ✅ Test recording and transcription on your device
3. ✅ Adjust model size based on performance
4. ✅ Review transcripts and export as needed

## Support

For issues with:
- **Flutter**: https://flutter.dev/docs
- **Whisper.cpp**: https://github.com/ggerganov/whisper.cpp
- **This App**: Check the GitHub issues

---

**Last Updated:** 2024
**Version:** 1.0.0
