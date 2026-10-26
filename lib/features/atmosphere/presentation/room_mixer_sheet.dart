import 'dart:async';

import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/features/atmosphere/application/ambience_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showRoomMixerSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AuvorynColors.slate,
      builder: (_) => const _RoomMixerSheet(),
    );

class _RoomMixerSheet extends ConsumerWidget {
  const _RoomMixerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomSettingsProvider);
    final mixer = ref.watch(ambienceProvider);
    final controller = ref.read(roomSettingsProvider.notifier);
    void report(Future<bool> operation) {
      unawaited(operation.then((ok) {
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to save your mixer settings.'),
          ));
        }
      }));
    }
    return SafeArea(child: Padding(
      padding: EdgeInsets.fromLTRB(
        24, 12, 24, 24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The sound of your room', style: AppTheme.editorial(size: 32)),
          const SizedBox(height: 7),
          const Text('Two independent levels. Your music stays yours.',
              style: TextStyle(color: AuvorynColors.mist)),
          const SizedBox(height: 24),
          Text('MUSIC  ${(room.musicVolume * 100).round()}%',
              style: const TextStyle(color: AuvorynColors.champagne,
                  fontSize: 11, letterSpacing: 1.3)),
          Slider(
            key: const Key('mixer_music_slider'),
            value: room.musicVolume,
            onChanged: (v) => unawaited(
              controller.setMusicVolume(v, persist: false)),
            onChangeEnd: (v) => report(controller.setMusicVolume(v)),
            semanticFormatterCallback: (v) => '${(v * 100).round()} percent',
          ),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            key: const Key('mixer_ambience_switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Ambient sound'),
            subtitle: Text(room.mood.title),
            value: room.ambienceEnabled,
            onChanged: (value) => report(
              controller.setAmbienceEnabled(value),
            ),
          ),
          Text('AMBIENCE  ${(room.ambienceVolume * 100).round()}%',
              style: const TextStyle(color: AuvorynColors.champagne,
                  fontSize: 11, letterSpacing: 1.3)),
          Slider(
            key: const Key('mixer_ambience_slider'),
            value: room.ambienceVolume,
            onChanged: room.ambienceEnabled ? (v) => unawaited(
              controller.setAmbienceVolume(v, persist: false)) : null,
            onChangeEnd: room.ambienceEnabled ? (v) =>
              report(controller.setAmbienceVolume(v)) : null,
            semanticFormatterCallback: (v) => '${(v * 100).round()} percent',
          ),
          if (mixer.error != null)
            Text(mixer.error!, style: const TextStyle(
              color: Color(0xFFFFA6A0), fontSize: 12)),
          if (mixer.busy) const LinearProgressIndicator(),
          const SizedBox(height: 9),
          const Text(
            'Opening the mixer never changes the current track or queue.',
            style: TextStyle(color: AuvorynColors.mist, fontSize: 12),
          ),
        ],
      )),
    ));
  }
}
