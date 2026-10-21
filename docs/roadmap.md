# AUVORYN — Milestone roadmap

## M1 · Foundation — source produced, runtime validation pending

Project structure, Riverpod, local settings, GoRouter nav, visual tokens, original Midnight Apartment scene, functional mood/lamp settings, honest empty states and authored test suite. **Blocked from build validation** by absent Flutter/Dart SDK in authoring environment.

## M2 · Real offline playback — next

1. Define Drift schema/migrations and media models.
2. Implement local file import on Android and document-picker import on iOS.
3. Index metadata/artwork in an isolate where needed, preserving valid file references.
4. Implement single just_audio playback coordinator, queues, playlists and favorites.
5. Integrate audio_service, notifications, lock screen, headsets and interruptions.
6. Verify airplane-mode playback and file-revocation recovery on real devices.

**Release gate:** user can select a real file, play/pause/seek/skip offline, save a playlist, background the app, and resume without losing the queue.

## M3 · Player design & accessibility

Now Playing, mini-player, editorial library layout, animated transitions, deep links, accessibility semantics, large text, reduced motion.

## M4 · Room interaction

Connection to the actual single audio state stream, vinyl and stereo responses, richer offline art, optimized geometry/layering.

## M5 · Atmosphere

Offline licensed ambience sounds, rain/weather motion, separate audio mixing controls, performance settings.

## M6 · Personalization & memories

Additional room configurations, real play-event histories, opt-in local stats, legitimate audio-energy visualization.

## M7 · Release QA

End-to-end tests, permission matrix by OS version, background audio/interruptions, frame/memory/battery profiling, localization checks, release signing, license review.
