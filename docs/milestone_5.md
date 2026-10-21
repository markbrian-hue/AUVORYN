# AUVORYN — Milestone 5: Offline Atmosphere & Ambient Audio

## Implemented in source

- Original, generated Ogg Vorbis ambience assets for soft rain, heavy rain, distant thunderstorm, and quiet city night. No commercial recordings, copyrighted samples, or network streams.
- User-controlled **opt-in** ambience (default off) with weather-driven soundscape mapping.
- Ambient audio through `audioplayers` (separate from the **single** `just_audio` + `just_audio_background` music player). Configure mixing without taking Android audio focus; media notification remains music-only.
- Independent music / ambient volume sliders, with an immediate audible preview and persistent values saved on drag completion.
- Lamp palette (Amber / Rose / Moonlight) and brightness persisted through existing `RoomSettingsStore` JSON key. Old settings default safely; no SQLite migration.
- Room renderer paint responds to palette and brightness, with decorative scene animations unchanged.
- Sound-source switching and user toggles serialized to prevent asynchronous source-load races.
- Unit and widget regression tests.

## Run from Windows

```powershell
git pull origin main
flutter pub get
flutter analyze
flutter test
flutter run
```

If Android reports a **new** plugin or Gradle error after adding audioplayers, stop and report the full first error before modifying native files. There is no reason to uninstall the app or clear its music library.

## Device acceptance checks

1. Play an imported song, open Room > Atmosphere, enable ambient sound, and change to Light rain. Both music and soft rain should be audible.
2. Change to Heavy rain, Thunderstorm, Clear night (city hush); wait for seamless repeating sound loops.
3. Drag the ambience slider to zero while music keeps playing, then drag music volume down while ambience continues.
4. Toggle ambience off; music must continue uninterrupted. Re-enable ambience. Exit the sheet; ambience must stay on, and only music should appear in notification controls.
5. Try Amber / Rose / Moonlight and lamp brightness, then restart app; settings should persist, old playlists and tracks must remain.
6. Lock/unlock device, background/foreground, listen through headphones and Bluetooth, and test incoming calls. Native audio mixing and audio-focus behavior **require real-device QA**.
7. Enable Reduced Motion; weather and record animations should stop while audio remains usable.

## Boundaries and caveats

- Weather conditions are user-selected atmospheric presets, **not** live forecasts.
- The bundled loops are original procedural approximations, not field recordings; thunder sound timing is not claimed to be frame-synchronized with a visual flash.
- The Ogg/Vorbis assets are ~18 seconds per loop; audible seams or audio focus differences should be reported for polishing on real devices.
- The additional `audioplayers` native plugin has not been tested on the user's Windows Android emulator by the authoring environment. CI can catch package and Dart issues, but physical-device interruption/background behavior needs validation.
- Ambience is off by default and can be disabled immediately. Audio while the app is backgrounded is OS-dependent; media playback controls belong to the primary player only.
