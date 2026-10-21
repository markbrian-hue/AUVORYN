# AUVORYN — spatial home

The home screen is now a small 3D listening apartment, rendered entirely offline
with Flutter. Authored world-space surfaces use perspective projection and depth
ordering, shared with the object controls. A cached binary-space partition splits
intersecting surfaces so walls, shelves and decorative details occlude correctly. The scene includes a walnut console,
turntable, speakers, record shelf, upholstered sofa, rug, coffee table, floor lamp,
plant, framed artwork and a window with the existing city, coast and mountain views.

## Interaction and visual behavior

- Drag horizontally to orbit the camera within a deliberately small range.
  Vertical gestures remain available for scrolling the home page.
- Left/right buttons provide the same camera control without dragging; the center
  button restores the original view. The camera does not drift autonomously.
- Tap the record, speaker, lamp, shelf or window to use the existing application
  actions. Controls share the camera projection and separate their 48px hit regions
  on compact screens. They can be hidden for an uninterrupted view.
- Mood and window changes crossfade; lamp intensity eases between settings. The record rotates only during real
  playback; rain follows the selected atmosphere. No beat detection is simulated.
- Home presets select After hours, Soft rain or Golden hour using the existing
  settings persistence. Fine-tune opens all atmosphere, lighting and audio controls.
- Premium layout changes include editorial typography, a spacious scene frame,
  restrained brass details, tactile preset cards and a useful collection entry.

## Rendering and accessibility boundaries

The static architecture/furniture and animated details use separate repaint
boundaries. Camera and light changes repaint the architecture only while those
values change. Camera movement reuses the scene geometry and partition tree. Animation stops when backgrounded, offstage, or reduced motion is
requested. Reduced motion keeps intentional camera controls immediate.

This is a lightweight geometric diorama, not a game-engine renderer. There are no
new runtime packages, network models, microphone or motion-sensor permissions.
No changes are made to audio ownership, SQLite, app identity or existing user data.
Hardware FPS, memory and battery measurements still require device profiling.

## Verification

Regression tests cover all 18 authored mood/window geometry variants, plane
intersection and occlusion ordering, camera projection/bounds, orbit and reset, compact hit areas,
object callbacks, background suspension, reduced motion, visibility controls and
large-text preset persistence. Existing room interaction tests remain in place.

CI runs analysis, tests, actual Flutter PNG captures and the Android debug build.
The opt-in `room_visual_preview_test.dart` capture writes `home`, `midnight`,
`sunset-coast`, `rain-mountain` and both orbit-extreme PNGs into `build/room-previews`. CI publishes them
as `auvoryn-room-previews` for visual review. These are rendered application views,
not concept mockups or performance measurements. Final verification results and
preview findings are recorded in the pull request.
