import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioService {
  late FlutterSoundRecorder _recorder;
  bool _isRecording = false;

  AudioService() {
    _recorder = FlutterSoundRecorder();
  }

  bool get isRecording => _isRecording;

  Future<void> initializeRecorder() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status.isDenied) {
      throw Exception('Microphone permission denied');
    }

    // Open the recorder
    if (!_recorder.isOpen) {
      await _recorder.openRecorder();
    }
  }

  Future<String> startRecording() async {
    if (_isRecording) {
      throw Exception('Recording already in progress');
    }

    await initializeRecorder();

    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/voice_audio');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final audioPath = '${audioDir.path}/recording_$timestamp.wav';

    try {
      await _recorder.startRecorder(
        toFile: audioPath,
        codec: Codec.pcm16wav,
      );
      _isRecording = true;
      return audioPath;
    } catch (e) {
      throw Exception('Failed to start recording: $e');
    }
  }

  Future<int> stopRecording() async {
    if (!_isRecording) {
      throw Exception('No recording in progress');
    }

    try {
      final duration = await _recorder.stopRecorder();
      _isRecording = false;
      return duration ?? 0;
    } catch (e) {
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    await _recorder.closeRecorder();
  }
}
