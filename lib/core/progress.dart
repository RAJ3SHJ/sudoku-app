import 'difficulty.dart';

/// Everything about a player's progress that is saved on the phone and,
/// once they sign in with Google, synced to the cloud.
class Progress {
  Progress({
    Map<Difficulty, int>? levelsPassed,
    Map<Difficulty, int>? bestTimes,
    Set<String>? playedPuzzles,
    this.masterCelebrated = false,
  })  : levelsPassed = levelsPassed ?? {for (final d in Difficulty.values) d: 0},
        bestTimes = bestTimes ?? {},
        playedPuzzles = playedPuzzles ?? {};

  /// Levels passed per difficulty (0..levels).
  final Map<Difficulty, int> levelsPassed;

  /// Best solve time in seconds per difficulty.
  final Map<Difficulty, int> bestTimes;

  /// Fingerprints of every puzzle this player has received, so none repeats.
  final Set<String> playedPuzzles;

  /// True once the Master celebration screen has been shown.
  bool masterCelebrated;

  int passed(Difficulty d) => levelsPassed[d] ?? 0;

  bool isUnlocked(Difficulty d) {
    final prev = d.previous;
    return prev == null || passed(prev) >= prev.levels;
  }

  bool isCompleted(Difficulty d) => passed(d) >= d.levels;

  /// The next level to play in [d], or null when the tier is finished.
  int? currentLevel(Difficulty d) => isCompleted(d) ? null : passed(d) + 1;

  bool get isMaster => isCompleted(Difficulty.extreme);

  /// Records a win. Returns true if it set a new best time.
  bool recordWin(Difficulty d, int? level, int seconds) {
    if (level != null && level == currentLevel(d)) {
      levelsPassed[d] = level;
    }
    final best = bestTimes[d];
    if (best == null || seconds < best) {
      bestTimes[d] = seconds;
      return true;
    }
    return false;
  }

  /// Combines progress from another device: keeps the furthest level,
  /// the fastest time and every played puzzle.
  void mergeFrom(Progress other) {
    for (final d in Difficulty.values) {
      if (other.passed(d) > passed(d)) levelsPassed[d] = other.passed(d);
      final theirs = other.bestTimes[d];
      final mine = bestTimes[d];
      if (theirs != null && (mine == null || theirs < mine)) bestTimes[d] = theirs;
    }
    playedPuzzles.addAll(other.playedPuzzles);
    masterCelebrated = masterCelebrated || other.masterCelebrated;
  }

  Map<String, Object> toJson() => {
        'levelsPassed': {for (final e in levelsPassed.entries) e.key.name: e.value},
        'bestTimes': {for (final e in bestTimes.entries) e.key.name: e.value},
        'playedPuzzles': playedPuzzles.toList(),
        'masterCelebrated': masterCelebrated,
      };

  static Progress fromJson(Map<String, dynamic> j) {
    Map<Difficulty, int> readMap(Object? raw) {
      if (raw is! Map) return {};
      return {
        for (final e in raw.entries)
          if (e.value is num) Difficulty.fromName(e.key as String): (e.value as num).toInt(),
      };
    }

    final passed = {for (final d in Difficulty.values) d: 0}
      ..addAll(readMap(j['levelsPassed']));
    // Never trust stored data beyond each tier's level count.
    for (final d in Difficulty.values) {
      passed[d] = passed[d]!.clamp(0, d.levels);
    }
    return Progress(
      levelsPassed: passed,
      bestTimes: readMap(j['bestTimes']),
      playedPuzzles: Set<String>.from((j['playedPuzzles'] as List?) ?? const []),
      masterCelebrated: j['masterCelebrated'] == true,
    );
  }
}
