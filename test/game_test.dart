import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/core/difficulty.dart';
import 'package:sudoku_app/core/game_session.dart';
import 'package:sudoku_app/core/progress.dart';
import 'package:sudoku_app/core/sudoku_generator.dart';

void main() {
  group('Generator', () {
    for (final d in Difficulty.values) {
      test('${d.label} puzzles have one solution and the right clue count', () {
        final gen = SudokuGenerator(Random(d.index + 7));
        final p = gen.generate(minClues: d.minClues, maxClues: d.maxClues);
        expect(SudokuGenerator.countSolutions(List<int>.from(p.puzzle), 2), 1);
        expect(p.clueCount, lessThanOrEqualTo(d.maxClues + 3));
        expect(p.clueCount, greaterThanOrEqualTo(d.minClues));
        for (var i = 0; i < 81; i++) {
          if (p.puzzle[i] != 0) expect(p.puzzle[i], p.solution[i]);
        }
      });
    }

    test('never returns a puzzle already played', () {
      final gen = SudokuGenerator(Random(1));
      final first = gen.generate(minClues: 38, maxClues: 42);
      final second = SudokuGenerator(Random(1))
          .generate(minClues: 38, maxClues: 42, usedFingerprints: {first.fingerprint});
      expect(second.fingerprint, isNot(first.fingerprint));
    });
  });

  group('Game rules', () {
    late GameSession s;
    setUp(() {
      final p = SudokuGenerator(Random(3)).generate(minClues: 40, maxClues: 40);
      s = GameSession(
        difficulty: Difficulty.easy,
        levelNumber: 1,
        puzzle: p.puzzle,
        solution: p.solution,
      );
    });

    int firstEmpty() => s.values.indexOf(0);

    test('a wrong number ends the game', () {
      final cell = firstEmpty();
      final wrong = s.solution[cell] % 9 + 1;
      expect(s.enterNumber(cell, wrong), EntryResult.wrong);
      expect(s.status, GameStatus.lost);
    });

    test('one undo takes back a correct number', () {
      final cell = firstEmpty();
      s.enterNumber(cell, s.solution[cell]);
      expect(s.undo(), isTrue);
      expect(s.values[cell], 0);
      final again = firstEmpty();
      s.enterNumber(again, s.solution[again]);
      expect(s.undo(), isFalse, reason: 'only one undo per puzzle');
    });

    test('two hints, each fills one correct cell', () {
      expect(s.useHint(null), isNotNull);
      expect(s.useHint(null), isNotNull);
      expect(s.useHint(null), isNull);
      expect(s.hintsLeft, 0);
    });

    test('filling every cell wins', () {
      EntryResult? last;
      for (var i = 0; i < 81; i++) {
        if (s.values[i] == 0) last = s.enterNumber(i, s.solution[i]);
      }
      expect(last, EntryResult.completed);
      expect(s.status, GameStatus.won);
    });

    test('save and restore keeps the game', () {
      final cell = firstEmpty();
      s.toggleNote(cell, 5);
      s.elapsedSeconds = 42;
      final copy = GameSession.fromJson(Map<String, dynamic>.from(s.toJson()));
      expect(copy.hasNote(cell, 5), isTrue);
      expect(copy.elapsedSeconds, 42);
    });
  });

  group('Progression', () {
    test('tiers unlock in order: 20, 20, 20, then 40 to Master', () {
      final p = Progress();
      expect(p.isUnlocked(Difficulty.medium), isFalse);
      for (var l = 1; l <= 20; l++) {
        p.recordWin(Difficulty.easy, l, 100);
      }
      expect(p.isUnlocked(Difficulty.medium), isTrue);
      expect(p.isUnlocked(Difficulty.hard), isFalse);

      p.levelsPassed[Difficulty.medium] = 20;
      p.levelsPassed[Difficulty.hard] = 20;
      for (var l = 1; l <= 40; l++) {
        p.recordWin(Difficulty.extreme, l, 300);
      }
      expect(p.isMaster, isTrue);
    });

    test('replaying a passed level does not skip ahead', () {
      final p = Progress()..levelsPassed[Difficulty.easy] = 5;
      p.recordWin(Difficulty.easy, 2, 100);
      expect(p.passed(Difficulty.easy), 5);
    });

    test('best time keeps the fastest', () {
      final p = Progress();
      expect(p.recordWin(Difficulty.easy, null, 200), isTrue);
      expect(p.recordWin(Difficulty.easy, null, 250), isFalse);
      expect(p.recordWin(Difficulty.easy, null, 150), isTrue);
      expect(p.bestTimes[Difficulty.easy], 150);
    });
  });
}
