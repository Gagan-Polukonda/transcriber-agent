import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';

typedef TranscribeFunction = Pointer<Utf8> Function(
  Pointer<Utf8> audioPath,
  Pointer<Utf8> modelPath,
);

typedef TranscribeFunctionDart = Pointer<Utf8> Function(
  Pointer<Utf8> audioPath,
  Pointer<Utf8> modelPath,
);

typedef FreeStringFunction = Void Function(Pointer<Utf8>);
typedef FreeStringFunctionDart = void Function(Pointer<Utf8>);

class WhisperService {
  late DynamicLibrary _dylib;
  late TranscribeFunctionDart transcribe;
  late FreeStringFunctionDart freeString;

  String _currentModel = 'base';
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load the native library
      if (Platform.isAndroid) {
        _dylib = DynamicLibrary.open('libwhisper_bridge.so');
      } else if (Platform.isMacOS) {
        _dylib = _loadMacOSLibrary();
      } else if (Platform.isLinux) {
        _dylib = DynamicLibrary.open('libwhisper_bridge.so');
      } else {
        throw UnsupportedError('Platform not supported');
      }

      // Get function pointers
      transcribe = _dylib
          .lookup<NativeFunction<TranscribeFunction>>('transcribe')
          .asFunction();

      freeString = _dylib
          .lookup<NativeFunction<FreeStringFunction>>('free_string')
          .asFunction();

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Whisper: $e');
    }
  }

  Future<String> transcribeAudio(String audioPath) async {
    await initialize();

    try {
      print('[WhisperService] Starting transcription for: $audioPath');

      // Find model file
      final modelPath = await _findModelFile(_currentModel);
      print('[WhisperService] Using model: $modelPath');

      // Verify audio file exists
      if (!await File(audioPath).exists()) {
        throw Exception('Audio file not found: $audioPath');
      }
      print('[WhisperService] Audio file exists');

      // Verify model file exists
      if (!await File(modelPath).exists()) {
        throw Exception('Model file not found: $modelPath');
      }
      print('[WhisperService] Model file exists');

      // Call native transcribe function
      print('[WhisperService] Calling native transcribe...');
      final audioCStr = audioPath.toNativeUtf8();
      final modelCStr = modelPath.toNativeUtf8();

      final resultPtr = transcribe(audioCStr, modelCStr);
      final result = resultPtr.toDartString();
      print('[WhisperService] Native call returned: $result');

      // Free C strings
      malloc.free(audioCStr);
      malloc.free(modelCStr);
      freeString(resultPtr);

      // Check for errors from native code
      if (result.startsWith('ERROR:')) {
        throw Exception('Native error: $result');
      }

      print('[WhisperService] Transcription successful: ${result.substring(0, 100)}...');
      return result;
    } catch (e) {
      print('[WhisperService] Transcription error: $e');
      throw Exception('Transcription failed: $e');
    }
  }

  void setModel(String model) {
    if (['tiny', 'base', 'small'].contains(model)) {
      _currentModel = model;
    } else {
      throw Exception('Invalid model: $model');
    }
  }

  String get currentModel => _currentModel;

  DynamicLibrary _loadMacOSLibrary() {
    // Search common paths where the dylib might be built
    final exe = Platform.resolvedExecutable;
    final appDir = exe.substring(0, exe.lastIndexOf('/'));

    final searchPaths = [
      // Next to the app executable (Frameworks dir)
      '$appDir/../Frameworks/whisper_bridge.dylib',
      // Native build output
      '${Directory.current.path}/native/build/whisper_bridge.dylib',
      // Relative to repo root from app/
      '${Directory.current.path}/../native/build/whisper_bridge.dylib',
      // System library path (where build.sh copies it)
      '/usr/local/lib/whisper_bridge.dylib',
    ];

    for (final path in searchPaths) {
      final file = File(path);
      if (file.existsSync()) {
        return DynamicLibrary.open(file.absolute.path);
      }
    }

    throw Exception(
      'whisper_bridge.dylib not found. Searched paths:\n'
      '${searchPaths.map((p) => '  - $p').join('\n')}\n'
      'Run ./build.sh from the project root to build the native library.',
    );
  }

  Future<String> _findModelFile(String model) async {
    final modelFileName = 'ggml-$model.bin';
    final List<String> searchPaths = [];

    if (Platform.isAndroid) {
      // App-specific external directory — push model here with:
      //   adb push models/ggml-base.bin \
      //     /sdcard/Android/data/com.voice_to_text_local/files/ggml-base.bin
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        searchPaths.add('${extDir.path}/$modelFileName');
      }
      // App internal documents directory as fallback
      final docsDir = await getApplicationDocumentsDirectory();
      searchPaths.add('${docsDir.path}/$modelFileName');
    } else {
      // Desktop: model lives in models/ at repo root
      searchPaths.addAll([
        // From app directory when running flutter run from app/
        '${Directory.current.path}/models/$modelFileName',
        // From parent of app directory (project root)
        '${Directory.current.path}/../models/$modelFileName',
        // From grandparent directory (if running from nested location)
        '${Directory.current.path}/../../models/$modelFileName',
      ]);
    }

    for (final path in searchPaths) {
      final file = File(path);
      if (file.existsSync()) {
        return file.absolute.path;
      }
    }

    final hint = Platform.isAndroid
        ? 'Push the model to the device with:\n'
          '  adb push models/ggml-base.bin \\\n'
          '    /sdcard/Android/data/com.voice_to_text_local/files/ggml-base.bin'
        : 'Ensure the model file exists in the repo at: models/$modelFileName';

    throw Exception(
      'Model file not found: $modelFileName\n'
      'Searched:\n'
      '${searchPaths.map((p) => '  - $p').join('\n')}\n'
      '$hint',
    );
  }
}
