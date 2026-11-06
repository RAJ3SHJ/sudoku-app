import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../core/difficulty.dart';
import 'game_screen.dart';

/// Generates a fresh puzzle and opens it. [level] is null for free play.
/// Asks first if starting would discard an unfinished game.
Future<void> launchGame(
  BuildContext context,
  Difficulty difficulty,
  int? level, {
  bool replace = false,
}) async {
  final state = context.read<AppState>();

  if (state.savedGame != null && !replace) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a new game?'),
        content: const Text('Your unfinished game will be discarded.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start new')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }

  final navigator = Navigator.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  final session = await state.startGame(difficulty, level);
  navigator.pop(); // close the loading spinner

  final route = MaterialPageRoute<void>(builder: (_) => GameScreen(session: session));
  if (replace) {
    await navigator.pushReplacement(route);
  } else {
    await navigator.push(route);
  }
}
