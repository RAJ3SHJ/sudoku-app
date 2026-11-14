import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'core/local_store.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // Firebase is optional at runtime: if it is not configured yet, the game
  // still runs fully offline and the Google sign-in button is hidden.
  // The web build is a preview only, so it skips Firebase.
  var firebaseReady = false;
  if (!kIsWeb) {
    try {
      // On Android this reads android/app/google-services.json,
      // which `flutterfire configure` creates.
      await Firebase.initializeApp().timeout(const Duration(seconds: 8));
      firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase not configured, running offline only: $e');
    }
  }

  final store = await LocalStore.open();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        store: store,
        auth: AuthService(available: firebaseReady),
      ),
      child: const SudokuApp(),
    ),
  );
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: 'Sudoku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
