import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transcript.dart';
import '../services/storage_service.dart';

class TranscriptsScreen extends StatefulWidget {
  const TranscriptsScreen({Key? key}) : super(key: key);

  @override
  State<TranscriptsScreen> createState() => _TranscriptsScreenState();
}

class _TranscriptsScreenState extends State<TranscriptsScreen> {
  late Future<List<Transcript>> _transcripts;

  @override
  void initState() {
    super.initState();
    _loadTranscripts();
  }

  void _loadTranscripts() {
    final storageService = context.read<StorageService>();
    _transcripts = storageService.getAllTranscripts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transcripts'),
      ),
      body: FutureBuilder<List<Transcript>>(
        future: _transcripts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final transcripts = snapshot.data ?? [];

          if (transcripts.isEmpty) {
            return const Center(child: Text('No transcripts yet'));
          }

          return ListView.builder(
            itemCount: transcripts.length,
            itemBuilder: (context, index) {
              final transcript = transcripts[index];
              return TranscriptCard(
                transcript: transcript,
                onDelete: _onDelete,
              );
            },
          );
        },
      ),
    );
  }

  void _onDelete(String id) {
    final storageService = context.read<StorageService>();
    storageService.deleteTranscript(id);
    setState(() {
      _loadTranscripts();
    });
  }
}

class TranscriptCard extends StatelessWidget {
  final Transcript transcript;
  final Function(String) onDelete;

  const TranscriptCard({
    Key? key,
    required this.transcript,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
    final dateStr = dateFormatter.format(transcript.createdAt);

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(
          transcript.text.length > 50
              ? '${transcript.text.substring(0, 50)}...'
              : transcript.text,
        ),
        subtitle: Text('$dateStr • ${transcript.durationSecs}s • ${transcript.modelUsed}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('View'),
              onTap: () => _showTranscriptDialog(context),
            ),
            PopupMenuItem(
              child: const Text('Export as TXT'),
              onTap: () => _exportTranscript(context, 'txt'),
            ),
            PopupMenuItem(
              child: const Text('Export as JSON'),
              onTap: () => _exportTranscript(context, 'json'),
            ),
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () => onDelete(transcript.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showTranscriptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Full Transcript'),
        content: SingleChildScrollView(
          child: Text(transcript.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTranscript(BuildContext context, String format) async {
    try {
      final storageService = context.read<StorageService>();
      final filePath = await storageService.exportTranscript(
        transcript,
        format: format,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
}
