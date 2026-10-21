# Milestone 6 — Personalization and Listening Memories

SQLite schema v3 adds only listening_stats. It preserves music files, existing tracks, playlists, favorites and queue. The upgrade runs on first launch, starting empty and never inventing historic values.

Listening time uses media-position progress while the player is actually ready and playing; paused time, seeking and unrelated ambience do not count. One qualified play is defined as ten seconds of progress, not a full-track completion. Metrics persist locally at checkpoints and may undercount while OS background callbacks are suspended.

Memories shows local totals, most-listened tracks/artist, recent tracks and a confirmation-based clear-history action. Window view customization offers skyline, mountain or coast without new media/network dependencies.

QA: play music for 15 seconds, open Memories, seek ahead 30 seconds, pause 15 seconds, test restart persistence and clear-history; switch window view and restart. Also test background playback on a real Android phone.

Run: flutter pub get; flutter analyze; flutter test; flutter run. Verify Android service and playlist regressions.
