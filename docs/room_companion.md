# AUVORYN — Quiet Room Companion (beta)

A lightweight, authored 2.5D character is perspective-anchored to the
**existing** 3D Midnight Apartment camera. This is not a photorealistic scanned
mesh, full skeletal avatar, or a new rendering engine. The design is a softly
shaded cozy character intended to complement the room's original visual style.

## In the app

- Room > **Companion** or Immersive > **Companion** opens customization.
- Choose **Boy, Girl, Emo boy, Emo girl**. Each has distinctive default
  clothing and hair; changing styles preserves visibility, skin, and pose.
- Choose three places: **sofa**, **standing by the rug**, **by the window**.
- Fine-tune **hair** (four options), **complexion** (three options), and
  **cozy clothing palette** (four options).
- Toggle **Companion in the room** off to hide it without erasing your selection.
- All changes save automatically under SharedPreferencesAsync key
  `auvoryn.room_companion.v1`; invalid or future-version data is protected
  from overwrite. No accounts, permissions, cloud requests, or model downloads.
- The visual layer is IgnorePointer and does not interfere with existing
  camera gestures or room object controls. It has no audio or session hooks,
  no artificial music-reactive animation, and respects existing scene motion.

## Engineering scope and limitations

- The model is a static, soft-shaded **2.5D illustration**, not a polygonal
  human that rotates independently or can walk freely. Its projected
  placement and apparent size follow camera orbit.
- This first implementation uses handcrafted strokes and shaded paths. For
  photorealism or clothing meshes, a future milestone needs licensed offline
  artwork / rigging and device performance evaluation.
- The companion draws as a foreground figure relative to furniture rather
  than mesh-integrated 3D occlusion; inspect orbit extremes on an actual
  device before release.
- The feature is entirely separate from the existing music SQLite database,
  playback engine, listening-scene storage, and sleep session data.

## Verification

`test/room_companion_test.dart` checks presets, JSON roundtrips,
invalid-data refusal, editor persistence and room control coexistence.
`test/room_visual_preview_test.dart` captures actual Flutter renders of the
home screen, companion editor, and Emo Boy by the window in CI.

Manual QA: verify character placement from each orbit position on small
screens, check large text and TalkBack, test persistence after app restart,
and confirm playback continues during all customization interactions.
