# Startup troubleshooting — AUVORYN Android

When the emulator shows the white native Flutter logo for a long time, the app may be stuck *before* Flutter draws its first frame. The app now draws an AUVORYN startup screen immediately and displays the stage/error when audio service or SQLite initialization fails. This is a diagnostic safeguard, **not a bypass** of the required background audio service.

## Refresh and rebuild on Windows

From the project root:

```powershell
git pull origin main
powershell -ExecutionPolicy Bypass -File .\scripts\configure_android_audio.ps1
flutter clean
flutter pub get
flutter run
```

Fully stop the old Flutter process before running these commands. Do not rely on hot reload for changes to Android native plugins or the Android manifest.

## Read the startup stage

Look for `AUVORYN startup:` in the `flutter run` terminal or Debug Console. Possible stages:

- `Restoring your room` — SharedPreferences; a failure falls back to default room settings.
- `Starting background audio` — `just_audio_background`/`audio_service` native integration.
- `Opening your offline music library` — opening SQLite in the app support directory.
- `Loading your songs and playlists` — reading the local library and saved queue.

A failed or timed-out stage now appears *inside the emulator* with the original exception. Capture that exception and the terminal stack trace rather than repeatedly clearing app data. Avoid uninstalling the app: doing so may remove previously imported music stored in the app's private files.

## Remove obsolete starter test

Some workstations generated `test/widget_test.dart` using `flutter create`. That test references `MyApp`, which does not exist in AUVORYN; this is a **test-source error**, separate from runtime startup. The `configure_android_audio.ps1` script preserves that exact starter test as `test/widget_test.generated-backup`. If the error remains, check whether the file contains your own edits before removing or renaming it. AUVORYN has its own test files.

## If AUVORYN still never renders its startup screen

Check the Debug Console/Terminal for the first `E/flutter` exception, `FATAL EXCEPTION`, or `PlatformException`. You can also capture Android logs with `adb logcat -d -v time > android-startup-log.txt` (if the Android SDK platform-tools are on PATH). Share the relevant startup error, not the entire verbose log. The app may also fail before Dart starts if the Android activity class or plugin registration is misconfigured.
