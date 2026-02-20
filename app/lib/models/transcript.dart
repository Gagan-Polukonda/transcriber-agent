class Transcript {
  final String id;
  final DateTime createdAt;
  final int durationSecs;
  final String audioPath;
  final String text;
  final String modelUsed;
  final String language;
  final String? exportPath;

  Transcript({
    required this.id,
    required this.createdAt,
    required this.durationSecs,
    required this.audioPath,
    required this.text,
    required this.modelUsed,
    required this.language,
    this.exportPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'duration_secs': durationSecs,
      'audio_path': audioPath,
      'text': text,
      'model_used': modelUsed,
      'language': language,
      'export_path': exportPath,
    };
  }

  factory Transcript.fromMap(Map<String, dynamic> map) {
    return Transcript(
      id: map['id'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      durationSecs: map['duration_secs'] ?? 0,
      audioPath: map['audio_path'] ?? '',
      text: map['text'] ?? '',
      modelUsed: map['model_used'] ?? 'base',
      language: map['language'] ?? 'en',
      exportPath: map['export_path'],
    );
  }
}
