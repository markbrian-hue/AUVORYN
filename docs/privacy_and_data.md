# AUVORYN — Local data and privacy notes (0.7.0)

These statements describe the **current repository implementation**, not a
certified legal privacy policy. Revalidate dependencies and platform behavior
before publication.

## What the app currently does

- Users select owned audio with the system file picker. AUVORYN copies the
  selected file into app-private storage so playback does not depend on the
  picker retaining temporary access.
- Embedded tags and supported album covers are parsed locally and covers are
  saved in app-private files. Song metadata, playlists, queue state, favorites
  and aggregate playback statistics are stored in a local SQLite database.
- Lamp, atmosphere, window view, music/ambience volumes and reduced-motion
  preferences are stored locally in SharedPreferences.
- Original bundled ambience files are played from local Flutter assets.
- The current application does not implement accounts, AUVORYN analytics,
  third-party advertising, online music search or cloud music uploads.
- Android's system audio, media notification, file picker and plugin services
  still perform platform operations; a plugin/dependency audit is required
  before making broader network or privacy claims.

## Retention and deletion

Listening-history clearing removes rows from the listening_stats table; it
does not delete song files, favorites or playlists. This app does not yet offer
a backup/export mechanism for its privately imported music or SQLite database.
**Uninstalling the app or clearing its storage can delete all these files and
preferences**, so people should keep source music in a separate location.
Installing a build under a different application ID also does not migrate
app-private data.

## Permissions and publication

AUVORYN uses Android foreground media playback and may request related
foreground service/wake-lock declarations for background audio; it chooses
files through the OS picker rather than scanning all device storage.
Before release, inspect the *merged* AndroidManifest.xml and all plugin
permissions, audit the final Android bundle, verify third-party licenses and
complete platform-specific store disclosures. Do not promise third-party SDKs
collect no data without verification.
