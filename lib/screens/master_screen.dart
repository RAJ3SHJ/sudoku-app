import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';

/// Shown once, after Extremely Hard level 40 is passed.
class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AppState>().markMasterCelebrated();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blue = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.workspace_premium, size: 120, color: blue),
              const SizedBox(height: 24),
              Text(
                'Master Sudoku Player',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: AppTheme.numberFont,
                  fontWeight: FontWeight.w700,
                  color: context.board.givenInk,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You passed all 100 levels, including 40 Extremely Hard puzzles.\n\n'
                'Free play is now open on every difficulty, with a fresh puzzle every time.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: context.board.noteInk),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
