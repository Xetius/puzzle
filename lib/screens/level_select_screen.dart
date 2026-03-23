import 'package:flutter/material.dart';
import '../config/level_config.dart';
import '../services/storage_service.dart';
import 'play_level_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  final StorageService storageService;
  final int initialPage;

  const LevelSelectScreen({
    super.key,
    required this.storageService,
    this.initialPage = 0,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  late int _currentPage;
  Set<int> _completedLevels = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final completed = await widget.storageService.getCompletedLevels();
    setState(() {
      _completedLevels = completed;
    });
  }

  int get _highestUnlocked {
    if (_completedLevels.isEmpty) return 1;
    return _completedLevels.reduce((a, b) => a > b ? a : b) + 1;
  }

  int get _firstLevelOnPage => _currentPage * levelsPerPage + 1;
  int get _lastLevelOnPage => _firstLevelOnPage + levelsPerPage - 1;

  bool get _allCompletedOnPage {
    for (int i = _firstLevelOnPage; i <= _lastLevelOnPage; i++) {
      if (!_completedLevels.contains(i)) return false;
    }
    return true;
  }

  void _onLevelTap(int level) async {
    await widget.storageService.setLastPlayedLevel(level);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayLevelScreen(
          level: level,
          storageService: widget.storageService,
        ),
      ),
    );
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Levels $_firstLevelOnPage-$_lastLevelOnPage'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.count(
                crossAxisCount: 5,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: List.generate(levelsPerPage, (index) {
                  final level = _firstLevelOnPage + index;
                  final isCompleted = _completedLevels.contains(level);
                  final isUnlocked = level <= _highestUnlocked;

                  return _buildLevelCell(level, isCompleted, isUnlocked);
                }),
              ),
            ),
          ),
          if (_allCompletedOnPage && _lastLevelOnPage < totalLevels)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentPage++;
                  });
                },
                child: const Text('Next Levels'),
              ),
            ),
          if (_currentPage > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _currentPage--;
                  });
                },
                child: const Text('Previous Levels'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelCell(int level, bool isCompleted, bool isUnlocked) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isCompleted) {
      // Revealed placeholder color
      final hue = (level * 12.0) % 360;
      return GestureDetector(
        onTap: () => _onLevelTap(level),
        child: Container(
          decoration: BoxDecoration(
            color: HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$level',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (isUnlocked) {
      return GestureDetector(
        onTap: () => _onLevelTap(level),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$level',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    // Locked
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.lock,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
