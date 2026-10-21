# AUVORYN — Technical architecture

## System boundaries

- Flutter UI handles scene rendering, navigation, gesture and screen-reader interaction.
- Riverpod owns room settings and later playlist/audio state.
- A single audio coordinator introduced in Milestone 2 will wrap `just_audio` and expose playback/queue streams, with `audio_service` supporting background controls. No screen or room object may instantiate a separate player.
- An indexed on-device SQLite library, using Drift, will manage songs, artists, albums, playlists, play counts, history, and the persistent queue. It must track *references* to locally accessible files and handle revoked or missing access.
- A lightweight key-value store (`SharedPreferencesAsync`) persists noncritical room and accessibility settings only. Never treat shared preferences as a transactional music database.
- No account, Internet service, DRM bypass, or streaming service is required for offline core use.

## Data design (planned for Milestone 2)

Entities and key fields:

| Entity | Planned key fields | Notes |
| --- | --- | --- |
| `tracks` | id, uri, display_name, artist, album, duration_ms, artwork_uri, last_scanned_at, unavailable | Stable app IDs, distinct from file URIs |
| `artists` | id, name | Normalized display metadata |
| `albums` | id, artist_id, title, artwork_uri | Handle missing cover art |
| `playlists` | id, name, created_at, updated_at | User-editable local collections |
| `playlist_tracks` | playlist_id, track_id, position | Preserves user ordering |
| `favorites` | track_id, added_at | User-defined favorites |
| `queue_items` | position, track_id | Persist next-to-play order and selection |
| `play_events` | id, track_id, started_at, played_ms | Event-based listening history |
| `room_profiles` | id, title, mood, lamp_on, customization_json | Future advanced room presets |

Use migrations for schema changes, parameterized statements via Drift, indexes for tracks/queue/history queries, and transactional playlist editing. Avoid storing giant artwork blobs in the database.

## Audio import strategy (planned)

Android: use approved media-store/library access where appropriate, using version-specific scoped-media permissions, and platform document pickers for user-selected files. iOS: use document picker, store security-scoped access or import into sandbox as needed, taking care that external document URLs may not persist. Verify formats with the decoder. Never request broad `MANAGE_EXTERNAL_STORAGE` merely to browse music.

`just_audio` + `audio_service` will eventually expose duration, position, player state, queue, interruption behavior and system controls. Lock-screen/background playback must be checked on physical devices; no test has been conducted yet.

## Visualization plan

Milestone 1 uses deterministic CustomPainter drawing for the room; its painter recomputes only when atmosphere or lamp changes. Milestone 4 may introduce layered image assets and animation, subject to measured memory/FPS. Actual music energy-reactivity requires a viable local analysis method and must not be substituted by random pulse effects.

## Asset and licensing policy

Room vector shapes are authored in the project. Further room artwork, animations, ambient sounds, and fonts must be original or correctly licensed and bundled for offline use. Store asset attributions/licenses in the repository. Avoid remote-fetch-on-first-use for core atmosphere resources.
