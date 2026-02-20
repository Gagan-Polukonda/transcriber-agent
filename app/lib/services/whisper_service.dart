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
        _dylib = DynamicLibrary.open('libwhisper_bridge.dylib');
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
      // Get model path
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = '${appDir.path}/whisper_models';
      final modelPath = '$modelDir/ggml-$_currentModel.bin';

      // Check if model exists
      if (!File(modelPath).existsSync()) {
        throw Exception('Model file not found at $modelPath');
      }

      // Call native transcribe function
      final audioCStr = audioPath.toNativeUtf8();
      final modelCStr = modelPath.toNativeUtf8();

      final resultPtr = transcribe(audioCStr, modelCStr);
      final result = resultPtr.toDartString();

      // Free C strings
      malloc.free(audioCStr);
      malloc.free(modelCStr);
      freeString(resultPtr);

      return result;
    } catch (e) {
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
}
