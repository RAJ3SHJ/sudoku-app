import 'dart:math';

import 'package:flutter/foundation.dart';

import 'difficulty.dart';

/// A generated puzzle. Cells are stored row by row (index = row * 9 + col).
/// 0 means an empty cell in [puzzle].
class GeneratedPuzzle {
  GeneratedPuzzle(this.puzzle, this.solution);

  final List<int> puzzle;
  final List<int> solution;

  int get clueCount => puzzle.where((v) => v != 0).length;

  /// Short, stable ID for this puzzle, used to make sure a player never gets
  /// the same puzzle twice (FNV-1a hash of the 81 cells, as hex).
  String get fingerprint => fingerprintOf(puzzle);

  static String fingerprintOf(List<int> cells) {
    // 64-bit FNV-1a, kept inside 63 bits so it is safe on every platform.
    var hash = 0x4bf29ce484222325;
    const prime = 0x100000001b3;
    for (final v in cells) {
      hash ^= v;
      hash = (hash * prime) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16);
  }
}

/// Generates a puzzle for [difficulty] that is not in [usedFingerprints].
///
/// Runs on a background isolate so the UI never freezes, even for
/// Extremely Hard puzzles that take more work to find.
Future<GeneratedPuzzle> generatePuzzle(
  Difficulty difficulty,
  Set<String> usedFingerprints,
) async {
  final result = await compute(_generateInIsolate, <String, Object>{
    'min': difficulty.minClues,
    'max': difficulty.maxClues,
    'used': usedFingerprints.toList(),
    'seed': DateTime.now().microsecondsSinceEpoch,
  });
  return GeneratedPuzzle(
    List<int>.from(result['puzzle'] as List),
    List<int>.from(result['solution'] as List),
  );
}

Map<String, List<int>> _generateInIsolate(Map<String, Object> args) {
  final gen = SudokuGenerator(Random(args['seed'] as int));
  final used = Set<String>.from(args['used'] as List);
  final p = gen.generate(
    minClues: args['min'] as int,
    maxClues: args['max'] as int,
    usedFingerprints: used,
  );
  return {'puzzle': p.puzzle, 'solution': p.solution};
}

/// Pure Dart Sudoku generator. Every puzzle it returns has exactly one solution.
class SudokuGenerator {
  SudokuGenerator([Random? random]) : _rng = random ?? Random();

  final Random _rng;

  GeneratedPuzzle generate({
    required int minClues,
    required int maxClues,
    Set<String> usedFingerprints = const {},
  }) {
    // Pick a target inside the range so puzzles vary.
    final target = minClues + _rng.nextInt(maxClues - minClues + 1);
    GeneratedPuzzle? best;

    // Hard targets (around 23 clues) are not always reachable from a given
    // grid, so try a few grids and keep the one with the fewest clues.
    for (var attempt = 0; attempt < 8; attempt++) {
      final candidate = _carve(target);
      if (usedFingerprints.contains(candidate.fingerprint)) continue;
      if (best == null || candidate.clueCount < best.clueCount) best = candidate;
      if (best.clueCount <= maxClues) break;
    }

    // Practically impossible, but never return a repeat.
    while (best == null || usedFingerprints.contains(best.fingerprint)) {
      best = _carve(target);
    }
    return best;
  }

  /// Builds a full random grid, then removes numbers one at a time, keeping
  /// each removal only if the puzzle still has a single solution.
  GeneratedPuzzle _carve(int targetClues) {
    final grid = List<int>.filled(81, 0);
    _fill(grid);
    final solution = List<int>.from(grid);

    final order = List<int>.generate(81, (i) => i)..shuffle(_rng);
    var clues = 81;
    for (final i in order) {
      if (clues <= targetClues) break;
      final saved = grid[i];
      grid[i] = 0;
      if (countSolutions(List<int>.from(grid), 2) == 1) {
        clues--;
      } else {
        grid[i] = saved;
      }
    }
    return GeneratedPuzzle(grid, solution);
  }

  bool _fill(List<int> g) {
    for (var i = 0; i < 81; i++) {
      if (g[i] != 0) continue;
      final options = candidates(g, i)..shuffle(_rng);
      for (final v in options) {
        g[i] = v;
        if (_fill(g)) return true;
      }
      g[i] = 0;
      return false;
    }
    return true;
  }

  /// Numbers that can legally go in cell [i] of grid [g].
  static List<int> candidates(List<int> g, int i) {
    final r = i ~/ 9, c = i % 9;
    final used = List<bool>.filled(10, false);
    for (var k = 0; k < 9; k++) {
      used[g[r * 9 + k]] = true;
      used[g[k * 9 + c]] = true;
    }
    final br = r ~/ 3 * 3, bc = c ~/ 3 * 3;
    for (var rr = br; rr < br + 3; rr++) {
      for (var cc = bc; cc < bc + 3; cc++) {
        used[g[rr * 9 + cc]] = true;
      }
    }
    return [for (var v = 1; v <= 9; v++) if (!used[v]) v];
  }

  /// Counts solutions of [g], stopping early once [limit] is reached.
  static int countSolutions(List<int> g, int limit) {
    var bestCell = -1;
    List<int>? bestOptions;
    for (var i = 0; i < 81; i++) {
      if (g[i] != 0) continue;
      final options = candidates(g, i);
      if (options.isEmpty) return 0;
      if (bestOptions == null || options.length < bestOptions.length) {
        bestCell = i;
        bestOptions = options;
        if (options.length == 1) break;
      }
    }
    if (bestCell == -1) return 1; // grid is full: one solution found

    var found = 0;
    for (final v in bestOptions!) {
      g[bestCell] = v;
      found += countSolutions(g, limit - found);
      g[bestCell] = 0;
      if (found >= limit) break;
    }
    return found;
  }
}
