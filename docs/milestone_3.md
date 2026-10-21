# AUVORYN — Milestone 3A: premium player UI

## Included

- Shared branded theme: spacing, surfaces, typography roles, champagne highlights and motion durations.
- A locally drawn vinyl record with real play/pause-linked rotation. No fake waveform or album art.
- Refined full-screen Now Playing screen with responsive record sizing, music metadata, favorites, transport controls, seek handling and up-next queue sheet.
- Scrubbing now seeks once when released rather than sending an audio seek for every drag pixel.
- Mini-player with a more tactile surface, an active progress line and animations that remain tied to the same music controller.
- Dedicated upward fade/slide Now Playing route respecting platform reduced-motion preferences.
- Widget coverage for record accessibility and player queue visibility.

## Preserved

The Milestone 2 audio controller, imported audio files, SQLite data, playlists, favorites and background playback integration are not replaced. The locally rendered record represents a design illustration: embedded album artwork and tag extraction are planned separately.

## QA on Windows Android emulator

From the AUVORYN project root:

```powershell
git pull origin main
flutter pub get
flutter analyze
flutter test
flutter run
```

Test playing imported files, switching songs, toggling repeat/shuffle, tapping favorite, dragging the seek slider, opening and jumping in the queue, opening and closing the player quickly, Android back gestures, rotating the device and reduced motion. Verify whether the existing Android manifest modification script remains applied after any `flutter create` invocation.

Test on a physical Android phone as well for audio focus, headsets, notification controls and animation performance. No device FPS or battery results are claimed here.

## Known remaining work

- Missing artist/album-art metadata extraction remains as in M2.
- Manrope and Instrument Serif are referenced as design direction but aren't bundled; correctly licensed locally bundled fonts are a separate deliverable.
- No pretend audio-reactive effects or downloadable assets.
- Full screen-reader and large-text QA needs actual devices.
- No new room renderer overhaul in this increment: the functional Midnight Apartment scene remains.
