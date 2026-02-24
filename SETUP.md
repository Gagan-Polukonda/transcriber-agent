# Voice to Text — Local Setup Guide

Fully offline voice-to-text transcription using Flutter + Whisper.cpp. No internet, no cloud, everything on your Mac.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter SDK | 3.0+ | https://flutter.dev/docs/get-started/install |
| Xcode CLT | latest | `xcode-select --install` |
| CMake | 3.14+ | `brew install cmake` |
| CocoaPods | latest | `brew install cocoapods` |

Verify Flutter is working:
```bash
flutter doctor
```

Fix any critical issues before proceeding.

---

## Repository Layout

```
transcriber-agent/
├── app/                        # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   ├── services/
│   │   └── models/
│   ├── macos/
│   │   └── Runner/
│   │       ├── DebugProfile.entitlements   # sandbox disabled, mic permission
│   │       └── Info.plist                  # NSMicrophoneUsageDescription set
│   └── pubspec.yaml
│
├── native/
│   ├── whisper_bridge.cpp      # FFI C++ wrapper
│   ├── CMakeLists.txt
│   ├── build/                  # build output (gitignored)
│   └── whisper.cpp/            # whisper.cpp source — already in repo, do NOT re-clone
│
├── models/                     # ← Put your .bin model files HERE (repo root)
│   └── ggml-base.bin           # default model (140 MB)
│
├── data/                       # Runtime data — auto-created by app, gitignored
│   ├── audio/                  # Recorded .wav files
│   └── voice_transcripts.db    # SQLite database
│
├── build.sh
├── README.md
├── SETUP.md                    # This file
└── ARCHITECTURE.md
```

---

## Step 1: Download a Whisper Model

Models live in `models/` at the **repo root** (not inside `app/`).

```bash
# From repo root:
mkdir -p models

# Base model — recommended (140 MB, good quality, fast enough)
curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin \
     -o models/ggml-base.bin

# Optional: Tiny model (75 MB, fastest)
# curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin \
#      -o models/ggml-tiny.bin

# Optional: Small model (465 MB, best quality)
# curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin \
#      -o models/ggml-small.bin
```

The app reads the model at runtime from:
```
<repo-root>/models/ggml-<model-name>.bin
```
(resolved as `../models/` relative to the `app/` directory when running `flutter run`.)

---

## Step 2: Build the Native Whisper Bridge

whisper.cpp is already included in the repo at `native/whisper.cpp/` — **no need to clone it**.

```bash
# From repo root:
cd native
mkdir -p build
cd build

cmake ..
make -j$(sysctl -n hw.logicalcpu)
```

This produces:
```
native/build/whisper_bridge.dylib   ← loaded by the Flutter app at runtime
native/build/libwhisper.a           ← static lib linked into the bridge
```

> **After rebuilding the dylib**, you must do a full stop and re-run — hot restart (`R`) does NOT reload dynamic libraries since the process caches them. Press `q` in the Flutter terminal, then `flutter run -d macos` again.

---

## Step 3: Install Flutter Dependencies

```bash
cd app
flutter pub get
```

No extra `ffigen` step is needed — the generated bindings (`lib/whisper_ffi.dart`) are already committed.

---

## Step 4: Run the App

```bash
cd app
flutter run -d macos
```

On first launch, macOS will prompt for **microphone access** — click Allow. If you accidentally deny it, go to:
> System Preferences → Security & Privacy → Microphone → enable the app

---

## How It Works at Runtime

1. **Record** — tap the mic button; audio is recorded at 16 kHz mono WAV
2. **Stop** — recording saved to `data/audio/<timestamp>.wav` (repo root)
3. **Transcribe** — whisper.cpp loads the model from `models/` and processes the WAV
4. **Save** — transcript stored in `data/voice_transcripts.db`
5. **Export** — TXT/JSON exports written to `data/`

The `data/` directory is created automatically and is gitignored.

---

## Platform Notes

### macOS — Intel (Iris 645 and similar GPUs)

GPU acceleration is **disabled** in the bridge (`use_gpu = false`) because the Metal backend on Intel integrated GPUs produces incorrect computation results with whisper.cpp. The app uses CPU-only mode (Accelerate / BLAS), which is stable and fast enough.

Apple Silicon Macs are unaffected but CPU mode also works fine there.

### Microphone Access

`NSMicrophoneUsageDescription` is already set in `app/macos/Runner/Info.plist`. The app sandbox is disabled in `DebugProfile.entitlements` and `Release.entitlements` so the dylib can be loaded from outside the bundle.

---

## Troubleshooting

### "Model file not found"
- Confirm the file exists: `ls -lh models/ggml-base.bin` (from repo root)
- The app resolves the path as `../models/ggml-base.bin` relative to `app/`
- Run `flutter run` from inside the `app/` directory, not from repo root

### "whisper_bridge.dylib not found"
- Build the native library (Step 2 above)
- Confirm: `ls native/build/whisper_bridge.dylib`
- After a rebuild, press `q` and re-run — don't use hot restart

### Empty transcription / no text
- Speak clearly; the app normalises low-amplitude audio automatically
- Check that the `.wav` file is non-empty: `ls -lh data/audio/`
- If `n_segments=0` persists, this is the GPU bug — already fixed with `use_gpu=false`

### SQLite errors / DB readonly
- Delete the stale database: `rm data/voice_transcripts.db`
- The app will recreate it on next launch

### Microphone permission denied
- System Preferences → Security & Privacy → Microphone → enable the app
- If the entry is missing, run the app once and then check again

---

## Model Quick Reference

| Model | File | Size | RAM | Quality |
|-------|------|------|-----|---------|
| Tiny | `ggml-tiny.bin` | 75 MB | ~1 GB | Good |
| **Base** | **`ggml-base.bin`** | **140 MB** | **~1.5 GB** | **Better (default)** |
| Small | `ggml-small.bin` | 465 MB | ~2 GB | Best |

Change the active model in the app's Settings screen.

---

## Android Setup

### Prerequisites

- **Android Studio** with SDK + NDK installed (SDK Manager → SDK Tools → NDK (Side by side))
- Set environment variables:
  ```bash
  export ANDROID_HOME=$HOME/Library/Android/sdk
  export ANDROID_NDK_ROOT=$ANDROID_HOME/ndk/<version>   # e.g. 26.1.10909125
  ```

### Step A: Generate Android project files

```bash
cd app
flutter create --platforms=android .
```

This creates `app/android/` with all Gradle files. It does not touch existing Dart code.

Then add microphone permission to `app/android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28"/>
```

### Step B: Cross-compile whisper_bridge for ARM64

```bash
cd native
mkdir -p build_android && cd build_android

cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE=Release

make -j$(sysctl -n hw.logicalcpu)
```

Copy the output into the Flutter jniLibs directory:

```bash
mkdir -p app/android/app/src/main/jniLibs/arm64-v8a
cp native/build_android/whisper_bridge.so \
   app/android/app/src/main/jniLibs/arm64-v8a/libwhisper_bridge.so
```

> The `lib` prefix is required — Android's dynamic linker looks for `libwhisper_bridge.so` when the Dart code calls `DynamicLibrary.open('libwhisper_bridge.so')`.

### Step C: Push the Whisper model to the device

The model is too large to bundle in the APK. Push it to the app's external storage directory:

```bash
# Install the app first (Step D), then:
adb push models/ggml-base.bin \
  /sdcard/Android/data/com.voice_to_text_local/files/ggml-base.bin
```

The app searches this exact path automatically.

### Step D: Build and run

```bash
cd app
flutter devices          # confirm your device is listed
flutter run -d <device-id>
```

Or build a release APK for sideloading:
```bash
flutter build apk --release
# output: app/build/app/outputs/flutter-apk/app-release.apk
adb install app/build/app/outputs/flutter-apk/app-release.apk
```

### Android Troubleshooting

**`UnsatisfiedLinkError: libwhisper_bridge.so`**
- Check `app/android/app/src/main/jniLibs/arm64-v8a/libwhisper_bridge.so` exists
- Rebuild and reinstall the APK — library changes require a fresh install, not just hot restart

**"Model file not found"**
- Run Step C above to push the model
- Check the exact package name by running `adb shell pm list packages | grep voice` and adjust the path if it differs from `com.voice_to_text_local`

**Microphone permission denied**
- Go to Android Settings → Apps → Voice to Text → Permissions → Microphone → Allow

---

**Last updated:** February 2026
