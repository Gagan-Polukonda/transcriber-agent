import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioService {
  late final AudioRecorder _recorder;
  bool _isRecording = false;

  AudioService() {
    _recorder = AudioRecorder();
  }

  bool get isRecording => _isRecording;

  Future<String> startRecording() async {
    if (_isRecording) {
      throw Exception('Recording already in progress');
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied. Please grant access in System Settings → Privacy → Microphone.');
    }

    // Save to app documents dir (works on Android and macOS)
    final Directory baseDir;
    if (Platform.isAndroid) {
      baseDir = await getApplicationDocumentsDirectory();
    } else {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) {
        throw Exception('Could not access Downloads directory');
      }
      baseDir = downloadDir;
    }
    final audioDir = Directory('${baseDir.path}/voice_transcripts/audio');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final audioPath = '${audioDir.path}/recording_$timestamp.wav';

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: audioPath,
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
      await _recorder.stop();
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
