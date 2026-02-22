import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioService {
  late final Record _recorder;
  bool _isRecording = false;

  AudioService() {
    _recorder = Record();
  }

  bool get isRecording => _isRecording;

  Future<void> initializeRecorder() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status.isDenied) {
      throw Exception('Microphone permission denied');
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
      await _recorder.start(
        path: audioPath,
        encoder: AudioEncoder.wav,
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
      final path = await _recorder.stop();
      _isRecording = false;
      // Return 0 as placeholder duration (record package doesn't return duration directly)
      return 0;
    } catch (e) {
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
  }
}
