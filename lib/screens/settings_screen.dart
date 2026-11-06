import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _Header('Appearance'),
          RadioGroup<ThemeMode>(
            groupValue: state.themeMode,
            onChanged: (m) {
              if (m != null) state.setThemeMode(m);
            },
            child: const Column(
              children: [
                RadioListTile(value: ThemeMode.system, title: Text('Match phone setting')),
                RadioListTile(value: ThemeMode.light, title: Text('Light (paper)')),
                RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
              ],
            ),
          ),
          if (state.signInAvailable) ...[
            const _Header('Account'),
            if (user == null)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Continue with Google'),
                subtitle: const Text('Back up progress and keep it on a new phone'),
                onTap: () => state.signIn().catchError((_) {}),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(user.displayName ?? 'Google account'),
                subtitle: Text(user.email ?? ''),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                subtitle: const Text('Progress stays on this phone'),
                onTap: state.signOut,
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: Text('Delete account',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                subtitle: const Text('Removes your account, cloud backup and progress'),
                onTap: () => _confirmDelete(context, state),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account, your cloud backup and all '
          'progress on this phone. It cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await state.deleteAccount();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Account deleted')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the account. Try again online.')),
        );
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
