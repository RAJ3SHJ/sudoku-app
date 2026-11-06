import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../core/difficulty.dart';
import '../theme/app_theme.dart';
import 'level_map_screen.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<AppState>().progress;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose difficulty')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final d in Difficulty.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DifficultyCard(
                difficulty: d,
                unlocked: progress.isUnlocked(d),
                passed: progress.passed(d),
                bestTime: progress.bestTimes[d],
              ),
            ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.difficulty,
    required this.unlocked,
    required this.passed,
    required this.bestTime,
  });

  final Difficulty difficulty;
  final bool unlocked;
  final int passed;
  final int? bestTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final board = context.board;
    final done = passed >= difficulty.levels;
    final prev = difficulty.previous;

    final subtitle = !unlocked
        ? 'Pass ${prev!.label} level ${prev.levels} to unlock'
        : done
            ? 'Completed · ${difficulty.levels} levels'
            : 'Level ${passed + 1} of ${difficulty.levels}';

    return Opacity(
      opacity: unlocked ? 1 : 0.5,
      child: Material(
        color: board.paper,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: unlocked
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LevelMapScreen(difficulty: difficulty)),
                  )
              : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: board.thinLine),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        difficulty.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: board.givenInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: board.noteInk)),
                      if (unlocked) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: passed / difficulty.levels,
                            minHeight: 6,
                            backgroundColor: board.peer,
                          ),
                        ),
                      ],
                      if (bestTime != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Best time ${formatTime(bestTime!)}',
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  !unlocked ? Icons.lock_outline : (done ? Icons.check_circle : Icons.chevron_right),
                  color: done ? theme.colorScheme.primary : board.noteInk,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
