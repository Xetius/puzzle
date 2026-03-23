import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'puzzle_tile_widget.dart';

class PuzzleGrid extends StatelessWidget {
  final GameState gameState;
  final int levelNumber;

  const PuzzleGrid({
    super.key,
    required this.gameState,
    required this.levelNumber,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: gameState.columns / gameState.rows,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / gameState.columns;
          final cellHeight = constraints.maxHeight / gameState.rows;

          return GridView.count(
            crossAxisCount: gameState.columns,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(gameState.totalCells, (position) {
              final tile = gameState.tileAtPosition(position);
              return PuzzleTileWidget(
                tile: tile,
                position: position,
                gameState: gameState,
                levelNumber: levelNumber,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
              );
            }),
          );
        },
      ),
    );
  }
}
