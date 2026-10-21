# AUVORYN — QA status and device validation

AUVORYN 0.7.0 is a **release QA candidate**, not a production signed Android or
iOS release. The user confirmed the previous 0.6.0 functionality on the
Android emulator; this does **not** establish Bluetooth behavior, battery
impact, app-store eligibility or performance on physical phones.

## Automated checks

Every pull request must pass these GitHub Actions steps:

1. Generate the Android Flutter platform shell.
2. Run `scripts/configure_android_audio.ps1` to configure the correct
   `AudioServiceActivity` launcher inheritance and media declarations.
3. Resolve dependencies and execute `flutter analyze` and `flutter test`.
4. Compile a **debug-signed** Android APK; verify it is nonempty, then upload
   it as a short-lived GitHub Actions QA artifact.

Results belong to the particular CI run. A source file or workflow passing
static inspection is **not** the same as having built or tested on hardware.

## Windows validation

From the current AUVORYN checkout, without uninstalling the installed app:

```powershell
git pull origin main
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\validate_android.ps1"
flutter run
```

The script checks the current Android project, applies the existing audio
service configuration, runs package resolution, analysis, tests and builds a
debug QA APK. It does not clean app data or overwrite a working native
project. For a local release **compile** check add
`-BuildReleaseCandidate`; this does not provision production signing.

## Manual QA

Use [release_readiness.md](release_readiness.md) as the acceptance matrix.
Specifically test offline playback, import deduplication and failures,
playlists/queue restored after upgrade, artwork, ambient mixing, history
clearing, reduced motion, screen readers, Android notifications and
interruptions. Test Android version and device model combinations.
Record device-specific evidence and performance profiling results rather
than assigning a pass based on emulators alone.

## Known release blockers

- Generated Android application ID may still be `com.example.auvoryn`.
- Release keystore, permanent app icon, signed AAB and store setup are not
  provided in this source-only repository.
- App-private imported songs have no export/backup workflow; uninstall or
  app-data clearing can erase them.
- iOS requires macOS/Xcode build, entitlements, signing and testing.
- Real-device performance, battery and audio-focus validation remain open.
