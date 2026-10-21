# Android background-audio activity repair

AUVORYN uses `just_audio_background` (`audio_service`). Flutter can build and install successfully yet fail during `JustAudioBackground.init()` with:

```text
The Activity class declared in your AndroidManifest.xml is wrong or has not provided the correct FlutterEngine.
```

This means the running Android activity does not correctly provide the shared Flutter engine required by `audio_service`. It is not a SQLite or offline-music-file error.

## Windows recovery

From VS Code, stop `flutter run` by pressing `q`. Then run these commands from the AUVORYN repository root:

```powershell
git pull origin main
powershell -ExecutionPolicy Bypass -File .\scripts\configure_android_audio.ps1
flutter clean
flutter pub get
flutter run
```

The updated script locates the single generated Java/Kotlin `MainActivity`. It changes a standard `FlutterActivity` to extend `AudioServiceActivity` (or the FragmentActivity equivalents), updates the manifest to reference the real `MainActivity` class, and ensures the background service, receiver, and foreground permissions are declared. It refuses to modify unfamiliar custom activity classes or ambiguous duplicate activity files.

You should see a confirmation such as:

```text
Configured Android launcher: com.example.auvoryn.MainActivity
Android background-audio manifest configured.
```

Package names vary. The Android manifest's launcher activity name must match the package declaration in `MainActivity.kt` or `MainActivity.java`, and the activity must extend the audio-service base class.

**Do not uninstall the app or clear its storage**: imported audio is stored privately and can be lost upon uninstall. The repair script is designed to be rerun without clearing this data.

### If the startup error continues

Check:

1. `android/app/src/main/AndroidManifest.xml` — the launcher `<activity android:name="...MainActivity">`.
2. `android/app/src/main/kotlin/.../MainActivity.kt` (or Java equivalent) — the class extends `AudioServiceActivity` (or `AudioServiceFragmentActivity`).
3. Check there is only one `MainActivity` defined in Kotlin/Java.

Share the script output and the **first** `AUVORYN startup:` error from `flutter run`. Don't edit `GeneratedPluginRegistrant.java`. A real emulator/phone check is required; updating source and successfully compiling are not sufficient verification of background playback.

Documentation: https://pub.dev/packages/just_audio_background and https://pub.dev/packages/audio_service
