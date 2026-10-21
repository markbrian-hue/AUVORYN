# AUVORYN — UI direction and interaction

## Identity

A listening instrument, not a generic streaming service. Use generous dark space, warm accent, a clear hierarchy, a signature ring-and-groove mark, and restrained illustration detail.

## Tokens

| Token | Hex | Use |
| --- | --- | --- |
| Ink | `#0B0D12` | Root canvas |
| Slate | `#171A21` | Functional surface |
| Raised | `#242832` | Active surface |
| Ivory | `#F4EFE7` | Readable primary copy |
| Mist | `#A8ADB8` | Secondary copy |
| Champagne | `#D8B78B` | Selected and lit actions |
| Dusk | `#A79AC6` | Mood accent |

Spacing scale: 4/8/12/16/24/32/48 logical pixels. Page gutters 24. Panels round to 24; interaction targets are at least 48×48.

## Type treatment

**Instrument Serif** for spacious editorial section headings; **Manrope** for navigation, player text and settings. Both families are now bundled for offline use, with their SIL Open Font License files in `assets/fonts/`. See `docs/beta_audit.md` for the current implementation and remaining design work.

## Screens in Milestone 1

- Room: top wordmark, settings, small 'YOUR SPACE' eyebrow, editorial Midnight Apartment title, 2.5D window/city/stereo/vinyl room, functional hotspots and mood surface.
- Library: editorial collection identity and a truthful empty state. No imported songs yet.
- Memories: future listening journal with truthful empty state; no fictitious metrics.
- Settings: lamp preference, motion preference, and atmosphere selection.

## Motion plan

- Press response: ~140ms with optional slight compression.
- Ordinary navigation: ~280ms and platform-adaptive.
- Future mini-player-to-player expansion: ~400ms shared-element transition after **real playback** is implemented.
- Weather shifts: ~760ms interpolate visual scene values; currently immediate until animation architecture is added.
- Respect accessible reduced motion and disable continuous particles/parallax when enabled.

No animations are presented as audio-reactive until genuine analysis is wired to playback. A static scene is deliberately used for the initial foundation to keep it lightweight and battery-friendly.
