class DifficultyConfig {
  final String name;
  final int columns;
  final int rows;

  const DifficultyConfig({
    required this.name,
    required this.columns,
    required this.rows,
  });

  int get totalCells => columns * rows;
}

const List<DifficultyConfig> difficulties = [
  DifficultyConfig(name: 'easy', columns: 4, rows: 5),
  DifficultyConfig(name: 'medium', columns: 5, rows: 6),
  DifficultyConfig(name: 'hard', columns: 6, rows: 7),
  DifficultyConfig(name: 'expert', columns: 7, rows: 8),
];

const int levelsPerPage = 30;

/// Maps a 1-based level number to its difficulty configuration.
/// Edit this function to change which levels use which difficulty.
DifficultyConfig difficultyForLevel(int level) {
  if (level <= 30) return difficulties[0];
  if (level <= 60) return difficulties[1];
  if (level <= 90) return difficulties[2];
  return difficulties[3];
}

/// Total number of levels in the game.
const int totalLevels = 120;
