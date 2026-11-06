import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tool row (undo, erase, notes, hint) plus the 1-9 number buttons.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.onNumber,
    required this.onUndo,
    required this.onErase,
    required this.onToggleNotes,
    required this.onHint,
    required this.notesMode,
    required this.undosLeft,
    required this.hintsLeft,
    required this.completedNumbers,
    this.enabled = true,
  });

  final ValueChanged<int> onNumber;
  final VoidCallback? onUndo;
  final VoidCallback onErase;
  final VoidCallback onToggleNotes;
  final VoidCallback? onHint;
  final bool notesMode;
  final int undosLeft;
  final int hintsLeft;

  /// Numbers already placed 9 times; their buttons are dimmed.
  final Set<int> completedNumbers;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final blue = Theme.of(context).colorScheme.primary;
    final board = context.board;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Tool(icon: Icons.undo, label: 'Undo', badge: '$undosLeft', onTap: enabled ? onUndo : null),
            _Tool(icon: Icons.backspace_outlined, label: 'Erase', onTap: enabled ? onErase : null),
            _Tool(
              icon: Icons.edit_outlined,
              label: notesMode ? 'Notes on' : 'Notes',
              active: notesMode,
              onTap: enabled ? onToggleNotes : null,
            ),
            _Tool(icon: Icons.lightbulb_outline, label: 'Hint', badge: '$hintsLeft', onTap: enabled ? onHint : null),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var n = 1; n <= 9; n++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AspectRatio(
                    aspectRatio: 0.8,
                    child: Material(
                      color: board.paper,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: enabled && !completedNumbers.contains(n) ? () => onNumber(n) : null,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: board.thinLine),
                          ),
                          child: Text(
                            '$n',
                            style: TextStyle(
                              fontFamily: AppTheme.numberFont,
                              fontSize: notesMode ? 20 : 28,
                              fontWeight: FontWeight.w600,
                              color: completedNumbers.contains(n)
                                  ? board.thinLine
                                  : (notesMode ? board.noteInk : blue),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, this.badge, this.active = false, this.onTap});

  final IconData icon;
  final String label;
  final String? badge;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final blue = Theme.of(context).colorScheme.primary;
    final board = context.board;
    final color = onTap == null ? board.thinLine : (active ? blue : board.givenInk);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badge != null,
              label: Text(badge ?? ''),
              backgroundColor: blue,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
