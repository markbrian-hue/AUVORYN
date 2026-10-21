# AUVORYN — Validation report

## Checks executed in authoring workspace

- Verified requested source file exists and its AUVORYN development requirements were read.
- Checked for an existing AUVORYN GitHub repository in connected repositories; none matched.
- Checked Flutter and Dart executables with `command -v`; neither is available.
- Produced the Milestone 1 source files, model/widget test source, a bootstrap script and documentation.
- Ran local source-tree validation for missing relative imports and required files (see final response for results).

## Checks not executed

- `flutter pub get`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter run`
- Android/iOS build or any real-device QA
- FPS/memory/battery/audio checks

**No compilation, rendered emulator inspection, or test-pass claim is made.**

## To validate on a Windows developer machine

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_windows.ps1
flutter devices
flutter run
```

Then manually inspect Room navigation, all atmosphere options, lamp state persistence on restart, Settings switches, and iOS-style accessibility scale and safe-area behavior. For iOS, use macOS with Xcode and a supported device/simulator.

## Known limitations

- This is a source foundation, not a release APK/IPA.
- No real music import, background audio, playing state, audio-reactive vinyl or history tracking.
- Room weather visuals are static representations, not animated rain.
- Local fonts are not bundled, so typography falls back until installed.
- System-level reduced motion is not yet connected to future transition animations; the current room painter is static.
- Platform shells are generated on the developer's machine, preserving handcrafted sources.

## Milestone 2 player checks (on real Android hardware/emulator)

1. `flutter pub get`, `flutter analyze`, `flutter test` complete with no failures.
2. Run `./scripts/configure_android_audio.ps1` in PowerShell after native directories are generated.
3. Launch AUVORYN with **airplane mode on**. Import 2-3 owned MP3/M4A files; play, pause, seek, skip.
4. Pause, lock the screen, resume using notification/media controls; test wired/Bluetooth unplug and call interruptions.
5. Favorite a song, create playlist, add/remove songs, restart app. All selections should survive.
6. Restart during paused playback: last queue and approximate position should restore without autoplay.
7. Import the same audio twice and verify checksum dedupe; import a malformed file to observe error.
8. Verify music continues while navigating the room, opening Memories, and backgrounding.
9. Test denied picker access, low storage, long filenames, non-ASCII filenames.

**Limitations:** v0.2 reads titles from filenames instead of embedded metadata; selecting music is picker-based (no full-device media library scan). Artwork extraction, detailed listening history, and auto-indexing are not implemented. No real-device tests have been executed by the AI authoring environment.
