# AUVORYN — Listening Scenes & Focus Sessions (beta)

This implementation builds on the **merged PR #10 spatial apartment**, not a
second scene renderer. The existing room geometry, camera, weather, lighting,
sound players and SQLite database remain intact.

## Saved listening scenes

- Open Room → **Scenes**. Starter scenes (Rainy Study Night, Sunday Morning,
  After Hours) work without imported music, playlists or an account.
- **Save the room as a scene** captures the current weather, window view, lamp
  status/palette/brightness, ambience toggle/volume and music volume.
- Link any local playlist optionally. Rename, change the link, duplicate,
  update from the current room or delete saved scenes.
- Scenes are stored as versioned JSON in SharedPreferencesAsync key
  `auvoryn.listening_scenes.v1` and never touch the music SQLite schema.
- Applying a scene updates room settings **in one write**, preserves reduced
  motion and does **not** start music, pause music, seek or replace the queue.
  Linked playlist playback is an **explicit button**.
- Corrupted saved scene JSON fails closed and is not silently overwritten.

## Interactive room and immersive mode

- Turntable: Now Playing if selected, Library otherwise.
- Record shelf: existing Library and playlists.
- Window: weather / full atmosphere sheet.
- Lamp: toggle, persisted.
- Speakers: dedicated music/ambience volume mixer (no play/pause side effect).
- **Immerse**: hides tab navigation; RoomScene starts with unobtrusive
  hotspots hidden. Exit, mini-player, scene/atmosphere/mixer controls remain
  accessible. Camera reset and hotspot visibility still use PR #10 behavior.

## Focus & sleep sessions

- Open Room → **Focus / Sleep**.
- Presets and a custom 5–180 minute slider; optional scene selection.
- Explicit end behavior: **Keep music playing** or **Fade and pause audio**.
- Pausing freezes remaining time; resuming recalculates an absolute deadline.
  Canceling has **no audio side effects**.
- The active countdown is shown quietly on Home.
- Single active session is persisted under
  `auvoryn.listening_session.v1`, independent from the music store.
- A foreground timer redraws remaining time from an absolute deadline.
  Android may suspend Dart timers or terminate the process while backgrounded;
  on resume/restoration, a passed deadline is reconciled and any needed pause
  is applied without starting music. The app does not promise a guaranteed
  scheduled native background alarm or exact-stop behavior while force-stopped.
- Sleep end fades the existing `just_audio` and `audioplayers` channels
  independently, then pauses/stops them. The saved volume values are restored,
  not overwritten. No new audio-engine instance or background permission.

## Library and queue

- Search song titles, artists, albums, filenames; filter playlists by name.
- Sort library by recent import, title, artist, album.
- Queue supports native reorder, Play Next and Remove from Queue; edits are
  disabled under shuffle because displayed and native playback orders diverge.
- Import now shows file progress and duplicate counts. Missing local media
  reports an error for reimport; no fabricated history or recommendations.

## Device QA

1. Upgrade without uninstall: confirm music, playlists and history remain.
2. Save a scene, change the room, apply it and confirm the music queue and
   playback are unchanged; restart and confirm scene persistence.
3. Delete a linked playlist and reopen the scene: the link is safely shown as
   missing and applying still changes the atmosphere.
4. Start/pause/resume a session, background and return, verify remaining time.
5. Use a short sleep timer and verify both audio channels fade and pause;
   confirm the selected volume settings have not been overwritten.
6. Try rotating the 3D apartment, opening speaker mixer, immersive mode, and
   returning without interrupting music.
7. Test queue operations, library filters and import progress.
8. Run `flutter analyze`, `flutter test` and `flutter build apk --debug`.
   CI additionally renders real Flutter UI screenshots for visual review.

**Release limitations:** physical Android battery/audio-focus testing,
background process death behavior, iOS build and signed distribution still
require explicit validation.
