import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/whisper_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedModel = 'base';
  late String _exportFormat = 'txt';
  late String _language = 'en';

  @override
  void initState() {
    super.initState();
    final whisperService = context.read<WhisperService>();
    _selectedModel = whisperService.currentModel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Model selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Whisper Model',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text('Tiny (Fast)'),
                    subtitle: const Text('75 MB - ~1GB RAM'),
                    value: 'tiny',
                    groupValue: _selectedModel,
                    onChanged: (value) {
                      setState(() => _selectedModel = value ?? 'base');
                      context.read<WhisperService>().setModel(_selectedModel);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Base (Balanced)'),
                    subtitle: const Text('140 MB - 1.5GB RAM'),
                    value: 'base',
                    groupValue: _selectedModel,
                    onChanged: (value) {
                      setState(() => _selectedModel = value ?? 'base');
                      context.read<WhisperService>().setModel(_selectedModel);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Small (Accurate)'),
                    subtitle: const Text('465 MB - 2GB RAM'),
                    value: 'small',
                    groupValue: _selectedModel,
                    onChanged: (value) {
                      setState(() => _selectedModel = value ?? 'base');
                      context.read<WhisperService>().setModel(_selectedModel);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Export format
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Format',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text('Text (.txt)'),
                    value: 'txt',
                    groupValue: _exportFormat,
                    onChanged: (value) => setState(() => _exportFormat = value ?? 'txt'),
                  ),
                  RadioListTile<String>(
                    title: const Text('JSON (.json)'),
                    value: 'json',
                    groupValue: _exportFormat,
                    onChanged: (value) => setState(() => _exportFormat = value ?? 'txt'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Language
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Language',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text('English'),
                    value: 'en',
                    groupValue: _language,
                    onChanged: (value) => setState(() => _language = value ?? 'en'),
                  ),
                  RadioListTile<String>(
                    title: const Text('Auto-detect'),
                    value: 'auto',
                    groupValue: _language,
                    onChanged: (value) => setState(() => _language = value ?? 'en'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info card
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Notice',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All audio recordings, models, and transcripts are stored locally on your device. No data is sent to any server or external service.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
