import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import 'difficulty_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openDifficulties(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DifficultyScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final saved = state.savedGame;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Sudoku',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontFamily: AppTheme.numberFont,
                  fontWeight: FontWeight.w600,
                  color: context.board.givenInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.progress.isMaster ? 'Master Sudoku Player' : 'Fresh puzzle every time',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: state.progress.isMaster ? theme.colorScheme.primary : context.board.noteInk,
                  fontWeight: state.progress.isMaster ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              if (state.progress.isMaster) ...[
                const SizedBox(height: 12),
                Icon(Icons.workspace_premium, size: 56, color: theme.colorScheme.primary),
              ],
              const Spacer(),
              if (saved != null) ...[
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GameScreen(session: saved)),
                  ),
                  child: Text(
                    'Continue · ${saved.difficulty.label}'
                    '${saved.levelNumber != null ? ' ${saved.levelNumber}' : ''}',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (saved == null)
                FilledButton(
                  onPressed: () => _openDifficulties(context),
                  child: const Text('Play'),
                )
              else
                OutlinedButton(
                  onPressed: () => _openDifficulties(context),
                  child: const Text('New game'),
                ),
              const SizedBox(height: 24),
              if (state.signInAvailable) const _AccountCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    if (user == null) {
      return TextButton.icon(
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Continue with Google to back up progress'),
        onPressed: () async {
          try {
            await state.signIn();
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sign-in failed. Check your connection and try again.')),
            );
          }
        },
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          state.syncing ? Icons.cloud_sync_outlined : Icons.cloud_done_outlined,
          size: 18,
          color: context.board.noteInk,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            state.syncing
                ? 'Syncing…'
                : 'Backed up · ${user.displayName ?? user.email ?? 'Google account'}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.board.noteInk),
          ),
        ),
      ],
    );
  }
}
