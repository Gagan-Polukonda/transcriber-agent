import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'services/whisper_service.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize services
  final whisperService = WhisperService();
  final audioService = AudioService();
  final storageService = StorageService();

  await storageService.initDb();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => whisperService),
        Provider(create: (_) => audioService),
        Provider(create: (_) => storageService),
      ],
      child: const VoiceToTextApp(),
    ),
  );
}

class VoiceToTextApp extends StatelessWidget {
  const VoiceToTextApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice to Text',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
