import 'package:flutter/material.dart';

import '../core/game_session.dart';
import '../theme/app_theme.dart';

/// The 9x9 board, drawn in one pass for smooth performance.
class SudokuBoard extends StatelessWidget {
  const SudokuBoard({
    super.key,
    required this.session,
    required this.selected,
    required this.onCellTap,
    this.hidden = false,
  });

  final GameSession session;
  final int? selected;
  final ValueChanged<int> onCellTap;

  /// True while paused: the numbers are hidden so the board can't be studied.
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          return GestureDetector(
            onTapDown: hidden
                ? null
                : (d) {
                    final cellSize = size / 9;
                    final c = (d.localPosition.dx / cellSize).floor().clamp(0, 8);
                    final r = (d.localPosition.dy / cellSize).floor().clamp(0, 8);
                    onCellTap(r * 9 + c);
                  },
            child: CustomPaint(
              size: Size.square(size),
              painter: _BoardPainter(
                session: session,
                selected: selected,
                colors: context.board,
                hidden: hidden,
                // Repaint whenever anything visible changes.
                signature: Object.hashAll([
                  ...session.values,
                  ...session.notes,
                  selected,
                  hidden,
                  session.wrongCell,
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.session,
    required this.selected,
    required this.colors,
    required this.hidden,
    required this.signature,
  });

  final GameSession session;
  final int? selected;
  final BoardColors colors;
  final bool hidden;
  final int signature;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 9;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = colors.paper,
    );

    if (!hidden) _paintHighlights(canvas, cell);
    _paintLines(canvas, size, cell);
    if (!hidden) _paintNumbers(canvas, cell);
  }

  void _paintHighlights(Canvas canvas, double cell) {
    final sel = selected;
    final selValue = sel == null ? 0 : session.values[sel];
    final peers = sel == null ? const <int>{} : GameSession.peersOf(sel).toSet();

    for (var i = 0; i < 81; i++) {
      Color? fill;
      if (i == session.wrongCell) {
        fill = colors.error.withValues(alpha: 0.18);
      } else if (i == sel) {
        fill = colors.selected;
      } else if (selValue != 0 && session.values[i] == selValue) {
        fill = colors.sameNumber;
      } else if (peers.contains(i)) {
        fill = colors.peer;
      }
      if (fill == null) continue;
      final r = i ~/ 9, c = i % 9;
      canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), Paint()..color = fill);
    }
  }

  void _paintLines(Canvas canvas, Size size, double cell) {
    final thin = Paint()
      ..color = colors.thinLine
      ..strokeWidth = 1;
    final thick = Paint()
      ..color = colors.thickLine
      ..strokeWidth = 2;

    for (var k = 1; k < 9; k++) {
      final p = k % 3 == 0 ? thick : thin;
      final o = k * cell;
      canvas.drawLine(Offset(o, 0), Offset(o, size.height), p);
      canvas.drawLine(Offset(0, o), Offset(size.width, o), p);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius((Offset.zero & size).deflate(1), const Radius.circular(6)),
      Paint()
        ..color = colors.thickLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintNumbers(Canvas canvas, double cell) {
    for (var i = 0; i < 81; i++) {
      final r = i ~/ 9, c = i % 9;
      final origin = Offset(c * cell, r * cell);

      if (i == session.wrongCell && session.wrongValue != null) {
        _drawCentered(canvas, '${session.wrongValue}', origin, cell, colors.error, FontWeight.w600);
        continue;
      }

      final v = session.values[i];
      if (v != 0) {
        final given = session.isGiven(i);
        _drawCentered(
          canvas,
          '$v',
          origin,
          cell,
          given ? colors.givenInk : colors.playerInk,
          given ? FontWeight.w700 : FontWeight.w500,
        );
      } else if (session.notes[i] != 0) {
        final sub = cell / 3;
        for (var n = 1; n <= 9; n++) {
          if (!session.hasNote(i, n)) continue;
          final nr = (n - 1) ~/ 3, nc = (n - 1) % 3;
          _drawCentered(
            canvas,
            '$n',
            origin + Offset(nc * sub, nr * sub),
            sub,
            colors.noteInk,
            FontWeight.w500,
          );
        }
      }
    }
  }

  void _drawCentered(Canvas canvas, String text, Offset origin, double box, Color color, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppTheme.numberFont,
          fontSize: box * 0.62,
          fontWeight: weight,
          color: color,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, origin + Offset((box - tp.width) / 2, (box - tp.height) / 2));
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.signature != signature || old.colors != colors || old.hidden != hidden;
}
