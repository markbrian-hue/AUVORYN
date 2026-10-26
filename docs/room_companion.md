# AUVORYN — Quiet Room Companion (beta)

The companion now uses **actual 3D surfaces** for head, hair, torso, arms, legs, shoes and clothing. The authored ellipsoid/capsule meshes share the existing Midnight Apartment perspective camera and BSP painter, so the figure rotates in world coordinates and surfaces are depth-sorted against the room's furniture. The aesthetic is cozy stylized 3D, **not photorealistic scanned or rigged 3D**.

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
- The model is part of the room's world-coordinate geometry, not a tap overlay. It does not interfere with existing camera gestures or room controls. There are no audio/session hooks, no fake beat response, and no extra animation timer.

## Engineering scope and limitations

- Actual 3D ellipsoids and oriented capsule surfaces are generated offline
  and inserted into the apartment's existing BSP surface tree. Furniture
  occlusion and camera orbit are handled by the same renderer as the room.
- The geometry is rebuilt on user customization, but no continuous avatar
  animation or extra rendering/audio engine is introduced.
- This is a static stylized 3D character, **not** a photorealistic, rigged,
  walkable human mesh. Realism, cloth simulation, blend shapes, natural idle
  animations and 3D asset authoring are future milestones requiring licensed
  offline models and performance measurements.
- No SQLite migration, accounts, remote assets, extra dependencies, new
  permissions, or changes to music playback architecture.
- Test CPU cost and rendering performance on physical Android hardware
  before release; BSP meshing can be more expensive than the old flat layer.

## Verification

`test/room_companion_test.dart` checks presets, JSON roundtrips,
invalid-data refusal, editor persistence and room control coexistence.
`test/room_companion_mesh_test.dart` covers genuine 3D depth, orbit camera projection, disabled models and BSP construction. `test/room_visual_preview_test.dart` captures actual Flutter renders of the home, companion editor, and multiple 3D companion poses in CI.

Manual QA: verify character placement from each orbit position on small
screens, check large text and TalkBack, test persistence after app restart,
and confirm playback continues during all customization interactions.
