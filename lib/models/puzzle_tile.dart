class PuzzleTile {
  /// The correct position index (0-based) in the solved puzzle.
  final int originalIndex;

  /// The current position index in the grid.
  int currentIndex;

  /// Group ID for joined tiles. Null means the tile is solo.
  int? groupId;

  PuzzleTile({
    required this.originalIndex,
    required this.currentIndex,
    this.groupId,
  });

  bool get isInCorrectPosition => originalIndex == currentIndex;
}
