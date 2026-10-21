# AUVORYN — Milestone 3B: Local Album Art & Music Identity

## Delivered

- `audio_metadata_reader` pure Dart parser reads supported local tags (title, artist, album and embedded cover) without a new Android native plugin. Metadata work runs in an isolate.
- New imports copy audio to private storage first, persist supported JPEG/PNG/WebP cover images separately, and retain filename/unknown-artist fallbacks for damaged/untagged files. Images larger than 8 MiB are ignored.
- SQLite version 2 adds nullable `artwork_path` to tracks through `onUpgrade`; existing playlists, favorites, imported audio and queue are preserved.
- Library song rows, mini-player and Now Playing prefer local album covers. Now Playing can switch between cover and classic vinyl when cover art is available.
- Library's **Refresh details** reparses old files on demand (does not delay launch). It never moves or alters original audio files, IDs, playlist relationships or favorite flags.
- Branded typography roles and accessible artwork fallbacks, plus widget/model tests.

## How to test

```powershell
git pull origin main
flutter pub get
flutter analyze
flutter test
flutter run
```

Test (1) fresh MP3/M4A/FLAC with embedded title/artist and cover, (2) no-tag MP3 fallback, (3) import a file again (deduping), (4) press Refresh details on previously imported music, (5) cover/vinyl switch, (6) restart and verify metadata/cover persisted, (7) playlist creation, background playback and lock screen artwork. Large/malformed covers and unsupported formats should fall back without crashing.

**No music or cover is downloaded online.** Image art is read only from user-imported files. Not all audio files have embedded metadata. JPEG/PNG/WebP signatures supported; other images use the branded fallback. New UI text styles do not ship third-party font binaries; proprietary-looking wordmark remains in the existing vector mark. Future local font integration must include license and tested assets.

## Limitations

- Tag extraction is best effort and does not guarantee metadata for every codec/container.
- If a track's metadata was refreshed while already playing, lock-screen metadata may not refresh until the next playback queue load.
- Android/emulator and iOS device QA still required after source-level review.
