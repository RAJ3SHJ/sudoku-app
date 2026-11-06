import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/difficulty.dart';
import 'core/game_session.dart';
import 'core/local_store.dart';
import 'core/progress.dart';
import 'core/sudoku_generator.dart';
import 'services/auth_service.dart';
import 'services/cloud_sync.dart';

/// What happened when a game was won.
class WinOutcome {
  WinOutcome({
    required this.seconds,
    required this.newBest,
    required this.levelPassed,
    required this.becameMaster,
    required this.tierCompleted,
  });

  final int seconds;
  final bool newBest;
  final bool levelPassed;
  final bool becameMaster;
  final bool tierCompleted;
}

/// App-wide state: progress, settings, the saved game and the signed-in user.
class AppState extends ChangeNotifier {
  AppState({required this.store, required this.auth, CloudSync? cloud})
      : _cloud = auth.available ? (cloud ?? CloudSync()) : null {
    progress = store.loadProgress();
    themeMode = store.loadThemeMode();
    savedGame = store.loadSavedGame();
    _authSub = auth.userChanges().listen(_onUserChanged);
  }

  final LocalStore store;
  final AuthService auth;
  final CloudSync? _cloud;
  StreamSubscription<User?>? _authSub;

  late Progress progress;
  late ThemeMode themeMode;
  GameSession? savedGame;
  User? user;
  bool syncing = false;

  bool get signInAvailable => auth.available;

  // ---------- Games ----------

  /// Creates a fresh puzzle the player has never had before.
  /// [level] is null for free play.
  Future<GameSession> startGame(Difficulty d, int? level) async {
    final puzzle = await generatePuzzle(d, progress.playedPuzzles);
    progress.playedPuzzles.add(puzzle.fingerprint);
    await store.saveProgress(progress);

    final session = GameSession(
      difficulty: d,
      levelNumber: level,
      puzzle: puzzle.puzzle,
      solution: puzzle.solution,
    );
    await saveGame(session);
    return session;
  }

  /// Auto-save, called after every move and when the app goes to background.
  Future<void> saveGame(GameSession s) async {
    savedGame = s;
    await store.saveGame(s);
    notifyListeners();
  }

  Future<void> gameLost() async {
    savedGame = null;
    await store.clearSavedGame();
    notifyListeners();
  }

  Future<WinOutcome> gameWon(GameSession s) async {
    final wasMaster = progress.isMaster;
    final wasCompleted = progress.isCompleted(s.difficulty);
    final levelBefore = progress.currentLevel(s.difficulty);

    final newBest = progress.recordWin(s.difficulty, s.levelNumber, s.elapsedSeconds);
    savedGame = null;
    await store.clearSavedGame();
    await store.saveProgress(progress);
    notifyListeners();
    unawaited(_pushToCloud());

    return WinOutcome(
      seconds: s.elapsedSeconds,
      newBest: newBest,
      levelPassed: s.levelNumber != null && s.levelNumber == levelBefore,
      becameMaster: !wasMaster && progress.isMaster,
      tierCompleted: !wasCompleted && progress.isCompleted(s.difficulty),
    );
  }

  Future<void> markMasterCelebrated() async {
    progress.masterCelebrated = true;
    await store.saveProgress(progress);
    unawaited(_pushToCloud());
  }

  // ---------- Settings ----------

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    await store.saveThemeMode(m);
    notifyListeners();
  }

  // ---------- Google sign-in and cloud backup ----------

  Future<void> signIn() async {
    await auth.signInWithGoogle();
    // _onUserChanged runs the first sync.
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  /// Deletes the cloud backup, the Google-linked account and the progress
  /// saved on this phone.
  Future<void> deleteAccount() async {
    final uid = user?.uid;
    if (uid != null) await _cloud?.delete(uid);
    await auth.deleteAccount();
    await store.clearAll();
    progress = Progress();
    savedGame = null;
    notifyListeners();
  }

  Future<void> _onUserChanged(User? u) async {
    user = u;
    notifyListeners();
    if (u != null) await _syncDown(u.uid);
  }

  /// Merges cloud progress with this phone's, then saves the result in both
  /// places. Keeps the furthest level and the fastest times from either.
  Future<void> _syncDown(String uid) async {
    final cloud = _cloud;
    if (cloud == null) return;
    syncing = true;
    notifyListeners();
    try {
      final remote = await cloud.fetch(uid);
      if (remote != null) progress.mergeFrom(remote);
      await store.saveProgress(progress);
      await cloud.push(uid, progress);
    } catch (e) {
      debugPrint('Cloud sync failed, will retry later: $e');
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> _pushToCloud() async {
    final uid = user?.uid;
    final cloud = _cloud;
    if (uid == null || cloud == null) return;
    try {
      await cloud.push(uid, progress);
    } catch (e) {
      debugPrint('Cloud push failed: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
