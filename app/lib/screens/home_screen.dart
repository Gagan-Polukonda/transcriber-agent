import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/audio_service.dart';
import '../services/whisper_service.dart';
import '../services/storage_service.dart';
import '../models/transcript.dart';
import 'transcripts_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRecording = false;
  bool _isTranscribing = false;
  String _statusText = 'Ready to record';
  String? _lastTranscript;
  Duration _recordingDuration = Duration.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice to Text'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red.shade100
                    : _isTranscribing
                        ? Colors.yellow.shade100
                        : Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _statusText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_isRecording)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _formatDuration(_recordingDuration),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),

            // Record button
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : Colors.blue).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),

            // Last transcript preview
            if (_lastTranscript != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Transcript:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastTranscript!.length > 200
                          ? '${_lastTranscript!.substring(0, 200)}...'
                          : _lastTranscript!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

            // View all transcripts button
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TranscriptsScreen()),
              ),
              icon: const Icon(Icons.history),
              label: const Text('View All Transcripts'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isRecording = true;
        _statusText = 'Recording...';
        _recordingDuration = Duration.zero;
      });

      final audioService = context.read<AudioService>();
      await audioService.startRecording();

      // Update duration every second
      while (_isRecording) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted && _isRecording) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
      setState(() {
        _isRecording = false;
        _statusText = 'Ready to record';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final audioService = context.read<AudioService>();
      final audioPath = audioService.toString(); // Placeholder
      final duration = await audioService.stopRecording();

      setState(() {
        _isRecording = false;
        _isTranscribing = true;
        _statusText = 'Transcribing...';
      });

      // Transcribe audio
      final whisperService = context.read<WhisperService>();
      final text = await whisperService.transcribeAudio(audioPath);

      // Save transcript
      final transcript = Transcript(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        durationSecs: duration ~/ 1000,
        audioPath: audioPath,
        text: text,
        modelUsed: whisperService.currentModel,
        language: 'en',
      );

      final storageService = context.read<StorageService>();
      await storageService.saveTranscript(transcript);

      setState(() {
        _isTranscribing = false;
        _statusText = 'Ready to record';
        _lastTranscript = text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcript saved successfully!')),
      );
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isTranscribing = false;
        _statusText = 'Ready to record';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
