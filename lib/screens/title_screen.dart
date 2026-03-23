import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../config/level_config.dart';
import '../services/storage_service.dart';
import 'level_select_screen.dart';

class TitleScreen extends StatefulWidget {
  final StorageService storageService;

  const TitleScreen({super.key, required this.storageService});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  int _highestLevel = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final completed = await widget.storageService.getCompletedLevels();
    setState(() {
      _highestLevel = completed.isEmpty ? 0 : completed.reduce((a, b) => a > b ? a : b);
      _loaded = true;
    });
  }

  void _play() async {
    final lastLevel = await widget.storageService.getLastPlayedLevel();
    final page = ((lastLevel - 1) ~/ levelsPerPage);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LevelSelectScreen(
          storageService: widget.storageService,
          initialPage: page,
        ),
      ),
    );
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Puzzle',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              if (_loaded && _highestLevel > 0)
                Text(
                  'Level $_highestLevel completed',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _play,
                child: const Text('Play'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
