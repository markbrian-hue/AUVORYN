import 'dart:math' as math;

import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/features/atmosphere/presentation/atmosphere_sheet.dart';
import 'package:auvoryn/features/atmosphere/presentation/room_mixer_sheet.dart';
import 'package:auvoryn/features/home_room/presentation/room_scene.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:auvoryn/features/music/presentation/mini_player.dart';
import 'package:auvoryn/features/scenes/presentation/listening_scenes_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Dedicated space without the tab bar. A close button and mini-player remain
/// reachable; the user's music state is shared, never recreated here.
class ImmersiveRoomPage extends ConsumerWidget {
  const ImmersiveRoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomSettingsProvider);
    final hasTrack = ref.watch(musicProvider.select((m) => m.currentSong != null));
    final playing = ref.watch(musicProvider.select((m) => m.playing));

    return Scaffold(
      backgroundColor: AuvorynColors.ink,
      bottomNavigationBar: const MiniPlayer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(children: [
            Row(children: [
              IconButton(
                key: const Key('immersive_exit'),
                tooltip: 'Exit immersive listening',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(child: Text(
                'MIDNIGHT APARTMENT',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AuvorynColors.champagne,
                    letterSpacing: 2, fontSize: 11),
              )),
              IconButton(
                tooltip: 'Saved listening scenes',
                onPressed: () => showListeningScenesSheet(context),
                icon: const Icon(Icons.bookmark_outline_rounded),
              ),
            ]),
            const SizedBox(height: 11),
            Expanded(child: LayoutBuilder(
              builder: (context, constraints) {
                final width = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight * .92,
                );
                return Center(
                  child: SizedBox(
                    width: width,
                    child: RoomScene(
                      settings: room,
                      hasTrack: hasTrack,
                      isPlaying: playing,
                      initiallyShowControls: false,
                      onRecordTap: () => hasTrack
                          ? context.push('/now-playing') : context.go('/library'),
                      onShelfTap: () => context.go('/library'),
                      onWindowTap: () => showAtmosphereSheet(context),
                      onSpeakerTap: () => showRoomMixerSheet(context),
                      onLampTap: () async {
                        final ok = await ref.read(roomSettingsProvider.notifier)
                            .setLamp(!ref.read(roomSettingsProvider).lampOn);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text(
                              'Unable to save your lamp setting.')),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            )),
            const SizedBox(height: 8),
            const Text(
              'Drag to look around · Tap the eye icon to explore objects',
              style: TextStyle(color: AuvorynColors.mist, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton.icon(
                onPressed: () => showRoomMixerSheet(context),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Mixer'),
              ),
              const SizedBox(width: 9),
              TextButton.icon(
                onPressed: () => showAtmosphereSheet(context),
                icon: const Icon(Icons.cloud_outlined, size: 18),
                label: const Text('Atmosphere'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
