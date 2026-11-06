import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../core/game_session.dart';
import '../theme/app_theme.dart';
import '../widgets/number_pad.dart';
import '../widgets/sudoku_board.dart';
import 'launch.dart';
import 'master_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.session});

  final GameSession session;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameSession s = widget.session;
  late final AppState app;
  Timer? _ticker;
  int? _selected;
  bool _notesMode = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    app = context.read<AppState>();
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    // Save without notifying listeners: the widget tree is locked here.
    if (s.status == GameStatus.playing) app.store.saveGame(s);
    super.dispose();
  }

  /// Pause and save whenever the player leaves the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && s.status == GameStatus.playing) {
      if (!_paused) setState(() => _paused = true);
      _ticker?.cancel();
      app.saveGame(s);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && s.status == GameStatus.playing && mounted) {
        setState(() => s.elapsedSeconds++);
      }
    });
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _ticker?.cancel();
      app.saveGame(s);
    } else {
      _startTicker();
    }
  }

  // ---------- Player actions ----------

  void _onNumber(int n) {
    final cell = _selected;
    if (cell == null || s.status != GameStatus.playing) return;

    if (_notesMode) {
      setState(() => s.toggleNote(cell, n));
      app.saveGame(s);
      return;
    }

    final result = s.enterNumber(cell, n);
    setState(() {});
    switch (result) {
      case EntryResult.wrong:
        _onLost();
      case EntryResult.completed:
        _onWon();
      case EntryResult.correct:
        app.saveGame(s);
      case EntryResult.ignored:
        break;
    }
  }

  void _onUndo() {
    if (s.undo()) {
      setState(() {});
      app.saveGame(s);
    }
  }

  void _onErase() {
    final cell = _selected;
    if (cell == null) return;
    setState(() => s.clearNotes(cell));
    app.saveGame(s);
  }

  void _onHint() {
    final cell = s.useHint(_selected);
    if (cell == null) return;
    setState(() => _selected = cell);
    if (s.status == GameStatus.won) {
      _onWon();
    } else {
      app.saveGame(s);
    }
  }

  // ---------- End of game ----------

  Future<void> _onLost() async {
    _ticker?.cancel();
    await app.gameLost();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Game over'),
        content: Text(
          'That number was wrong. One mistake ends the game.\n\n'
          '${s.isFreePlay ? 'Try another puzzle?' : 'Try level ${s.levelNumber} again with a fresh puzzle?'}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Home')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Retry')),
        ],
      ),
    );
    if (!mounted) return;
    if (retry == true) {
      await launchGame(context, s.difficulty, s.levelNumber, replace: true);
    } else {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _onWon() async {
    _ticker?.cancel();
    final outcome = await app.gameWon(s);
    if (!mounted) return;

    if (outcome.becameMaster) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MasterScreen()),
      );
      return;
    }

    final progress = app.progress;
    final nextLevel = progress.currentLevel(s.difficulty);
    final nextDifficulty = outcome.tierCompleted && s.difficulty.index < 3
        ? s.difficulty.index + 1
        : null;

    final action = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _WinSheet(
        title: s.isFreePlay ? 'Solved!' : 'Level ${s.levelNumber} complete',
        seconds: outcome.seconds,
        newBest: outcome.newBest,
        bestTime: progress.bestTimes[s.difficulty],
        unlockedMessage: nextDifficulty == null
            ? null
            : '${s.difficulty.label} completed. New difficulty unlocked!',
        primaryLabel: s.isFreePlay
            ? 'New puzzle'
            : (nextLevel != null ? 'Next level' : null),
      ),
    );
    if (!mounted) return;

    if (action == 'next') {
      await launchGame(context, s.difficulty, s.isFreePlay ? null : nextLevel, replace: true);
    } else {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  // ---------- Layout ----------

  @override
  Widget build(BuildContext context) {
    final board = context.board;
    final title = s.isFreePlay
        ? '${s.difficulty.label} · Free play'
        : '${s.difficulty.label} · Level ${s.levelNumber}';
    final playing = s.status == GameStatus.playing;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        actions: [
          if (playing)
            IconButton(
              tooltip: _paused ? 'Resume' : 'Pause',
              icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
              onPressed: _togglePause,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hints ${s.hintsLeft}', style: TextStyle(color: board.noteInk)),
                    Text(
                      formatTime(s.elapsedSeconds),
                      style: TextStyle(
                        fontFamily: AppTheme.numberFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: board.givenInk,
                      ),
                    ),
                    Text('Undo ${s.undosLeft}', style: TextStyle(color: board.noteInk)),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SudokuBoard(
                    session: s,
                    selected: _selected,
                    hidden: _paused,
                    onCellTap: (c) => setState(() => _selected = c),
                  ),
                  if (_paused) _PausedOverlay(onResume: _togglePause),
                ],
              ),
              const Spacer(),
              NumberPad(
                enabled: playing && !_paused,
                notesMode: _notesMode,
                undosLeft: s.undosLeft,
                hintsLeft: s.hintsLeft,
                completedNumbers: {for (var n = 1; n <= 9; n++) if (s.countOf(n) >= 9) n},
                onNumber: _onNumber,
                onUndo: s.canUndo ? _onUndo : null,
                onErase: _onErase,
                onToggleNotes: () => setState(() => _notesMode = !_notesMode),
                onHint: s.canHint ? _onHint : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Paused', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: context.board.givenInk)),
        const SizedBox(height: 16),
        SizedBox(
          width: 180,
          child: FilledButton(onPressed: onResume, child: const Text('Resume')),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: const Text('Quit to home'),
        ),
      ],
    );
  }
}

class _WinSheet extends StatelessWidget {
  const _WinSheet({
    required this.title,
    required this.seconds,
    required this.newBest,
    required this.bestTime,
    required this.unlockedMessage,
    required this.primaryLabel,
  });

  final String title;
  final int seconds;
  final bool newBest;
  final int? bestTime;
  final String? unlockedMessage;
  final String? primaryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blue = theme.colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              formatTime(seconds),
              style: TextStyle(fontFamily: AppTheme.numberFont, fontSize: 40, fontWeight: FontWeight.w700, color: blue),
            ),
            const SizedBox(height: 8),
            if (newBest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(20)),
                child: Text('New best time!', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700)),
              )
            else if (bestTime != null)
              Text('Best time ${formatTime(bestTime!)}', style: TextStyle(color: context.board.noteInk)),
            if (unlockedMessage != null) ...[
              const SizedBox(height: 12),
              Text(unlockedMessage!, textAlign: TextAlign.center, style: TextStyle(color: blue, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 24),
            if (primaryLabel != null) ...[
              FilledButton(onPressed: () => Navigator.pop(context, 'next'), child: Text(primaryLabel!)),
              const SizedBox(height: 8),
            ],
            OutlinedButton(onPressed: () => Navigator.pop(context, 'home'), child: const Text('Home')),
          ],
        ),
      ),
    );
  }
}
