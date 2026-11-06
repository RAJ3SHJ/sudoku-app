import 'package:flutter/material.dart';

/// Colours used on the board, kept separate so light and dark mode each get
/// a matching set. Paper style with blue accents.
@immutable
class BoardColors extends ThemeExtension<BoardColors> {
  const BoardColors({
    required this.paper,
    required this.thinLine,
    required this.thickLine,
    required this.givenInk,
    required this.playerInk,
    required this.noteInk,
    required this.selected,
    required this.peer,
    required this.sameNumber,
    required this.error,
  });

  final Color paper;
  final Color thinLine;
  final Color thickLine;
  final Color givenInk;
  final Color playerInk;
  final Color noteInk;
  final Color selected;
  final Color peer;
  final Color sameNumber;
  final Color error;

  static const light = BoardColors(
    paper: Color(0xFFFFFDF6),
    thinLine: Color(0xFFCFC8B8),
    thickLine: Color(0xFF4A4637),
    givenInk: Color(0xFF26241F),
    playerInk: Color(0xFF1E5BB8),
    noteInk: Color(0xFF6B6658),
    selected: Color(0xFFCFE0F7),
    peer: Color(0xFFEDF1F6),
    sameNumber: Color(0xFFB9D0F2),
    error: Color(0xFFC62828),
  );

  static const dark = BoardColors(
    paper: Color(0xFF1C2028),
    thinLine: Color(0xFF353B47),
    thickLine: Color(0xFF8C94A3),
    givenInk: Color(0xFFE8E6E1),
    playerInk: Color(0xFF7AB0FF),
    noteInk: Color(0xFF9AA1AE),
    selected: Color(0xFF26446F),
    peer: Color(0xFF232935),
    sameNumber: Color(0xFF2F5288),
    error: Color(0xFFFF6B6B),
  );

  @override
  BoardColors copyWith() => this;

  @override
  BoardColors lerp(ThemeExtension<BoardColors>? other, double t) {
    if (other is! BoardColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return BoardColors(
      paper: mix(paper, other.paper),
      thinLine: mix(thinLine, other.thinLine),
      thickLine: mix(thickLine, other.thickLine),
      givenInk: mix(givenInk, other.givenInk),
      playerInk: mix(playerInk, other.playerInk),
      noteInk: mix(noteInk, other.noteInk),
      selected: mix(selected, other.selected),
      peer: mix(peer, other.peer),
      sameNumber: mix(sameNumber, other.sameNumber),
      error: mix(error, other.error),
    );
  }
}

class AppTheme {
  static const _blue = Color(0xFF1E5BB8);
  static const _blueDark = Color(0xFF7AB0FF);

  /// Serif type gives the board a printed-puzzle-book feel.
  static const numberFont = 'serif';

  static ThemeData light() => _build(
        brightness: Brightness.light,
        accent: _blue,
        background: const Color(0xFFF5F0E3),
        surface: const Color(0xFFFFFDF6),
        board: BoardColors.light,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        accent: _blueDark,
        background: const Color(0xFF14171D),
        surface: const Color(0xFF1C2028),
        board: BoardColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color accent,
    required Color background,
    required Color surface,
    required BoardColors board,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _blue,
      brightness: brightness,
    ).copyWith(primary: accent, surface: surface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: board.givenInk,
        elevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: accent),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      extensions: [board],
    );
  }
}

extension BoardColorsX on BuildContext {
  BoardColors get board => Theme.of(this).extension<BoardColors>()!;
}

String formatTime(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  final h = m ~/ 60;
  if (h > 0) return '$h:${(m % 60).toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
