import 'difficulty.dart';

enum GameStatus { playing, won, lost }

enum EntryResult { ignored, correct, wrong, completed }

/// One number placement, kept so it can be undone.
class _Move {
  _Move(this.cell, this.notesBefore, this.peerNotesBefore);

  final int cell;
  final int notesBefore;
  final Map<int, int> peerNotesBefore;

  Map<String, Object> toJson() => {
        'cell': cell,
        'notes': notesBefore,
        'peers': peerNotesBefore.map((k, v) => MapEntry(k.toString(), v)),
      };

  static _Move fromJson(Map<String, dynamic> j) => _Move(
        j['cell'] as int,
        j['notes'] as int,
        (j['peers'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), v as int)),
      );
}

/// The full state of one game and its rules. Contains no UI code, so it can
/// be saved, restored and unit tested on its own.
///
/// Rules (from the v1 spec):
/// - A wrong number ends the game immediately.
/// - 2 hints per puzzle; each fills in one correct cell.
/// - 1 undo per puzzle; it takes back a correct number placement.
class GameSession {
  GameSession({
    required this.difficulty,
    required this.levelNumber,
    required this.puzzle,
    required this.solution,
    List<int>? values,
    List<int>? notes,
    this.hintsLeft = maxHints,
    this.undosLeft = maxUndos,
    this.elapsedSeconds = 0,
    this.status = GameStatus.playing,
    this.wrongCell,
    this.wrongValue,
    List<_Move>? history,
  })  : values = values ?? List<int>.from(puzzle),
        notes = notes ?? List<int>.filled(81, 0),
        _history = history ?? [];

  static const maxHints = 2;
  static const maxUndos = 1;

  final Difficulty difficulty;

  /// Level being played, or null for free play.
  final int? levelNumber;
  final List<int> puzzle;
  final List<int> solution;
  final List<int> values;

  /// Pencil notes per cell as a bitmask: bit n set = note n shown.
  final List<int> notes;
  int hintsLeft;
  int undosLeft;
  int elapsedSeconds;
  GameStatus status;
  int? wrongCell;
  int? wrongValue;
  final List<_Move> _history;

  bool get isFreePlay => levelNumber == null;
  bool get canUndo => status == GameStatus.playing && undosLeft > 0 && _history.isNotEmpty;
  bool get canHint => status == GameStatus.playing && hintsLeft > 0;

  bool isGiven(int cell) => puzzle[cell] != 0;
  bool isFilled(int cell) => values[cell] != 0;
  bool hasNote(int cell, int n) => notes[cell] & (1 << n) != 0;

  /// How many of number [n] are already on the board (for the number pad).
  int countOf(int n) => values.where((v) => v == n).length;

  static Iterable<int> peersOf(int cell) sync* {
    final r = cell ~/ 9, c = cell % 9;
    final br = r ~/ 3 * 3, bc = c ~/ 3 * 3;
    final seen = <int>{};
    for (var k = 0; k < 9; k++) {
      seen.add(r * 9 + k);
      seen.add(k * 9 + c);
    }
    for (var rr = br; rr < br + 3; rr++) {
      for (var cc = bc; cc < bc + 3; cc++) {
        seen.add(rr * 9 + cc);
      }
    }
    seen.remove(cell);
    yield* seen;
  }

  EntryResult enterNumber(int cell, int n) {
    if (status != GameStatus.playing || isFilled(cell)) return EntryResult.ignored;

    if (solution[cell] != n) {
      status = GameStatus.lost;
      wrongCell = cell;
      wrongValue = n;
      return EntryResult.wrong;
    }

    _place(cell, n, record: true);
    if (_isComplete) {
      status = GameStatus.won;
      return EntryResult.completed;
    }
    return EntryResult.correct;
  }

  void toggleNote(int cell, int n) {
    if (status != GameStatus.playing || isFilled(cell)) return;
    notes[cell] ^= (1 << n);
  }

  void clearNotes(int cell) {
    if (status != GameStatus.playing || isFilled(cell)) return;
    notes[cell] = 0;
  }

  /// Takes back the last number placed. Returns false if not allowed.
  bool undo() {
    if (!canUndo) return false;
    final move = _history.removeLast();
    values[move.cell] = 0;
    notes[move.cell] = move.notesBefore;
    move.peerNotesBefore.forEach((peer, before) => notes[peer] = before);
    undosLeft--;
    return true;
  }

  /// Fills [preferredCell] if it is empty, otherwise the first empty cell.
  /// Returns the cell that was filled, or null if no hint was used.
  int? useHint(int? preferredCell) {
    if (!canHint) return null;
    int? cell;
    if (preferredCell != null && !isFilled(preferredCell)) {
      cell = preferredCell;
    } else {
      for (var i = 0; i < 81; i++) {
        if (!isFilled(i)) {
          cell = i;
          break;
        }
      }
    }
    if (cell == null) return null;
    // Hinted cells cannot be undone, so they are not recorded in history.
    _place(cell, solution[cell], record: false);
    hintsLeft--;
    if (_isComplete) status = GameStatus.won;
    return cell;
  }

  void _place(int cell, int n, {required bool record}) {
    final peerBefore = <int, int>{};
    for (final p in peersOf(cell)) {
      if (hasNote(p, n)) {
        peerBefore[p] = notes[p];
        notes[p] &= ~(1 << n);
      }
    }
    if (record) _history.add(_Move(cell, notes[cell], peerBefore));
    values[cell] = n;
    notes[cell] = 0;
  }

  bool get _isComplete {
    for (var i = 0; i < 81; i++) {
      if (values[i] != solution[i]) return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'difficulty': difficulty.name,
        'level': levelNumber,
        'puzzle': puzzle,
        'solution': solution,
        'values': values,
        'notes': notes,
        'hints': hintsLeft,
        'undos': undosLeft,
        'elapsed': elapsedSeconds,
        'history': _history.map((m) => m.toJson()).toList(),
      };

  static GameSession fromJson(Map<String, dynamic> j) => GameSession(
        difficulty: Difficulty.fromName(j['difficulty'] as String),
        levelNumber: j['level'] as int?,
        puzzle: List<int>.from(j['puzzle'] as List),
        solution: List<int>.from(j['solution'] as List),
        values: List<int>.from(j['values'] as List),
        notes: List<int>.from(j['notes'] as List),
        hintsLeft: j['hints'] as int,
        undosLeft: j['undos'] as int,
        elapsedSeconds: j['elapsed'] as int,
        history: (j['history'] as List)
            .map((m) => _Move.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList(),
      );
}
