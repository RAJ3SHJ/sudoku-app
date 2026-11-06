import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_session.dart';
import 'progress.dart';

/// Saves progress, the unfinished game and settings on the phone.
/// This is what lets the game work fully offline.
class LocalStore {
  LocalStore(this._prefs);

  static Future<LocalStore> open() async =>
      LocalStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _progressKey = 'progress_v1';
  static const _savedGameKey = 'saved_game_v1';
  static const _themeKey = 'theme_mode';

  Progress loadProgress() {
    final raw = _prefs.getString(_progressKey);
    if (raw == null) return Progress();
    try {
      return Progress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return Progress();
    }
  }

  Future<void> saveProgress(Progress p) =>
      _prefs.setString(_progressKey, jsonEncode(p.toJson()));

  GameSession? loadSavedGame() {
    final raw = _prefs.getString(_savedGameKey);
    if (raw == null) return null;
    try {
      return GameSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGame(GameSession s) =>
      _prefs.setString(_savedGameKey, jsonEncode(s.toJson()));

  Future<void> clearSavedGame() => _prefs.remove(_savedGameKey);

  ThemeMode loadThemeMode() => switch (_prefs.getString(_themeKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> saveThemeMode(ThemeMode m) => _prefs.setString(_themeKey, m.name);

  /// Wipes everything, used when a player deletes their account.
  Future<void> clearAll() async {
    await _prefs.remove(_progressKey);
    await _prefs.remove(_savedGameKey);
  }
}
