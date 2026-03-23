import 'dart:math';
import 'package:flutter/foundation.dart';
import 'puzzle_tile.dart';

class GameState extends ChangeNotifier {
  final int columns;
  final int rows;
  late List<PuzzleTile> tiles;
  int moveCount = 0;
  bool _isComplete = false;
  int? _draggingGroupId;

  bool get isComplete => _isComplete;
  int get totalCells => columns * rows;

  /// Whether a tile is part of the currently dragged group.
  bool isDragging(PuzzleTile tile) {
    if (_draggingGroupId == null) return false;
    return tile.groupId == _draggingGroupId;
  }

  /// Whether a solo tile (no group) is being dragged from [position].
  int? _draggingSoloPosition;
  bool isDraggingSolo(int position) => _draggingSoloPosition == position;

  void startDrag(int position) {
    final tile = tileAtPosition(position);
    if (tile.groupId != null) {
      _draggingGroupId = tile.groupId;
    } else {
      _draggingSoloPosition = position;
    }
    notifyListeners();
  }

  void endDrag() {
    _clearDrag();
  }

  void _clearDrag() {
    _draggingGroupId = null;
    _draggingSoloPosition = null;
    notifyListeners();
  }

  GameState({required this.columns, required this.rows}) {
    _initAndScramble();
  }

  /// Recompute groups from current tile positions. Exposed for testing.
  void refreshGroups() {
    _checkAndMergeGroups();
    _checkCompletion();
  }

  void _initAndScramble() {
    tiles = List.generate(
      totalCells,
      (i) => PuzzleTile(originalIndex: i, currentIndex: i),
    );
    _scramble();
    _checkAndMergeGroups();
  }

  void _scramble() {
    final random = Random();
    // Fisher-Yates shuffle on currentIndex values
    final indices = List.generate(totalCells, (i) => i);
    for (int i = indices.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = indices[i];
      indices[i] = indices[j];
      indices[j] = temp;
    }

    for (int i = 0; i < totalCells; i++) {
      tiles[i].currentIndex = indices[i];
    }

    // Make sure it's not already solved
    if (tiles.every((t) => t.isInCorrectPosition)) {
      // Swap first two to unshuffle
      tiles[0].currentIndex = 1;
      tiles[1].currentIndex = 0;
    }
  }

  /// Get the tile that is currently displayed at grid position [position].
  PuzzleTile tileAtPosition(int position) {
    return tiles.firstWhere((t) => t.currentIndex == position);
  }

  /// Get all tiles in the same group as the tile at [position].
  /// Returns a single-element list if the tile is solo.
  List<PuzzleTile> groupAtPosition(int position) {
    final tile = tileAtPosition(position);
    if (tile.groupId == null) return [tile];
    return tiles.where((t) => t.groupId == tile.groupId).toList();
  }

  /// Move the group containing tile at [fromPosition] so that the dragged
  /// tile lands at [toPosition]. The whole group shifts by the same
  /// row/column delta. Displaced tiles swap into the vacated positions.
  bool swap(int fromPosition, int toPosition) {
    if (fromPosition == toPosition) {
      _clearDrag();
      return false;
    }

    final draggedGroup = groupAtPosition(fromPosition);

    // Work in row/col space to avoid wrapping bugs
    final rowDelta = toPosition ~/ columns - fromPosition ~/ columns;
    final colDelta = toPosition % columns - fromPosition % columns;

    // Calculate where each group tile lands
    final sourcePositions = <int>{};
    final destPositions = <int>{};
    final groupMoves = <PuzzleTile, int>{};

    for (final tile in draggedGroup) {
      final srcPos = tile.currentIndex;
      sourcePositions.add(srcPos);

      final newRow = srcPos ~/ columns + rowDelta;
      final newCol = srcPos % columns + colDelta;

      if (newRow < 0 || newRow >= rows || newCol < 0 || newCol >= columns) {
        _clearDrag();
        return false;
      }

      final destPos = newRow * columns + newCol;
      destPositions.add(destPos);
      groupMoves[tile] = destPos;
    }

    // Positions the group is moving INTO that it doesn't already occupy
    final newlyOccupied = destPositions.difference(sourcePositions);
    // Positions the group is leaving behind
    final newlyVacated = sourcePositions.difference(destPositions);

    // Collect tiles that need to be displaced (only from newly occupied positions).
    // If a displaced tile is part of a group, it gets ripped out — groups are
    // recomputed after the move, so the remaining tiles simply stop being joined.
    final displacedTiles = <PuzzleTile>[];
    for (final pos in newlyOccupied) {
      displacedTiles.add(tileAtPosition(pos));
    }

    // Map displaced tiles to vacated positions.
    // Sort both sets so tiles maintain their relative order.
    final sortedOccupied = newlyOccupied.toList()..sort();
    final sortedVacated = newlyVacated.toList()..sort();

    final displacedMoves = <PuzzleTile, int>{};
    for (int i = 0; i < sortedOccupied.length; i++) {
      displacedMoves[tileAtPosition(sortedOccupied[i])] = sortedVacated[i];
    }

    // Apply all moves
    for (final entry in groupMoves.entries) {
      entry.key.currentIndex = entry.value;
    }
    for (final entry in displacedMoves.entries) {
      entry.key.currentIndex = entry.value;
    }

    _clearDrag();
    moveCount++;
    _checkAndMergeGroups();
    _checkCompletion();
    notifyListeners();
    return true;
  }

  void _checkAndMergeGroups() {
    // Reset all groups
    for (final tile in tiles) {
      tile.groupId = null;
    }

    int nextGroupId = 0;

    // For each position, check if the tile there and its right/bottom neighbor
    // are correctly adjacent in the original image.
    for (int pos = 0; pos < totalCells; pos++) {
      final tile = tileAtPosition(pos);

      // Check right neighbor (same row)
      if ((pos + 1) % columns != 0 && pos + 1 < totalCells) {
        final rightTile = tileAtPosition(pos + 1);
        if (rightTile.originalIndex == tile.originalIndex + 1 &&
            tile.originalIndex % columns != columns - 1) {
          _mergeTiles(tile, rightTile, nextGroupId++);
        }
      }

      // Check bottom neighbor
      if (pos + columns < totalCells) {
        final bottomTile = tileAtPosition(pos + columns);
        if (bottomTile.originalIndex == tile.originalIndex + columns) {
          _mergeTiles(tile, bottomTile, nextGroupId++);
        }
      }
    }
  }

  void _mergeTiles(PuzzleTile a, PuzzleTile b, int newGroupId) {
    if (a.groupId != null && b.groupId != null) {
      // Both already in groups — merge b's group into a's
      final oldGroup = b.groupId!;
      final targetGroup = a.groupId!;
      for (final t in tiles) {
        if (t.groupId == oldGroup) {
          t.groupId = targetGroup;
        }
      }
    } else if (a.groupId != null) {
      b.groupId = a.groupId;
    } else if (b.groupId != null) {
      a.groupId = b.groupId;
    } else {
      a.groupId = newGroupId;
      b.groupId = newGroupId;
    }
  }

  void _checkCompletion() {
    _isComplete = tiles.every((t) => t.isInCorrectPosition);
  }

  /// Check if the tile at [position] has a joined neighbor on the given side.
  bool isJoinedRight(int position) {
    if ((position + 1) % columns == 0) return false;
    final tile = tileAtPosition(position);
    if (tile.groupId == null) return false;
    final right = tileAtPosition(position + 1);
    return right.groupId == tile.groupId;
  }

  bool isJoinedBelow(int position) {
    if (position + columns >= totalCells) return false;
    final tile = tileAtPosition(position);
    if (tile.groupId == null) return false;
    final below = tileAtPosition(position + columns);
    return below.groupId == tile.groupId;
  }

  bool isJoinedLeft(int position) {
    if (position % columns == 0) return false;
    return isJoinedRight(position - 1);
  }

  bool isJoinedAbove(int position) {
    if (position - columns < 0) return false;
    return isJoinedBelow(position - columns);
  }
}
