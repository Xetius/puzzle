import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'services/storage_service.dart';
import 'screens/title_screen.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final storageService = StorageService();

  runApp(PuzzleApp(storageService: storageService));
}

class PuzzleApp extends StatelessWidget {
  final StorageService storageService;

  const PuzzleApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: TitleScreen(storageService: storageService),
    );
  }
}
