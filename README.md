# auvoryn

**Sound, somewhere yours.**

AUVORYN is an immersive, personal, **offline-first** music listening room built with Flutter and Riverpod. The first room is **Midnight Apartment**.

## Current progress — M2 Offline Music (0.2.0)

- Actual local file picker and import into persistent app-private storage
- SQLite song library, deduplicated imports, favorites and playlists
- Real `just_audio` playback, queue, seek, skip, shuffle and repeat
- `just_audio_background` media session for Android notifications and lock screen (native Android manifest configuration required)
- Global mini-player and Now Playing screen, while room and mood settings remain functional
- Queue/position restoration (paused after relaunch)

The visual room is 2.5D; record taps open the music collection. Embedded tags/album art extraction, automated Android media scans, detailed listening statistics, realtime beat detection, and extra ambience audio are **not yet implemented**.

## First-time setup (Windows / Android)

Install Flutter and Android Studio first. At repository root:

```powershell
flutter create --platforms=android,ios .
flutter pub get
powershell -ExecutionPolicy Bypass -File .\scripts\configure_android_audio.ps1
flutter analyze
flutter test
flutter run
```

Existing M1 clones which already have `android/` and `ios/`: only run `flutter pub get`, **the `configure_android_audio.ps1` script**, and then the three Flutter commands. Restart the app fully after introducing native plugins. Do not paste these commands in a folder without `pubspec.yaml`.

Alternatively, the project-specific `scripts/bootstrap_windows.ps1` builds missing platform shells, configures Android, and runs checks. Do not run the script while a prior temp platform shell still exists.

## Import music

From **Library → Import Music**, choose music you own from the Android file picker or iOS Files. The selected files are copied into AUVORYN app storage so they stay available after the file picker clears temporary cache. Imported music uses device storage and is removed if the app is uninstalled. No permissions to browse your full device library are requested.

Tap any song for the full player. Use its action menu to favorite it or add it to playlists. Playback is local; no account or internet is required.

## Engineering notes

- Architecture: feature-first Flutter, Riverpod 3, GoRouter, SQLite via sqflite.
- Audio: a single just_audio instance plus just_audio_background/audio_service for media control and audio_session for music interruptions.
- Files: SHA-256 dedupe, persistent path references and protected app storage.
- Native: Android manifest configured by `scripts/configure_android_audio.ps1` for generated Android native projects; iOS background mode needs `UIBackgroundModes = audio` once building on macOS.
- Testing: `flutter analyze`, `flutter test`, real-device QA per `docs/qa.md`.

**Status:** Source changes have not been compiled or tested on a device in the AI execution environment. Follow validation instructions before declaring M2 done.

See `docs/milestone_2.md`, `docs/architecture.md`, and `docs/roadmap.md` for implementation and acceptance requirements.
