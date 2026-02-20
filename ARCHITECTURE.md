# Voice to Text - Architecture Overview

## System Design

This is a fully offline, local-first voice transcription system with zero network dependency.

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER UI LAYER                      │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Home     │  │ Transcripts  │  │  Settings    │    │
│  │  Screen    │  │   Screen     │  │  Screen      │    │
│  └────────────┘  └──────────────┘  └──────────────┘    │
└────────────────────────┬─────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼──────┐  ┌────▼──────┐  ┌────▼──────┐
    │   Audio   │  │  Whisper  │  │ Storage   │
    │  Service  │  │  Service  │  │  Service  │
    │  (Record) │  │ (Transcr.)│  │  (DB)     │
    └────┬──────┘  └────┬──────┘  └────┬──────┘
         │               │               │
         └───────────────┼───────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
    ┌────▼──────────────────────┐  ┌────▼─────────────┐
    │    Whisper.cpp Bridge     │  │   SQLite DB &    │
    │   (Native C++ via FFI)     │  │  Local Files     │
    │  ┌──────────────────────┐  │  │ ┌──────────────┐ │
    │  │ whisper_bridge.so    │  │  │ │ Transcripts  │ │
    │  │ (Compiled binary)    │  │  │ │ Audio Files  │ │
    │  └──────────────────────┘  │  │ │ Models       │ │
    └────┬──────────────────────┘  │ └──────────────┘ │
         │                          └────────────────────┘
    ┌────▼──────────────────┐
    │  Whisper Models       │
    │ ├─ ggml-tiny.bin      │  (75 MB)
    │ ├─ ggml-base.bin      │  (140 MB)
    │ └─ ggml-small.bin     │  (465 MB)
    └───────────────────────┘
```

## Component Breakdown

### 1. **Flutter UI Layer** (Dart)

#### HomeScreen
- Record button (start/stop recording)
- Live status indicator (idle/recording/transcribing)
- Duration timer while recording
- Last transcript preview
- Navigation to Transcripts & Settings

#### TranscriptsScreen
- Scrollable list of all saved transcripts
- Sorted by date (newest first)
- Quick actions: View, Export (TXT/JSON), Delete
- Tap to view full transcript text

#### SettingsScreen
- Model selection (Tiny/Base/Small)
- Export format (TXT/JSON)
- Language selection (English/Auto-detect)
- Privacy notice

### 2. **Service Layer** (Dart/Flutter)

#### AudioService
- **Responsibilities**: Record audio from microphone
- **Functions**:
  - `initializeRecorder()` - Request permissions, init recorder
  - `startRecording()` - Start recording to .wav file
  - `stopRecording()` - Stop recording, return duration
  - `dispose()` - Cleanup
- **Technology**: `flutter_sound` package
- **Output**: `.wav` files to app documents directory

#### WhisperService
- **Responsibilities**: Transcribe audio using Whisper.cpp
- **Functions**:
  - `initialize()` - Load native library and setup
  - `transcribeAudio(audioPath)` - Send audio file to whisper, get text
  - `setModel(model)` - Switch between tiny/base/small
- **Technology**: Dart FFI (Foreign Function Interface)
- **Bridge**: Calls `libwhisper_bridge.so/.dylib` native code

#### StorageService
- **Responsibilities**: Persist transcripts and manage files
- **Functions**:
  - `initDb()` - Setup SQLite database
  - `saveTranscript(transcript)` - Save to DB
  - `getAllTranscripts()` - Retrieve all transcripts
  - `getTranscript(id)` - Get single transcript
  - `deleteTranscript(id)` - Remove transcript
  - `exportTranscript(transcript, format)` - Save as TXT or JSON
- **Technology**: SQLite via `sqflite` package
- **Storage**: `~/Documents/VoiceTranscripts/` or app-specific directory

### 3. **Native Bridge Layer** (C++)

#### whisper_bridge.cpp
- **FFI-friendly wrapper** for Whisper.cpp
- **Core functions** (exported for FFI):
  - `init_whisper(model_path)` - Load model
  - `transcribe(audio_path, model_path)` - Transcribe audio
  - `free_string(ptr)` - Free allocated memory
  - `cleanup_whisper()` - Cleanup resources

- **Links against**: `libwhisper.a` (pre-compiled Whisper.cpp)
- **Compiled as**: `.so` (Android/Linux) or `.dylib` (macOS)

### 4. **Data Layer** (Local Files & SQLite)

#### SQLite Database (`voice_transcripts.db`)
```sql
CREATE TABLE transcripts (
  id TEXT PRIMARY KEY,
  created_at TEXT NOT NULL,
  duration_secs INTEGER NOT NULL,
  audio_path TEXT NOT NULL,
  text TEXT NOT NULL,
  model_used TEXT NOT NULL,
  language TEXT NOT NULL,
  export_path TEXT
);
```

#### File Structure
```
~/Documents/VoiceTranscripts/
├── voice_audio/
│   ├── recording_1708123456789.wav
│   └── recording_1708123457890.wav
├── transcripts/
│   ├── transcript_uuid-1.txt
│   ├── transcript_uuid-2.json
│   └── ...
└── whisper_models/
    ├── ggml-tiny.bin
    ├── ggml-base.bin
    └── ggml-small.bin
```

## Data Flow

### Record & Transcribe Flow

```
User clicks Record
        ↓
AudioService.startRecording()
        ↓
flutter_sound records to .wav file
        ↓
User clicks Stop
        ↓
AudioService.stopRecording() → returns duration
        ↓
UI shows "Transcribing..."
        ↓
WhisperService.transcribeAudio(audioPath)
        ↓
FFI call to whisper_bridge.transcribe()
        ↓
whisper_bridge loads model + processes audio
        ↓
Returns transcribed text to Dart
        ↓
StorageService.saveTranscript()
        ↓
Insert into SQLite DB
        ↓
Export to .txt/.json file
        ↓
UI shows "Transcript saved!"
```

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **UI Framework** | Flutter 3.0+ | Cross-platform UI (Android, macOS, Linux) |
| **Audio Recording** | flutter_sound | Microphone input → .wav files |
| **Speech Recognition** | Whisper.cpp | Local, offline transcription engine |
| **FFI Bridge** | Dart FFI | Dart ↔ C++ native interop |
| **Database** | SQLite | Persist transcripts and metadata |
| **State Management** | Provider | App state & service injection |
| **Build System** | CMake | Compile native whisper_bridge |

## Security & Privacy

### Zero Network Access
- ✅ No internet permission on Android (AndroidManifest.xml)
- ✅ No outbound connections on any platform
- ✅ All data stored locally on device

### Data Isolation
- ✅ Audio files in app-specific directory
- ✅ Database encrypted at rest (optional with sqflite_common_ffi)
- ✅ No sharing with other apps (unless user exports)

### Model Security
- ✅ Whisper models are public (OpenAI)
- ✅ No custom/proprietary models
- ✅ Embedded in app or downloaded once

## Performance Characteristics

### Model Performance

| Model | Size | Speed | Quality | RAM |
|-------|------|-------|---------|-----|
| Tiny | 75 MB | Real-time | Good | 1 GB |
| Base | 140 MB | 1-2x audio length | Better | 1.5 GB |
| Small | 465 MB | 2-5x audio length | Best | 2 GB |

### Device Requirements

**Minimum:**
- Android 7.0+ (API 24+) or macOS 10.15+ or Linux
- 1 GB RAM free (Tiny model)
- 500 MB storage for model + app

**Recommended:**
- Android 10+ or macOS 11+ or Modern Linux
- 2 GB RAM free (Base model)
- 1 GB storage

## Deployment

### Android
- Built as APK (single device) or AAB (Play Store)
- Model bundled inside APK or downloaded on first run
- Installed via adb or Play Store

### macOS
- Built as .dmg installer or directly as app bundle
- Notarization required for distribution

### Linux
- Built as AppImage, snap, or direct binary
- Desktop entry for application menu

## Future Enhancements

- [ ] Real-time streaming transcription
- [ ] Batch processing multiple files
- [ ] Cloud backup (optional, encrypted)
- [ ] Custom language packs
- [ ] Voice activity detection (VAD)
- [ ] Audio preprocessing (noise reduction)
- [ ] Speaker diarization
- [ ] Export to multiple formats (SRT, VTT, DOCX)

---

**Document Version**: 1.0
**Last Updated**: February 2024
