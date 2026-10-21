# AUVORYN beta audit — 21 October 2026

## 1. Executive summary

Baseline: `main` at `568e65aa116d7abfb93c034176d8cb87fdc42d44`, version
`0.7.0+8`. No open pull requests were returned at discovery. The baseline
GitHub Actions run `39613328361` succeeded. This establishes automated baseline
health, not physical-device release readiness.

The source uses a feature-first Flutter app with Riverpod notifiers and a
GoRouter stateful shell. `MusicController` owns the background-enabled
just_audio player; `AmbienceController` owns an independent audioplayers channel.
`LocalMusicStore` copies imported media to private storage and maintains SQLite
schema v3. SharedPreferences stores room settings. Metadata parsing uses a
separate isolate. The room is authored CustomPainter geometry with weather and
play-state animation: it does not analyze musical energy or detect beats.

Reviewed playback, library/playlist operations, schema/migrations, history,
settings, ambience, routing, major UI screens, native setup scripts, CI, release
docs, tests and asset declarations. No existing native platform directories are
tracked. No user data, app identifier, release key, or schema version was changed.

## 2. QA findings

| Priority | Finding / reproduction | Files | Change and evidence |
| --- | --- | --- | --- |
| P1 | Rapidly select two songs while the audio session is initializing: asynchronous initialization/source loads can overlap. | `music_controller.dart` | Memoize initialization; serialize transport operations; dispose a player that finishes initializing after controller disposal. Controlled asynchronous audio double tests cover ownership and load overlap. |
| P1 | Select two songs in a playlist before the first database write resolves: both callbacks use the old playlist and the last write drops the other addition. | `music_controller.dart` | Serialize library edits and resolve the playlist from current state when each edit executes. Regression verifies both tracks persist in the write sequence. |
| P1 | Tap favorite twice quickly or change it during metadata refresh: stale song snapshots can desynchronize UI and persisted favorites. | `music_controller.dart` | Resolve favorite state at edit time; merge refreshed metadata into current library state. Regression tests cover both paths and recovery after write failure. |
| P1 | At queue completion the UI remains “playing”; the first play/pause tap pauses an already finished player. | `music_controller.dart` | Treat completed playback as stopped in the UI; a single tap seeks to the beginning and plays. Regression uses the documented playing=true/completed combination. |
| P1 | A small manual seek can fit the history tracker's elapsed-time tolerance and be counted as listening. | `listening_tracker.dart`, `music_controller.dart` | Explicit seek rebases the tracker without erasing earned session qualification. Test checks exact credited milliseconds. External media-session seeks still need device evidence. |
| P1 | Clear history while writes are arriving: new checkpoints can race the deletion. | `music_controller.dart` | Put clearing into the same write queue so subsequent checkpoints follow the clear. |
| P1 | Queue snapshots can use old position after seeking or old stream events during source replacement. | `music_controller.dart` | Synchronize position/index after commands and suppress transitional stream updates while loading a replacement queue. Missing restored selection starts its replacement at zero. |
| P1 | App Reduce motion setting changes the room but not player or route animations. | `app.dart`, `vinyl_artwork.dart` | Combine app and OS reduced motion in the root MediaQuery. Stop vinyl animation on background lifecycle and disabled tickers. Widget tests exercise propagation and frame scheduling. |
| P1 | Many playlists overflow the Add to playlist sheet; the window sheet can overflow in landscape; 320px player controls exceed available width. | library, window sheet, player | Scrollable bounded playlist sheet, scrollable window sheet, 64px primary play target and 48px secondary targets. Compact/large-text tests added. |
| P2 | Library filtering and eager row construction repeat on every playback position update. | `library_page.dart`, `playlist_detail_page.dart` | Subscribe only to relevant library collections/status. This removes that position-driven work; full lazy list conversion remains recommended for very large collections. |
| P1 | Reimporting identical audio cannot repair a missing private file because deduplication exits early. | `local_music_store.dart`, `music_controller.dart` | Restore the missing copy at a fresh managed path, update only the path column, preserve IDs/relationships and avoid duplicate UI entries. SQLite regression checks favorites, playlist and history preservation. |
| P2 | Instrument Serif is referenced but missing; Manrope is neither bundled nor configured. | theme, pubspec, `assets/fonts` | Bundle unmodified official font files with OFL notices; apply Manrope to UI text and Instrument Serif to editorial headings. No network font dependency. |
| P2 | Playlist rename/delete failures can escape UI callbacks. | `playlist_detail_page.dart` | Catch failure and keep a useful recovery message; do not navigate away on failed deletion. |

No exploitable critical security defect was established in this review. SQL values
are parameterized; playlist replacement uses a transaction; imports copy to UUID
paths and hash for deduplication. This is a source review, not a penetration test
or exhaustive vulnerability database scan.

## 3. Fixes implemented

Playback commands now share one initialization and serialized command stream.
Library edits use current state when they execute, protecting rapid playlist and
favorite changes. Metadata refresh preserves intervening favorite changes, and
async callbacks guard disposal. Completed playback can restart with one tap.

Queue snapshots are synchronized after transport actions; explicit seeks are not
credited as listening. History deletion is ordered with history writes. Reimport
of identical missing music repairs only its private file path, preserving the
track ID and related favorites, playlists and history. No schema upgrade or reset
is introduced by this change.

## 4. UI/UX improvements

Manrope now provides the interface typography and Instrument Serif the editorial
headings. Both are bundled offline with their OFL licenses. The existing dark
palette and AUVORYN identity are retained. App and operating-system reduced motion
settings now reach every route, and decorative vinyl rotation pauses in the
background. Playlist and customization sheets scroll in constrained layouts;
player transport buttons fit a 320px screen while retaining usable touch targets.

Shared artwork transitions, interactive player dismissal, screen-reader focus and
visual review on devices remain future work. This pass improves the existing
design system; it is not a complete native iOS redesign or a visual sign-off.

## 5. Performance findings

Library and playlist screens select collection/status changes instead of rebuilding
their collection UI for every playback position tick. Metadata comparison now
uses an ID map instead of repeated list searches. Background vinyl animation stops
scheduling frames, as checked by a widget regression. These remove identifiable
work; no FPS, startup, memory or battery improvements have been measured.

Remaining risks are eager large-library rows, import hashing on the UI isolate,
artwork decode limits and room painter cost on lower-powered devices. Profile
representative devices and datasets before making broader architectural changes.

## 6. Test results

Local Dart formatting and `git diff --check` were executed. A standalone Dart history smoke check passed (explicit seek, pause, track change and qualification; 12,000 ms credited). FontTools parsed both bundled fonts successfully. Calculated WCAG contrast for ivory/mist/champagne on the three solid surface tokens ranges from 6.55:1 to 16.98:1; this does not establish contrast over every scene or gradient. Local Flutter package
setup was rejected by automatic approval review because it attempted to reach
the cloud instance metadata service. That request was not retried. GitHub Actions
is the independent validation path for analyzer, tests and Android compilation.
The application/test source at `bfc1852d1584c374977883910ffa8a727da5c24e` passed
[GitHub Actions run 39618693484](https://github.com/markbrian-hue/AUVORYN/actions/runs/39618693484):
package resolution, analyzer, all 42 tests and Android debug APK compilation. The
APK was checked for nonzero size and uploaded as `auvoryn-android-debug-qa`
(five-day retention). The final commit after that run updates only this report;
its independent rerun is linked from [PR #9](https://github.com/markbrian-hue/AUVORYN/pull/9).

New tests cover controller races, completed-track restart, disposal, favorite
preservation, playlist updates, failed-write recovery, old schema v1/v2 upgrades,
import deduplication/private-copy persistence, empty files, clearing history
without removing favorites/playlists, compact/large-text player layout, long
playlist sheets, landscape customization and reduced motion/background rendering.
SQLite migration tests use the actual store with a test-only FFI database backend;
production storage locations and migration SQL are unchanged. Audio tests use a
controlled native-boundary double, not real audio output.

| Gate | Result |
| --- | --- |
| Offline Dart formatting of changed files | PASS (package-resolution warnings; not an analyzer result) |
| `git diff --check` | PASS |
| Standalone Dart listening-tracker regression | PASS |
| Font parsing and solid-token contrast calculation | PASS — minimum 6.55:1 for tested pairs |
| Local `flutter pub get`, analyzer, test, Android build | BLOCKED / NOT RUN after dependency setup rejection |
| GitHub Actions package resolution | PASS — run 39618693484 |
| GitHub Actions `flutter analyze` | PASS — no issues found |
| GitHub Actions `flutter test` | PASS — 42 tests |
| GitHub Actions Android audio setup and debug APK | PASS — built, verified nonempty and uploaded |
| Device audio, Bluetooth, calls, lock-screen, battery/FPS, screenshot review | NOT RUN — no device/emulator available |
| iOS build, release signing, Play Store readiness | NOT RUN / NOT READY |

No measured FPS, memory, battery, or startup improvement is claimed. Library
selector changes remove an identified rebuild cause. The reduced-motion test
checks scheduled animation callbacks, not device energy use.

### Remaining release and quality work

- Ambience opts out of audio focus and has no explicit interruption listener.
  Verify calls, alarms, headset unplug, notification stop and background mixing
  on devices; define whether ambience should pause with music before changing its
  independent playback semantics.
- Queue shuffle/repeat modes are not restored. Queue reordering is absent.
- Missing media can now be repaired by selecting identical audio bytes again.
  The private file is restored under a fresh generated path, retaining track identity,
  playlists, favorites and history. Select the restored track to load its repaired path.
  Export/restore and detection of corrupted-but-present private files remain open.
- Large-library import hashing occurs in the UI isolate; measure impact, then
  consider moving hash/copy analysis and lazy library rows off hot UI paths.
- Startup failure copy still contains developer-oriented remediation. Add a
  consumer recovery screen with optional diagnostics without masking native failures.
- Absolute private paths require validation across iOS sandbox relocation and
  backup/restore scenarios. iOS is not built or tested.
- Native platform shells and dependency/tool versions need reproducible release
  ownership. Production package identity, keystore, app icon and disclosures remain
  open. Do not regenerate a user's customized platform tree or change identity.
- True shared artwork transitions, interactive player dismissal and screen-reader
  focus review remain design work. This pass retains the existing visual structure;
  it is not a complete native iOS redesign or visual sign-off.
- Runtime permission/media-format coverage and malformed image/metadata limits
  need real decoder testing. The tag parser accepting a file does not prove playback.

## 7. Feature recommendations

| Rank | Improvement | User value | Effort | Risk / cost | Priority |
| --- | --- | --- | --- | --- | --- |
| 1 | Non-destructive storage repair and export/restore | Protects a user's music investment | Medium/high | High data-integrity impact; entirely offline | P1 |
| 2 | Sleep timer with explicit music/ambience behavior | Makes bedtime listening useful | Low/medium | Background timer semantics need device tests | P2 |
| 3 | Queue reorder/remove and saved shuffle/repeat | Better everyday playback control | Medium | Queue identity and media-session synchronization | P2 |
| 4 | Lazy library list, album/artist views and sorting | Makes larger libraries usable | Medium | Low architecture impact; benchmark first | P2 |
| 5 | First-launch import and accessibility walkthrough | Improves discoverability | Low/medium | Low runtime cost | P3 |

## 8. GitHub delivery

- Pull request: https://github.com/markbrian-hue/AUVORYN/pull/9
- Branch: `qa/beta-reliability-and-accessibility`
- Changes are isolated from `main`; no merge or force-push is performed.
- Implementation commits: `5153165` (audio/library reliability), `2d57d72`
  (UI/accessibility/fonts), `7f023b2` (completion/disposal), `c023012`
  (analyzer/test compatibility), `18d21a5` (missing-file repair), and
  `bfc1852` (compact-player regression harness). This report is a final docs-only commit.
- Early CI runs exposed test API compatibility/lint problems and an offscreen
  test-finder mistake; those were fixed without removing the relevant assertions.
- Application validation run `39618693484` passed all automated gates. The final
  docs-only commit is also validated before the PR is marked ready. Device-dependent
  checks remain required even after automated CI succeeds.

## 9. Next development roadmap

1. **Device reliability:** reproduce call/Bluetooth/unplug/background scenarios on
   two Android versions; verify upgrade preserves a populated library; define and
   test ambience interruption policy. Acceptance: documented PASS/FAIL evidence,
   no unexplained continuing audio or lost playback state.
2. **Data resilience and library scale:** add a guided recovery flow around the
   implemented missing-file repair; export/restore with collision handling and migration tests;
   profile a representative large library and make rows lazy. Acceptance: backup
   round-trip preserves songs, playlists, favorites and history; measured import
   and scrolling results with documented dataset/device.
3. **Premium beta and packaging:** finish shared player transitions and accessible
   gestures, capture compact/large-text screenshots, pin a release toolchain and
   dependencies, finalize app identity/signing with owner input. Acceptance: green
   CI, visual review, signed internal-track build and complete release checklist.
