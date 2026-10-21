# AUVORYN — M2 offline playback handoff

## What this increment adds

* User-driven multi-select audio import (MP3, M4A, AAC, FLAC, WAV, OGG/OPUS), private copied storage and SHA-256 dedupe.
* SQLite songs, favorites, playlists, playlist memberships and queue snapshot.
* Just Audio playback of on-device files with seeking, skip, shuffle, repeat; one shared player.
* Notification/lock-screen/headset support via `just_audio_background`, which uses `audio_service` internally.
* Persistent mini-player, Now Playing screen and queue navigation across the existing GoRouter shell.

## Required setup on Windows (after `git pull origin main`)

```powershell
flutter pub get
powershell -ExecutionPolicy Bypass -File .\scripts\configure_android_audio.ps1
flutter analyze
flutter test
flutter run
```

Use **hot restart**, not just hot reload, after adding native plugins. The Android manifest is modified **locally** rather than committed because the M1 setup generated native files on the user's computer. Committing the manifest after this would conflict with Git-untracked generated files. Re-run the script after `flutter create` regenerates native code. The manifest script is idempotent.

For iOS (when using macOS with Xcode), add `UIBackgroundModes` with an `audio` entry in `ios/Runner/Info.plist`, per `just_audio_background` installation documentation; then `flutter pub get`, `cd ios && pod install`. Validate actual background behavior on iOS before release.

## Honest scope

Metadata parsed from filename only; artist and album use sensible unknown defaults. No automatic Android media store scanning or ID3 tag extraction yet. Imported files live in the app sandbox and will be removed if the application is uninstalled. This does **not** include Apple Music, Spotify, DRM decoding, account features, streaming, cloud or bundled copyrighted music. Android headset, notification and lock-screen behavior require physical-device verification. Since Flutter/Dart SDK is not installed in the authoring environment, these files could not be compiled or executed by the authoring agent.
