import 'package:flutter/material.dart';
import '../config/level_config.dart';
import '../models/game_state.dart';
import '../services/storage_service.dart';
import '../widgets/puzzle_grid.dart';

class PlayLevelScreen extends StatefulWidget {
  final int level;
  final StorageService storageService;

  const PlayLevelScreen({
    super.key,
    required this.level,
    required this.storageService,
  });

  @override
  State<PlayLevelScreen> createState() => _PlayLevelScreenState();
}

class _PlayLevelScreenState extends State<PlayLevelScreen> {
  late final DifficultyConfig _difficulty;
  late final GameState _gameState;

  @override
  void initState() {
    super.initState();
    _difficulty = difficultyForLevel(widget.level);
    _gameState = GameState(
      columns: _difficulty.columns,
      rows: _difficulty.rows,
    );
    _gameState.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    _gameState.removeListener(_onGameStateChanged);
    _gameState.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    setState(() {});
    if (_gameState.isComplete) {
      _onPuzzleComplete();
    }
  }

  Future<void> _onPuzzleComplete() async {
    await widget.storageService.markLevelCompleted(widget.level);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Puzzle Complete!'),
        content: Text('You solved it in ${_gameState.moveCount} moves.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // back to level select
            },
            child: const Text('Back to Levels'),
          ),
          if (widget.level < totalLevels)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx); // close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayLevelScreen(
                      level: widget.level + 1,
                      storageService: widget.storageService,
                    ),
                  ),
                );
              },
              child: const Text('Next Level'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${widget.level}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Moves: ${_gameState.moveCount}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: PuzzleGrid(
            gameState: _gameState,
            levelNumber: widget.level,
          ),
        ),
      ),
    );
  }
}
