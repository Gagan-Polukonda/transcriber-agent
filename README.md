# Voice to Text - Local Offline Transcription App

A fully offline voice-to-text transcription application that runs 100% locally on your mobile device or laptop. No cloud, no servers, no internet required. Everything stays on your device.

## Features

✨ **100% Offline** - All processing happens locally
🎤 **High-Quality Transcription** - Powered by OpenAI's Whisper
📱 **Cross-Platform** - Android, macOS, Linux support
⚡ **Fast** - Real-time or near real-time transcription
🔒 **Privacy** - Zero external connections, no data collection
💾 **Local Storage** - Transcripts saved locally
🎯 **Simple UI** - Intuitive recording and transcript management

## Quick Start (macOS)

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd transcriber-agent
   ```

2. **Download a Whisper model** into `models/` at the repo root
   ```bash
   mkdir -p models
   curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin \
        -o models/ggml-base.bin
   ```

3. **Build the native Whisper bridge** (whisper.cpp is already in the repo)
   ```bash
   cd native && mkdir -p build && cd build
   cmake .. && make -j$(sysctl -n hw.logicalcpu)
   cd ../../
   ```

4. **Install Flutter dependencies**
   ```bash
   cd app && flutter pub get
   ```

5. **Run the app**
   ```bash
   flutter run -d macos
   ```

See [SETUP.md](SETUP.md) for full details, troubleshooting, and Android/Linux setup.

## System Requirements

### Android
- Android 7.0+ (API 24+)
- 1GB+ RAM (Tiny model) or 2GB+ (Base/Small models)
- ~500MB storage for app + models

### macOS
- macOS 10.15+
- 1.5GB+ RAM
- Xcode Command Line Tools

### Linux
- Most modern distributions (Ubuntu 18.04+, Fedora, etc.)
- 1.5GB+ RAM
- Build tools: cmake, make, gcc/clang

## Project Structure

```
transcriber-agent/
├── app/                      # Flutter application
│   ├── lib/
│   │   ├── main.dart        # App entry point
│   │   ├── screens/         # UI screens
│   │   ├── services/        # Business logic
│   │   ├── models/          # Data models
│   │   └── widgets/         # Reusable UI components
│   ├── pubspec.yaml         # Flutter dependencies
│   ├── android/             # Android configuration
│   ├── macos/               # macOS configuration
│   └── linux/               # Linux configuration
│
├── native/                  # C++ Whisper bridge
│   ├── whisper_bridge.cpp   # FFI wrapper
│   ├── CMakeLists.txt       # Build configuration
│   ├── build/               # Compiled output (gitignored)
│   └── whisper.cpp/         # whisper.cpp source (included — do not re-clone)
│
├── models/                  # ← Whisper model files go here (repo root)
│   └── ggml-base.bin        # Default model (140 MB) — download separately
│
├── data/                    # Runtime data — auto-created, gitignored
│   ├── audio/               # Recorded WAV files
│   └── voice_transcripts.db # SQLite transcript database
│
├── SETUP.md                 # Detailed setup instructions
├── ARCHITECTURE.md          # Technical architecture
├── build.sh                 # Build automation script
└── README.md                # This file
```

## Architecture

The app is built in layers:

1. **Flutter UI** (Dart) - Cross-platform user interface
2. **Services** (Dart) - Audio recording, transcription, storage
3. **Native Bridge** (C++) - FFI wrapper for Whisper.cpp
4. **Whisper.cpp** (C++) - Core transcription engine
5. **SQLite** - Local transcript database

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed technical design.

## How It Works

1. **Record** - Click the big mic button to start/stop recording
2. **Transcribe** - Audio is processed by Whisper.cpp locally
3. **Save** - Transcript automatically saved to database
4. **Export** - Download as TXT or JSON file
5. **Manage** - View, search, and delete past transcripts

## Whisper Models

Choose based on your device and needs:

| Model | Size | Speed | Quality | RAM |
|-------|------|-------|---------|-----|
| **Tiny** | 75 MB | Very Fast (~real-time) | Good | 1 GB |
| **Base** | 140 MB | Fast (1-2x audio) | Better | 1.5 GB |
| **Small** | 465 MB | Moderate (2-5x audio) | Best | 2 GB |

Default is **Base** (good balance). Change in Settings.

## Supported Languages

- English (en)
- Auto-detect (coming soon)
- More languages can be added by downloading corresponding models

## Privacy & Security

🔐 **No Network Access**
- ✅ Zero internet permissions
- ✅ No outbound connections
- ✅ Works completely offline

🔐 **Data Stays Local**
- ✅ Audio files stored on device only
- ✅ Database encrypted at rest
- ✅ No cloud backup by default
- ✅ User has full control

🔐 **No Tracking**
- ✅ No analytics
- ✅ No telemetry
- ✅ No ads

## Platform-Specific Notes

### Android
- Microphone permission requested at runtime
- Audio stored in app-specific directory
- Models can be bundled or downloaded on first run

### macOS
- Grant microphone access via System Preferences → Security & Privacy → Microphone
- Runs in CPU-only mode (`use_gpu=false`) for compatibility with Intel Iris/HD GPUs where the Metal backend produces incorrect results
- Works on both Intel and Apple Silicon Macs

### Linux
- Works with ALSA and PulseAudio
- Models stored in `~/.local/share/voice_to_text/`
- Desktop entry for application menu

## Building for Distribution

### Android Release
```bash
cd app
flutter build apk --release
```

### macOS Release
```bash
cd app
flutter build macos --release
```

### Linux Release
```bash
cd app
flutter build linux --release
```

## Troubleshooting

**Issue: "whisper_bridge.dylib not found"**
- Build the native bridge: `cd native/build && cmake .. && make -j$(sysctl -n hw.logicalcpu)`
- After rebuilding, press `q` and do a full re-run — hot restart (`R`) won't pick up a new dylib

**Issue: "Model file not found"**
- Place your `.bin` file in `models/` at the **repo root** (e.g. `models/ggml-base.bin`)
- Download from HuggingFace — see [SETUP.md](SETUP.md) for the curl commands
- Run `flutter run` from inside the `app/` directory

**Issue: Empty transcription / no text returned**
- Low mic volume is automatically normalised — just speak clearly
- If it still fails, check `data/audio/` for non-empty `.wav` files
- If `n_segments=0` appears in logs, the Intel GPU Metal bug is already fixed with `use_gpu=false`

**Issue: SQLite error / database readonly**
- Delete the stale DB: `rm data/voice_transcripts.db` — the app recreates it on next launch

**Issue: Microphone permission denied**
- System Preferences → Security & Privacy → Microphone → enable the app

For more help, see [SETUP.md](SETUP.md).

## Performance Tips

- **Older phones**: Use "Tiny" model for speed
- **Powerful devices**: Use "Small" model for best quality
- **Noisy environment**: Record in quiet space, use directional microphone
- **Long audio**: Break into chunks for faster processing

## Contributing

Contributions welcome! Areas for improvement:
- Better audio preprocessing
- Real-time streaming transcription
- Additional language support
- UI/UX improvements
- Performance optimization

## License

[Specify your license here - MIT, Apache 2.0, etc.]

## Acknowledgments

- **Whisper.cpp**: https://github.com/ggerganov/whisper.cpp
- **OpenAI Whisper**: https://github.com/openai/whisper
- **Flutter**: https://flutter.dev

## Support

- 📖 **Documentation**: See SETUP.md and ARCHITECTURE.md
- 🐛 **Issues**: Report bugs via GitHub Issues
- 💬 **Discussions**: Share ideas and get help

---

**Version**: 1.0.0
**Last Updated**: February 2026
**Status**: Active Development

Built with ❤️ for offline-first privacy.
