# AUVORYN — Milestone roadmap

> Current source: **M7 QA candidate, 0.7.0**. Milestones 1–6 are implemented
> in source and have user-confirmed functionality on an Android emulator.
> M7 adds Android build checks, local data disclosure, and release QA
> documentation. Physical-device performance, audio interruptions, release
> signing, unique application ID, and store approval are still pending.

## M1 · Foundation — source produced, runtime validation pending

Project structure, Riverpod, local settings, GoRouter nav, visual tokens, original Midnight Apartment scene, functional mood/lamp settings, honest empty states and authored test suite. **Blocked from build validation** by absent Flutter/Dart SDK in authoring environment.

## M2 · Real offline playback — source implemented; local build/device verification pending

1. [x] Define SQLite schema via sqflite and media models (Drift deferred).
2. [x] Implement local file import via OS document picker with durable private copies.
3. [ ] Embedded metadata/artwork parsing and scalable background indexing (future increment).
4. [x] Implement single just_audio playback coordinator, queues, playlists and favorites.
5. [x] Integrate just_audio_background (audio_service) and audio_session; [ ] verify notifications, lock screen, headsets and interruptions on device.
6. [ ] Verify airplane-mode playback, missing files and recovery on real devices.

**Release gate:** user can select a real file, play/pause/seek/skip offline, save a playlist, background the app, and resume without losing the queue.

## M3 · Player design & accessibility

Now Playing, mini-player, editorial library layout, animated transitions, deep links, accessibility semantics, large text, reduced motion.

## M4 · Room interaction — source implemented, device validation pending

[x] Existing single audio state wired to room vinyl, turntable and speaker controls. [x] Five accessible object hotspots. [x] Independently painted offline rain and record animation, with reduced-motion/lifecycle suspension. [ ] Validate rendering, frame time and accessibility on devices. See `docs/milestone_4.md`.

## M5 · Atmosphere

Offline licensed ambience sounds, weather presets/light polish, separate audio mixing controls, performance settings.

## M6 · Personalization & memories — source implemented; device QA pending

On-device playback-progress history, real listening statistics and clearing controls, three offline window views. Future: optional song notes and genuine audio-energy visualization.

## M7 · Release QA (in progress)

- [x] Add CI Android APK build gate and a local validation script.
- [x] Document privacy, local storage and release blockers.
- [x] Bound listening-history summaries to avoid unbounded Dart allocations.
- [x] Guard playlist selection when a deleted playlist is still displayed.
- [ ] Run Android build, all tests, and device QA on this candidate.
- [ ] Verify headset/Bluetooth interruptions, background playback, memory,
  battery and reduced motion on real hardware.
- [ ] Choose permanent Android/iOS application identifiers, set app icons,
  configure **private** release signing and complete store requirements.
See [release_readiness.md](release_readiness.md).


## M5 progress — 0.5.0

Offline original Ogg soundscapes, independent ambient/music volume controls, persistent lamp palette/brightness and an opt-in ambient audio engine. Source integration and unit/widget tests added; Android/iOS focus, Bluetooth, background and long-session audio QA remain device acceptance gates.
