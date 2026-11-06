import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../core/difficulty.dart';
import '../theme/app_theme.dart';
import 'launch.dart';

class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key, required this.difficulty});

  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<AppState>().progress;
    final current = progress.currentLevel(difficulty);
    final passed = progress.passed(difficulty);

    return Scaffold(
      appBar: AppBar(title: Text(difficulty.label)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: difficulty.levels,
                itemBuilder: (context, i) {
                  final level = i + 1;
                  final state = level <= passed
                      ? _LevelState.passed
                      : level == current
                          ? _LevelState.current
                          : _LevelState.locked;
                  return _LevelTile(
                    level: level,
                    state: state,
                    onTap: state == _LevelState.locked
                        ? null
                        : () => launchGame(context, difficulty, level),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  if (current != null)
                    FilledButton(
                      onPressed: () => launchGame(context, difficulty, current),
                      child: Text('Play level $current'),
                    ),
                  if (progress.isMaster) ...[
                    if (current != null) const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => launchGame(context, difficulty, null),
                      child: const Text('Free play'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LevelState { passed, current, locked }

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.state, this.onTap});

  final int level;
  final _LevelState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final board = context.board;
    final blue = Theme.of(context).colorScheme.primary;

    final (Color fill, Color border, Color ink) = switch (state) {
      _LevelState.current => (blue, blue, Theme.of(context).colorScheme.onPrimary),
      _LevelState.passed => (board.selected, blue, board.givenInk),
      _LevelState.locked => (board.paper, board.thinLine, board.noteInk),
    };

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: state == _LevelState.locked ? 1 : 1.5),
          ),
          alignment: Alignment.center,
          child: state == _LevelState.locked
              ? Icon(Icons.lock_outline, size: 18, color: ink)
              : Text(
                  '$level',
                  style: TextStyle(
                    fontFamily: AppTheme.numberFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
        ),
      ),
    );
  }
}
