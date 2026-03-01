import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/transcript.dart';

class StorageService {
  late Database _db;

  Future<Directory> _getDataDir() async {
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
    return Directory('${baseDir.path}/voice_transcripts');
  }

  Future<void> initDb() async {
    final dataDir = await _getDataDir();
    if (!dataDir.existsSync()) {
      dataDir.createSync(recursive: true);
    }

    final dbPath = join(dataDir.path, 'voice_transcripts.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createTables,
    );

    final transcriptsDir = Directory('${dataDir.path}/transcripts');
    if (!transcriptsDir.existsSync()) {
      transcriptsDir.createSync(recursive: true);
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transcripts (
        id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        duration_secs INTEGER NOT NULL,
        audio_path TEXT NOT NULL,
        text TEXT NOT NULL,
        model_used TEXT NOT NULL,
        language TEXT NOT NULL,
        export_path TEXT
      )
    ''');
  }

  Future<void> saveTranscript(Transcript transcript) async {
    await _db.insert('transcripts', transcript.toMap());
  }

  Future<List<Transcript>> getAllTranscripts() async {
    final result = await _db.query('transcripts', orderBy: 'created_at DESC');
    return result.map((map) => Transcript.fromMap(map)).toList();
  }

  Future<Transcript?> getTranscript(String id) async {
    final result = await _db.query('transcripts', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Transcript.fromMap(result.first);
  }

  Future<void> deleteTranscript(String id) async {
    await _db.delete('transcripts', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> exportTranscript(
    Transcript transcript, {
    required String format, // 'txt' or 'json'
  }) async {
    final dataDir = await _getDataDir();
    final transcriptsDir = Directory('${dataDir.path}/transcripts');

    final fileName = 'transcript_${transcript.id}.$format';
    final filePath = join(transcriptsDir.path, fileName);

    final file = File(filePath);

    if (format == 'txt') {
      final content = '''
Transcript
==========
Date: ${transcript.createdAt}
Duration: ${transcript.durationSecs} seconds
Model: ${transcript.modelUsed}
Language: ${transcript.language}

${transcript.text}
''';
      await file.writeAsString(content);
    } else if (format == 'json') {
      final jsonContent = '''
{
  "id": "${transcript.id}",
  "created_at": "${transcript.createdAt.toIso8601String()}",
  "duration_secs": ${transcript.durationSecs},
  "audio_path": "${transcript.audioPath}",
  "text": "${transcript.text.replaceAll('"', '\\"')}",
  "model_used": "${transcript.modelUsed}",
  "language": "${transcript.language}"
}
''';
      await file.writeAsString(jsonContent);
    }

    return filePath;
  }

  Future<void> closeDb() async {
    await _db.close();
  }
}
