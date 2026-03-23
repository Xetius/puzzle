import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _completedLevelsKey = 'completed_levels';
  static const _lastPlayedLevelKey = 'last_played_level';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<Set<int>> getCompletedLevels() async {
    final p = await prefs;
    final json = p.getString(_completedLevelsKey);
    if (json == null) return {};
    final list = jsonDecode(json) as List;
    return list.cast<int>().toSet();
  }

  Future<void> markLevelCompleted(int level) async {
    final completed = await getCompletedLevels();
    completed.add(level);
    final p = await prefs;
    await p.setString(_completedLevelsKey, jsonEncode(completed.toList()));
  }

  Future<int> getLastPlayedLevel() async {
    final p = await prefs;
    return p.getInt(_lastPlayedLevelKey) ?? 1;
  }

  Future<void> setLastPlayedLevel(int level) async {
    final p = await prefs;
    await p.setInt(_lastPlayedLevelKey, level);
  }
}
