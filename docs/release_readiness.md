# AUVORYN 0.7.0 — Release candidate verification

This is an **engineering QA milestone, not a public store release**. Previous Android
emulator success does not prove performance, Bluetooth behavior, background
audio, signing, or store compliance on actual devices. Do **not** uninstall the
current app to test a new build: imported music lives in app-private storage.

## Automated gates

On every PR, GitHub Actions generates an Android platform shell, applies
`scripts/configure_android_audio.ps1`, resolves packages, runs
`flutter analyze` and `flutter test`, then assembles a **debug-signed QA APK**.
The workflow uploads that QA APK as a short-lived GitHub Actions artifact.
This is not a production AAB and must not be distributed as a Play Store build.

On the existing Windows project (no data reset):

```powershell
git pull origin main
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\validate_android.ps1"
flutter run
```

For a **local compile check** of release mode, add `-BuildReleaseCandidate`
to the PowerShell script. This does **not** configure your private signing key.

## Device acceptance matrix

Test at least one **real Android phone** plus your Android emulator,
using a device with low storage and a second device/OS version when possible.
Record OS version, app version/build number, observed behavior and logs.

| Area | Required verification | Result |
| --- | --- | --- |
| Fresh installation | Branded startup; room renders, all tabs reachable | Not yet verified |
| Upgrade from 0.6.0 | Existing imported songs, playlists, favorites, queue, history and room settings persist | Not yet verified |
| Offline mode | Airplane mode; import from Documents; play/seek/skip without internet | Not yet verified |
| Media controls | Notification, lock screen, wired headset, Bluetooth headset and unplug behavior | Not yet verified |
| Audio interruptions | Incoming call, other audio app, focus changes, alarms; music/ambience mixing | Not yet verified |
| Long playback | 30-minute loop with app backgrounded; resume without unexpected pause or leaks | Not yet verified |
| Fault tolerance | Corrupt/unreadable audio, deleted source, low storage, repeated import, denied picker | Not yet verified |
| UI & accessibility | 200% text scaling, small screen, screen reader, contrast, safe areas, reduced motion | Not yet verified |
| Performance | Profile-mode startup latency, room FPS, memory, CPU and battery under ambience + music | Not yet verified |
| Data safety | Clearing listening history keeps music; app upgrade does not remove app-private files | Not yet verified |
| Privacy | All data disclosures, Android permissions and dependencies reviewed | Not yet verified |

For performance testing use `flutter run --profile` on a **physical device**,
then Flutter DevTools' Performance/Memory views. Debug-mode emulator FPS is not
a release performance measurement. Capture reproducible frame timings and
memory growth before claiming the app meets a performance target.

## Android store-readiness blockers

1. **Permanent package ID**: generated platform shells may use
   `com.example.auvoryn`. Choose and verify an organization-owned application
   ID before publishing. Changing an installed application's ID creates a
   different Android app; it does not upgrade the existing user's data.
2. **App signing**: create and safely back up the production upload key;
   configure Android release signing in the platform project without committing
   `key.properties`, keystores or passwords. Use a real release-signed AAB.
3. **Native project**: the platform shell is currently generated, not a
   maintained reproducible native release module. Lock down the chosen Android
   application ID, SDK/API targets, launcher icons, splash, labels, audio
   service manifest and Gradle dependencies before publishing.
4. **Privacy and compliance**: review `docs/privacy_and_data.md`; verify
   permissions, privacy disclosures, data-safety answers and third-party
   dependency licenses. Verify bundled original ambience asset provenance.
5. **Store assets and testing**: licensed app icon, screenshots, accessibility,
   support/privacy URLs, internal track, real-device crash monitoring and
   staged rollout plan are still required.
6. **iOS**: not built or tested. iOS release requires macOS, Xcode,
   provisioning, correct bundle ID, background audio entitlement and testing.

**Do not commit personal signing credentials or ship a debug-signed APK as a
store release.** No public release is claimed until these gates pass.
