import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/models/game_state.dart';

/// Create a GameState with a specific tile arrangement for testing.
/// [arrangement] maps grid position -> originalIndex of the tile displayed there.
/// Example: [1, 0, 2, 3] means position 0 shows tile with originalIndex 1, etc.
GameState createTestState(int columns, int rows, List<int> arrangement) {
  final state = GameState(columns: columns, rows: rows);
  for (int i = 0; i < arrangement.length; i++) {
    state.tiles[arrangement[i]].currentIndex = i;
  }
  state.moveCount = 0;
  state.refreshGroups();
  return state;
}

/// Helper to get a list of originalIndex values in grid position order.
List<int> getArrangement(GameState state) {
  return List.generate(state.totalCells, (pos) {
    return state.tileAtPosition(pos).originalIndex;
  });
}

/// Helper to check no positions are missing or duplicated.
void verifyIntegrity(GameState state) {
  final positions = state.tiles.map((t) => t.currentIndex).toList()..sort();
  expect(positions, List.generate(state.totalCells, (i) => i),
      reason: 'Every position must be occupied by exactly one tile');
}

void main() {
  group('Solo tile swaps', () {
    test('swap two solo tiles in same row', () {
      // 4x1: [1, 0, 3, 2] — no correct adjacencies
      final state = createTestState(4, 1, [1, 0, 3, 2]);
      expect(state.swap(0, 1), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [0, 1, 3, 2]);
    });

    test('swap two solo tiles across rows', () {
      // 3x2: [5, 3, 1, 4, 0, 2] — no correct adjacencies anywhere
      final state = createTestState(3, 2, [5, 3, 1, 4, 0, 2]);
      expect(state.swap(0, 4), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [0, 3, 1, 4, 5, 2]);
    });

    test('swap same position returns false', () {
      final state = createTestState(4, 1, [1, 0, 3, 2]);
      expect(state.swap(0, 0), isFalse);
    });

    test('swap increments move count', () {
      final state = createTestState(4, 1, [1, 0, 3, 2]);
      expect(state.moveCount, 0);
      state.swap(0, 1);
      expect(state.moveCount, 1);
    });
  });

  group('Group formation', () {
    test('horizontally adjacent correct tiles form a group', () {
      // [0, 1, 3, 2] — tiles 0,1 at positions 0,1 are correctly adjacent
      final state = createTestState(4, 1, [0, 1, 3, 2]);
      final tile0 = state.tileAtPosition(0);
      final tile1 = state.tileAtPosition(1);
      expect(tile0.groupId, isNotNull);
      expect(tile0.groupId, equals(tile1.groupId));
      // tiles 3,2 at positions 2,3 are backwards — NOT grouped
      final tile2 = state.tileAtPosition(2);
      final tile3 = state.tileAtPosition(3);
      expect(tile2.groupId == null || tile2.groupId != tile3.groupId, isTrue);
    });

    test('reversed tiles are not grouped', () {
      final state = createTestState(4, 1, [1, 0, 3, 2]);
      final tile0 = state.tileAtPosition(0);
      final tile1 = state.tileAtPosition(1);
      expect(tile0.groupId == null || tile0.groupId != tile1.groupId, isTrue);
    });

    test('vertically adjacent correct tiles form a group', () {
      // 3x3: orig 0 at pos 0, orig 3 at pos 3 → 0+3=3 ✓
      final state = createTestState(3, 3, [0, 2, 1, 3, 8, 4, 5, 7, 6]);
      final tile0 = state.tileAtPosition(0);
      final tile3 = state.tileAtPosition(3);
      expect(tile0.groupId, isNotNull);
      expect(tile0.groupId, equals(tile3.groupId));
    });

    test('three consecutive tiles form one group', () {
      // 5x1: [0, 1, 2, 4, 3] — only tiles 0,1,2 are adjacent
      final state = createTestState(5, 1, [0, 1, 2, 4, 3]);
      final group = state.groupAtPosition(0);
      expect(group.length, 3);
      // tiles 4,3 at positions 3,4 are NOT grouped
      final tile3 = state.tileAtPosition(3);
      expect(tile3.groupId == null || tile3.groupId != group.first.groupId, isTrue);
    });
  });

  group('Group movement — slide right by 1 (overlap case)', () {
    test('2-tile group slides right by 1', () {
      // 4x1: [0, 1, 3, 2] — only tiles 0,1 are grouped
      // Drag from pos 0 to pos 1 → group slides right by 1
      // Group at {0,1} → {1,2}; tile at pos 2 (orig 3) → pos 0
      // Expected: [3, 0, 1, 2]
      final state = createTestState(4, 1, [0, 1, 3, 2]);
      expect(state.swap(0, 1), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [3, 0, 1, 2]);
    });

    test('2-tile group slides right by 1 — drag from right tile', () {
      // Same arrangement. Drag from pos 1 to pos 2 — same colDelta (+1).
      final state = createTestState(4, 1, [0, 1, 3, 2]);
      expect(state.swap(1, 2), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [3, 0, 1, 2]);
    });
  });

  group('Group movement — slide right by 2 (no overlap)', () {
    test('2-tile group slides right by 2', () {
      // 4x1: [0, 1, 3, 2] — tiles 0,1 grouped
      // Drag pos 0 to pos 2 (delta +2)
      // Group {0,1} → {2,3}; tiles at {2,3} → {0,1}
      // Sorted mapping: pos 2 (orig 3) → pos 0, pos 3 (orig 2) → pos 1
      // Expected: [3, 2, 0, 1]
      final state = createTestState(4, 1, [0, 1, 3, 2]);
      expect(state.swap(0, 2), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [3, 2, 0, 1]);
    });
  });

  group('Group movement — slide left', () {
    test('2-tile group slides left by 1', () {
      // 4x1: [2, 0, 1, 3] — tiles 0,1 grouped at positions 1,2
      // Drag pos 1 to pos 0 (delta -1)
      // Group {1,2} → {0,1}; tile at pos 0 (orig 2) → pos 2
      // Expected: [0, 1, 2, 3]
      final state = createTestState(4, 1, [2, 0, 1, 3]);
      expect(state.swap(1, 0), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [0, 1, 2, 3]);
    });

    test('2-tile group slides left by 2', () {
      // 4x1: [3, 2, 0, 1] — tiles 0,1 grouped at positions 2,3
      // Drag pos 2 to pos 0 (delta -2)
      // Group {2,3} → {0,1}; tiles at {0,1} → {2,3}
      // Sorted: pos 0 (orig 3) → pos 2, pos 1 (orig 2) → pos 3
      // Expected: [0, 1, 3, 2]
      final state = createTestState(4, 1, [3, 2, 0, 1]);
      expect(state.swap(2, 0), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [0, 1, 3, 2]);
    });
  });

  group('Group movement — vertical slides', () {
    test('2-tile vertical group slides down by 1 row', () {
      // 3x3: [0, 2, 1, 3, 8, 4, 5, 7, 6]
      // Tiles orig 0 at pos 0, orig 3 at pos 3 → vertically grouped
      // Drag pos 0 to pos 3 (delta +1 row)
      // Group {0,3} → {3,6}; tile at pos 6 (orig 5) → pos 0
      // Expected: [5, 2, 1, 0, 8, 4, 3, 7, 6]
      final state = createTestState(3, 3, [0, 2, 1, 3, 8, 4, 5, 7, 6]);
      expect(state.swap(0, 3), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [5, 2, 1, 0, 8, 4, 3, 7, 6]);
    });

    test('2-tile vertical group slides up by 1 row', () {
      // 3x3: [5, 2, 1, 0, 8, 4, 3, 7, 6]
      // Tiles orig 0 at pos 3, orig 3 at pos 6 → vertically grouped
      // Drag pos 3 to pos 0 (delta -1 row)
      // Group {3,6} → {0,3}; tile at pos 0 (orig 5) → pos 6
      // Expected: [0, 2, 1, 3, 8, 4, 5, 7, 6]
      final state = createTestState(3, 3, [5, 2, 1, 0, 8, 4, 3, 7, 6]);
      expect(state.swap(3, 0), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [0, 2, 1, 3, 8, 4, 5, 7, 6]);
    });
  });

  group('Group movement — 3-tile group', () {
    test('3-tile horizontal group slides right by 1', () {
      // 5x1: [0, 1, 2, 4, 3] — tiles 0,1,2 grouped. Tiles 4,3 not grouped.
      // Drag pos 0 to pos 1 (delta +1)
      // Group {0,1,2} → {1,2,3}; tile at pos 3 (orig 4) → pos 0
      // Expected: [4, 0, 1, 2, 3]
      final state = createTestState(5, 1, [0, 1, 2, 4, 3]);
      expect(state.swap(0, 1), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [4, 0, 1, 2, 3]);
    });

    test('3-tile horizontal group slides right by 2', () {
      // 5x1: [0, 1, 2, 4, 3]
      // Drag pos 0 to pos 2 (delta +2)
      // Group {0,1,2} → {2,3,4}; tiles at {3,4} → {0,1}
      // Sorted: pos 3 (orig 4) → pos 0, pos 4 (orig 3) → pos 1
      // Expected: [4, 3, 0, 1, 2]
      final state = createTestState(5, 1, [0, 1, 2, 4, 3]);
      expect(state.swap(0, 2), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [4, 3, 0, 1, 2]);
    });

    test('3-tile horizontal group slides left by 1', () {
      // 5x1: [3, 0, 1, 2, 4] — tiles 0,1,2 grouped at {1,2,3}
      // (NOT [4,0,1,2,3] because that makes 0,1,2,3 all grouped — 4 tiles!)
      // Drag pos 1 to pos 0 (delta -1)
      // Group {1,2,3} → {0,1,2}; tile at pos 0 (orig 3) → pos 3
      // Expected: [0, 1, 2, 3, 4]
      final state = createTestState(5, 1, [3, 0, 1, 2, 4]);
      expect(state.swap(1, 0), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [0, 1, 2, 3, 4]);
    });
  });

  group('Group movement — out of bounds rejected', () {
    test('group cannot move past right edge', () {
      // 4x1: [0, 1, 3, 2] — tiles 0,1 grouped at {0,1}
      // Drag pos 0 to pos 3 (delta +3). Tile at pos 1 → col 1+3=4 >= 4. OOB.
      final state = createTestState(4, 1, [0, 1, 3, 2]);
      expect(state.swap(0, 3), isFalse);
      verifyIntegrity(state);
    });

    test('group cannot move past left edge', () {
      // 4x1: [2, 0, 1, 3] — tiles 0,1 grouped at {1,2}
      // Drag pos 2 to pos 0 (delta -2). Tile at pos 1 → col 1-2=-1. OOB.
      final state = createTestState(4, 1, [2, 0, 1, 3]);
      expect(state.swap(2, 0), isFalse);
      verifyIntegrity(state);
    });

    test('group cannot wrap across row boundary', () {
      // 4x2: tiles 0,1 at positions 3,4 would span rows — but they CAN'T
      // be grouped because pos 3 is col 3 (last col) and pos 4 is col 0 (next row).
      // Instead test: group at end of row trying to slide right.
      // [2, 3, 0, 1, 4, 5, 6, 7] — tiles 0,1 at positions 2,3 (cols 2,3)
      // Drag pos 2 to pos 3 (delta +1). Tile at pos 3 → col 3+1=4 >= 4. OOB.
      final state = createTestState(4, 2, [2, 3, 0, 1, 4, 5, 6, 7]);
      expect(state.swap(2, 3), isFalse);
      verifyIntegrity(state);
    });
  });

  group('User scenario: display 2|3|1|4', () {
    // Display "2|3|1|4" means originalIndex [1, 2, 0, 3] at positions [0,1,2,3]
    // Tiles orig 1,2 at positions 0,1 are correctly adjacent → grouped

    test('slide group right by 1 to get display 1|2|3|4', () {
      final state = createTestState(4, 1, [1, 2, 0, 3]);
      expect(state.swap(0, 1), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [0, 1, 2, 3]);
    });

    test('after slide right by 1, all tiles are solved', () {
      final state = createTestState(4, 1, [1, 2, 0, 3]);
      state.swap(0, 1);
      expect(state.isComplete, isTrue);
    });

    test('slide group right by 2 to get display 1|4|2|3', () {
      final state = createTestState(4, 1, [1, 2, 0, 3]);
      expect(state.swap(0, 2), isTrue);
      verifyIntegrity(state);
      // Group {0,1} → {2,3}; tiles at {2,3} = orig 0, orig 3 → {0,1}
      expect(getArrangement(state), [0, 3, 1, 2]);
    });
  });

  group('Moving into groups breaks them apart', () {
    test('solo tile displaces tile from middle of a 3-tile group', () {
      // 5x1: [3, 0, 1, 2, 4] — tiles 0,1,2 grouped at {1,2,3}
      // Swap solo at pos 0 with pos 2 (middle of group).
      // Tile at pos 2 (orig 1) gets displaced to pos 0.
      // Group {0,1,2} breaks apart — orig 0 at pos 1 and orig 2 at pos 3
      // are no longer adjacent to orig 1 (now at pos 0).
      final state = createTestState(5, 1, [3, 0, 1, 2, 4]);
      expect(state.swap(0, 2), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [1, 0, 3, 2, 4]);
    });

    test('group breaks apart correctly after displacement', () {
      // Same setup: after solo tile displaces middle of group
      final state = createTestState(5, 1, [3, 0, 1, 2, 4]);
      state.swap(0, 2);
      // Result: [1, 0, 3, 2, 4] — no correct adjacencies remain
      final tile0 = state.tileAtPosition(0);
      final tile1 = state.tileAtPosition(1);
      expect(tile0.groupId == null || tile0.groupId != tile1.groupId, isTrue);
    });

    test('2-tile group displaces into 3-tile group', () {
      // 5x1: [0, 1, 3, 2, 4] — tiles 0,1 grouped at {0,1}
      // After swap(0,1): [3, 0, 1, 2, 4] — tiles 0,1,2 grouped at {1,2,3}
      // Now slide 3-tile group right: swap(1,2)
      // After: [3, 4, 0, 1, 2] — {3,4} at {0,1} grouped, {0,1,2} at {2,3,4} grouped
      // Now move {3,4} group right into {0,1,2}: swap(0,2)
      // Group {0,1} at {0,1} → {2,3}. Displaces tiles at {2,3} (from {0,1,2} group).
      // Displaced tiles go to {0,1}. Group {0,1,2} breaks.
      final state = createTestState(5, 1, [0, 1, 3, 2, 4]);
      state.swap(0, 1); // [3, 0, 1, 2, 4]
      state.swap(1, 2); // [3, 4, 0, 1, 2]
      verifyIntegrity(state);
      // {3,4} at {0,1}, {0,1,2} at {2,3,4}
      // Now move {3,4} right by 2 into the other group
      expect(state.swap(0, 2), isTrue);
      verifyIntegrity(state);
      // {3,4} group → {2,3}. Tiles at {2,3} (orig 0, orig 1) → {0,1}.
      expect(getArrangement(state), [0, 1, 3, 4, 2]);
    });

    test('solo tile can swap with a solo tile next to a group', () {
      final state = createTestState(5, 1, [3, 0, 1, 2, 4]);
      expect(state.swap(0, 4), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [4, 0, 1, 2, 3]);
    });
  });

  group('Data integrity — no blank cells', () {
    test('repeated solo swaps maintain integrity', () {
      final state = createTestState(4, 3, [
        3, 1, 0, 2,
        7, 5, 4, 6,
        11, 9, 8, 10,
      ]);
      final moves = [
        [0, 1], [2, 3], [0, 4], [5, 1], [6, 2],
        [7, 3], [8, 9], [10, 11], [0, 8], [3, 11],
      ];
      for (final move in moves) {
        state.swap(move[0], move[1]);
        verifyIntegrity(state);
      }
    });

    test('group slides maintain integrity through many moves', () {
      // 5x1: [0, 1, 3, 2, 4] — tiles 0,1 grouped at {0,1}
      final state = createTestState(5, 1, [0, 1, 3, 2, 4]);

      // Slide right by 1: [3, 0, 1, 2, 4]
      // Group grows: orig 1 at pos 2, orig 2 at pos 3 → now {0,1,2} grouped.
      expect(state.swap(0, 1), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [3, 0, 1, 2, 4]);
      expect(state.groupAtPosition(1).length, 3);

      // Slide the 3-tile group right by 1: [3, 4, 0, 1, 2]
      expect(state.swap(1, 2), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [3, 4, 0, 1, 2]);

      // Now {3,4} at {0,1} form a group. Sliding {0,1,2} left breaks {3,4}.
      expect(state.swap(2, 1), isTrue);
      verifyIntegrity(state);
      // {0,1,2} at {2,3,4} → {1,2,3}. Tile at pos 1 (orig 4) → pos 4.
      expect(getArrangement(state), [3, 0, 1, 2, 4]);

      // Slide left again: {0,1,2} at {1,2,3} → {0,1,2}. Tile at pos 0 (orig 3) → pos 3.
      expect(state.swap(1, 0), isTrue);
      verifyIntegrity(state);
      expect(getArrangement(state), [0, 1, 2, 3, 4]);
      expect(state.isComplete, isTrue);
    });

    test('failed swap does not corrupt state', () {
      final state = createTestState(4, 1, [0, 1, 3, 2]);
      final before = getArrangement(state);
      state.swap(0, 3); // group would go OOB
      verifyIntegrity(state);
      expect(getArrangement(state), before);
    });
  });

  group('Win detection', () {
    test('solved puzzle is detected as complete', () {
      final state = createTestState(3, 2, [0, 1, 2, 3, 4, 5]);
      expect(state.isComplete, isTrue);
    });

    test('unsolved puzzle is not complete', () {
      final state = createTestState(3, 1, [1, 0, 2]);
      expect(state.isComplete, isFalse);
    });

    test('swapping last two tiles triggers completion', () {
      final state = createTestState(3, 1, [1, 0, 2]);
      state.swap(0, 1);
      expect(state.isComplete, isTrue);
    });
  });
}
