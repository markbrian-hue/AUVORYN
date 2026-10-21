# auvoryn

**Sound, somewhere yours.**

AUVORYN is an immersive offline-first music player with a personal listening room. This source tree is the **Milestone 1 foundation**, not a finished music player.

## Actual implemented features

- Premium dark theme tokens, original vector app mark, and mobile-responsive page composition.
- Three real navigation destinations: Room, Library, Memories; functional Settings.
- Original deterministic 2.5D **Midnight Apartment** scene, painted without external image assets.
- Interactive room hotspots for a library route, ambience picker, and lamp.
- Six visual ambience presets, lamp on/off and reduce-motion preference, all stored locally using `SharedPreferencesAsync`.
- Honest empty states for library and history; no fabricated music or statistics.
- Model tests and a navigation widget test written, **not run in this environment**.

**Not yet implemented:** local file import, music library indexing, real audio playback, background playback, playlist or queue management, audio-reactive effects, ambience audio, SQLite/Drift, and cloud sync. Those belong to later milestones.

## Getting running on Windows

The generated source is supplied without Flutter platform directories because the Flutter SDK is not installed in the authoring environment. The included helper generates official Android/iOS templates **without overwriting the source files**.

1. Install the Flutter SDK and Android SDK, then run `flutter doctor`. Android Studio or an Android emulator (or a real device) is required for Android deployment. iOS builds require macOS with Xcode.
2. Open PowerShell in the directory containing this README and `pubspec.yaml`.
3. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_windows.ps1
flutter devices
flutter run
```

Or generate platform folders through Flutter manually, then run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter run`.

The generated Android application identifier uses the **placeholder** `com.example.auvoryn`; select a unique app identifier before publishing.

## Project layout

```text
lib/
  main.dart
  app/
    app.dart
    routing/                 # GoRouter shell and destinations
    theme/                   # shared visual tokens and typography
  core/
    settings/                # immutable model, Riverpod, local settings store
    widgets/                 # original app logo mark
  features/
    home_room/presentation/  # room, interactive hotspots, 2.5D CustomPainter
    atmosphere/presentation/ # adjustable modal sheet
    library/presentation/    # transparent MVP empty state
    memories/presentation/   # transparent MVP empty state
    settings/presentation/   # functional settings
assets/
  fonts/                     # setup instructions, no embedded third-party fonts
  rooms/                     # for future licensed/offline room media
test/                        # tests that require Flutter SDK
docs/                        # design, architecture, milestones, QA
scripts/                     # safe Windows platform bootstrap
```

## Why the app is deliberately incomplete

The original master specification requests actual playback and local music ownership. A visual-only player would violate that requirement. Milestone 1 establishes a coherent identity and durable architecture, while intentionally **not rendering fake play/pause, fake tracks or fake listening statistics**. Milestone 2 integrates `just_audio`, `audio_service`, device-appropriate import and SQLite/Drift.

## Design identity

- Ink `#0B0D12`, Slate `#171A21`, Raised `#242832`
- Ivory `#F4EFE7`, Mist `#A8ADB8`, Champagne `#D8B78B`, Dusk `#A79AC6`
- Intended typography: **Instrument Serif** for editorial headings and **Manrope** for UI. Current code renders system fallbacks until fonts are installed locally; see `assets/fonts/README.md`.
- Motion targets are specified for upcoming interactions in `docs/design.md`. The current scene has no continuous animation, reducing battery use.

## Git setup

```bash
git init
git add .
git commit -m "feat: establish auvoryn milestone 1 foundation"
```

No GitHub repository was created or modified by this source package.

## Documentation

Read [Architecture](docs/architecture.md), [Design](docs/design.md), [Roadmap](docs/roadmap.md), and [QA](docs/qa.md).
