# Milestone 4 — Midnight Apartment interaction

M4 upgrades the existing deterministic 2.5D scene with offline, lifecycle-aware layers. It does **not** introduce a second audio player, bundled 3D assets or pretend to calculate beats.

## Controls and real effects

| Room object | Touch action | Response |
| --- | --- | --- |
| Turntable | Now Playing (or Library when no track) | Record rotation reflects the existing audio controller's `playing` state. Tonearm rests near the disc when a track is selected. |
| Speakers | Pause/resume currently queued music (or browse Library) | The transport indicator reflects play/pause. There is no fake waveform or beat detection. |
| Desk lamp | Toggle light | State persists through the original RoomSettingsStore. |
| Window | Weather sheet | Presets persist locally; raindrops animate in the physical window only for rainy presets. |
| Record shelf | Library | Access music and playlists without leaving the established navigation model. |

The room paints static architecture once in a separate repaint boundary. Record motion and rain each have their own painter and controller; animation stops for reduced motion, disabled ticker or background lifecycle. Preset changes use an interruptible crossfade and do not influence the audio engine.

## Test and verify

1. `flutter analyze && flutter test` — test cases include all five hotspots, selected-track state, rainy preset and motion toggle.
2. `flutter run` — play imported audio, open Room and verify record spins; pause from the speaker and confirm playback **really** stops.
3. Select light rain/heavy rain/thunderstorm/clear night. Ensure rain remains inside window and disappears on clear night.
4. Toggle lamp, restart app, confirm lamp state was saved.
5. Disable motion in settings (or Android accessibility settings); confirm animated rain and disc stop but playback remains available.
6. Leave app running with music and lock the screen: audio should continue while decorative rendering stops.
7. Test large text, landscape/emulator portrait, rapid tapping and switch between room/library while music continues.

## Scope limits

M4 weather motion is **visual only**, not weather fetched from a live service. M5 will introduce separately mixed, licensed ambient audio; M6 may introduce genuine audio-derived visual analysis. There is no online fetching and no new Android permission or plugin. No local music data are migrated or removed in this milestone.
