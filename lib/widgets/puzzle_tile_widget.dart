import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/puzzle_tile.dart';

class PuzzleTileWidget extends StatelessWidget {
  final PuzzleTile tile;
  final int position;
  final GameState gameState;
  final int levelNumber;
  final double cellWidth;
  final double cellHeight;

  const PuzzleTileWidget({
    super.key,
    required this.tile,
    required this.position,
    required this.gameState,
    required this.levelNumber,
    required this.cellWidth,
    required this.cellHeight,
  });

  Color _colorForTile(PuzzleTile t) {
    final hue = (levelNumber * 37.0 + t.originalIndex * 7.0) % 360;
    final saturation = 0.5 + (t.originalIndex % 5) * 0.1;
    final lightness = 0.3 + (t.originalIndex % 7) * 0.05;
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  Widget _buildTileContent({
    required PuzzleTile t,
    required int pos,
    bool showJoinedBorders = true,
  }) {
    const borderColor = Colors.black87;
    const borderWidth = 2.0;
    const noBorder = BorderSide.none;

    final joinedRight = showJoinedBorders && gameState.isJoinedRight(pos);
    final joinedBelow = showJoinedBorders && gameState.isJoinedBelow(pos);
    final joinedLeft = showJoinedBorders && gameState.isJoinedLeft(pos);
    final joinedAbove = showJoinedBorders && gameState.isJoinedAbove(pos);

    return Container(
      decoration: BoxDecoration(
        color: _colorForTile(t),
        border: Border(
          top: joinedAbove ? noBorder : const BorderSide(color: borderColor, width: borderWidth),
          right: joinedRight ? noBorder : const BorderSide(color: borderColor, width: borderWidth),
          bottom: joinedBelow ? noBorder : const BorderSide(color: borderColor, width: borderWidth),
          left: joinedLeft ? noBorder : const BorderSide(color: borderColor, width: borderWidth),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${t.originalIndex + 1}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  /// Build a feedback widget showing the entire group arranged correctly.
  Widget _buildGroupFeedback() {
    final group = gameState.groupAtPosition(position);

    if (group.length == 1) {
      // Solo tile feedback
      return SizedBox(
        width: cellWidth,
        height: cellHeight,
        child: Opacity(
          opacity: 0.85,
          child: _buildTileContent(t: tile, pos: position, showJoinedBorders: false),
        ),
      );
    }

    // Find bounding box of the group in grid coordinates
    final positions = group.map((t) => t.currentIndex).toList();
    final minRow = positions.map((p) => p ~/ gameState.columns).reduce((a, b) => a < b ? a : b);
    final maxRow = positions.map((p) => p ~/ gameState.columns).reduce((a, b) => a > b ? a : b);
    final minCol = positions.map((p) => p % gameState.columns).reduce((a, b) => a < b ? a : b);
    final maxCol = positions.map((p) => p % gameState.columns).reduce((a, b) => a > b ? a : b);

    final groupCols = maxCol - minCol + 1;
    final groupRows = maxRow - minRow + 1;

    // Offset so the drag anchor is at the dragged tile's position within the group
    final dragRow = position ~/ gameState.columns;
    final dragCol = position % gameState.columns;
    final offsetX = (dragCol - minCol) * cellWidth;
    final offsetY = (dragRow - minRow) * cellHeight;

    return Transform.translate(
      offset: Offset(-offsetX, -offsetY),
      child: SizedBox(
        width: groupCols * cellWidth,
        height: groupRows * cellHeight,
        child: Opacity(
          opacity: 0.85,
          child: Stack(
            children: group.map((t) {
              final tRow = t.currentIndex ~/ gameState.columns;
              final tCol = t.currentIndex % gameState.columns;
              return Positioned(
                left: (tCol - minCol) * cellWidth,
                top: (tRow - minRow) * cellHeight,
                width: cellWidth,
                height: cellHeight,
                child: _buildTileContent(t: t, pos: t.currentIndex),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If this tile is part of a group being dragged, show ghost
    final isBeingDragged = gameState.isDragging(tile) ||
        gameState.isDraggingSolo(position);

    if (isBeingDragged) {
      return DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != position,
        onAcceptWithDetails: (details) {
          gameState.swap(details.data, position);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withValues(alpha: 0.4),
              border: Border.all(color: Colors.grey.shade700, width: 1),
            ),
          );
        },
      );
    }

    final tileContent = _buildTileContent(t: tile, pos: position);

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != position,
      onAcceptWithDetails: (details) {
        gameState.swap(details.data, position);
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        return Draggable<int>(
          data: position,
          onDragStarted: () => gameState.startDrag(position),
          onDragEnd: (_) => gameState.endDrag(),
          onDraggableCanceled: (_, __) => gameState.endDrag(),
          feedback: Material(
            color: Colors.transparent,
            child: _buildGroupFeedback(),
          ),
          childWhenDragging: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withValues(alpha: 0.4),
              border: Border.all(color: Colors.grey.shade700, width: 1),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isHighlighted
                  ? _colorForTile(tile).withValues(alpha: 0.5)
                  : null,
            ),
            child: tileContent,
          ),
        );
      },
    );
  }
}
