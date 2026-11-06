# Sudoku App (v1)

Classic Sudoku for Android, built in Flutter. 100 levels across four difficulties,
a fresh puzzle every game, optional Google sign-in with cloud backup.

## What's in v1

- **Difficulties:** Easy (20 levels), Medium (20), Hard (20), Extremely Hard (40).
  Each unlocks after every level of the one before is passed.
- **Master Sudoku Player** badge after Extremely Hard level 40, then free play on any difficulty.
- **Rules:** one wrong number ends the game · 2 hints per puzzle (each fills one cell) ·
  1 undo per puzzle · no time limit, best time per difficulty with a "New best time!" popup.
- **Helpers:** pencil notes, highlighting, pause (board hidden), auto-save and resume.
- **Puzzles:** generated on the phone, each with exactly one solution, never repeated for a player.
- **Look:** paper style with blue accents, plus dark mode.
- **Google sign-in (optional):** players start as guests; signing in backs up progress
  to the cloud and restores it on a new phone. Includes in-app account deletion.
- **Offline:** the whole game works without internet. Firebase is only used for sign-in and backup.

## Project layout

```
lib/
  main.dart                 app start; Firebase is optional at runtime
  app_state.dart            progress, settings, saved game, sign-in and sync
  core/
    difficulty.dart         the four tiers: level counts and clue ranges
    sudoku_generator.dart   unique-solution generator (runs off the UI thread)
    game_session.dart       one game and its rules (mistake, hints, undo, notes)
    progress.dart           levels passed, best times, played puzzles, merge logic
    local_store.dart        saves everything on the phone
  services/
    auth_service.dart       Google sign-in via Firebase Authentication
    cloud_sync.dart         backup to Cloud Firestore at users/{uid}
  screens/                  home, difficulty, level map, game, master, settings
  widgets/                  board and number pad
  theme/app_theme.dart      paper + blue light theme, dark theme
test/game_test.dart         generator, rules and progression tests
firestore.rules             database security rules
```

## 1. Run it locally (no Firebase needed yet)

You need the Flutter SDK (stable, 3.35 or newer) and Android Studio with an emulator or a phone.

```bash
cd sudoku_app
# Creates the android/ folder. Your lib/ code is not touched.
flutter create --platforms=android --org com.yourname .
flutter pub get
flutter test
flutter run
```

Then open `android/app/build.gradle.kts` (or `build.gradle`) and set:

```
minSdk = 24
```

The game runs fully. The Google sign-in button stays hidden until Firebase is set up.

## 2. Turn on Google sign-in and cloud backup

1. Go to the [Firebase console](https://console.firebase.google.com) and create a project.
2. **Authentication → Sign-in method →** enable **Google**.
3. **Firestore Database →** create a database in production mode (choose a region near your players, e.g. `asia-south1` for India).
4. Connect the app:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android
   ```
   This creates `android/app/google-services.json` and wires up Gradle.
5. Add your signing fingerprints to the Android app in Firebase
   (**Project settings → Your apps → Add fingerprint**):
   ```bash
   cd android && ./gradlew signingReport
   ```
   Add both SHA-1 and SHA-256. Repeat later with your release key and the Play App Signing key.
6. Publish the security rules: paste `firestore.rules` into **Firestore → Rules**, or run
   `firebase deploy --only firestore:rules`.
7. Make sure `android/app/src/main/AndroidManifest.xml` has
   `<uses-permission android:name="android.permission.INTERNET"/>` above `<application>`.

Run `flutter run` again. "Continue with Google to back up progress" now appears on the home screen.

## Security

- No passwords: Google confirms the player's identity; the app only receives a signed token, name and email.
- Firestore rules let each signed-in player read and write only their own document; everything else is closed.
- Progress data from storage or the cloud is range-checked before use.
- Before launch, turn on **Firebase App Check** with Play Integrity so only your genuine app can reach the database.

## Before publishing on Google Play

- [ ] Privacy policy URL (mention: Google name, email, user ID, game progress)
- [ ] Data Safety form in Play Console
- [ ] Account deletion: in-app is done (Settings → Delete account); Play also asks for a web link where people can request deletion
- [ ] App Check enabled
- [ ] App name, icon and store screenshots
- [ ] Release signing key, and its SHA fingerprints added to Firebase

## Not in v1 (phase 2)

Online competition, iOS release, daily puzzles.
