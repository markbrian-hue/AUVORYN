import 'dart:async';

import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/features/atmosphere/application/ambience_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showAtmosphereSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AuvorynColors.slate,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const FractionallySizedBox(
      heightFactor: .88,
      child: _AtmosphereSheet(),
    ),
  );
}

class _AtmosphereSheet extends ConsumerWidget {
  const _AtmosphereSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(roomSettingsProvider);
    final status = ref.watch(ambienceProvider);
    final controller = ref.read(roomSettingsProvider.notifier);

    Future<void> save(Future<bool> pending) async {
      final result = await pending;
      if (!result && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to save this atmosphere setting.'),
        ));
      }
    }

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 34),
        children: [
          Text('Set the atmosphere', style: AppTheme.editorial(size: 35)),
          const SizedBox(height: 7),
          const Text('Weather, sound, and light. Entirely yours. Entirely offline.',
            style: TextStyle(color: AuvorynColors.mist, fontSize: 13)),
          const SizedBox(height: 22),
          const _SectionLabel('OUTSIDE YOUR WINDOW'),
          const SizedBox(height: 10),
          for (final mood in RoomMood.values) ...[
            Semantics(
              selected: settings.mood == mood,
              child: ListTile(
                key: Key('mood_${mood.name}'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                tileColor: settings.mood == mood ? AuvorynColors.raised : null,
                title: Text(mood.title),
                subtitle: Text(mood.description,
                  style: const TextStyle(color: AuvorynColors.mist, fontSize: 12)),
                trailing: settings.mood == mood
                  ? const Icon(Icons.check_circle, color: AuvorynColors.champagne)
                  : const Icon(Icons.circle_outlined, color: AuvorynColors.mist),
                onTap: () => save(controller.setMood(mood)),
              ),
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 26),
          const _SectionLabel('SOUNDS OF THE ROOM'),
          const SizedBox(height: 9),
          Material(
            color: AuvorynColors.raised,
            borderRadius: BorderRadius.circular(18),
            child: SwitchListTile(
              key: const Key('ambience_enable'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              title: const Text('Play ambient sounds'),
              subtitle: Text(settings.ambienceEnabled
                ? 'Looping ${settings.mood.title.toLowerCase()} soundscape'
                : 'Off until you choose to listen',
                style: const TextStyle(color: AuvorynColors.mist, fontSize: 12)),
              value: settings.ambienceEnabled,
              activeThumbColor: AuvorynColors.champagne,
              onChanged: (value) => save(controller.setAmbienceEnabled(value)),
            ),
          ),
          if (status.busy) const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          if (status.error != null) Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(status.error!,
              style: const TextStyle(color: Color(0xFFFF9F9A), fontSize: 12)),
          ),
          const SizedBox(height: 20),
          _VolumeControl(
            label: 'Ambience volume',
            value: settings.ambienceVolume,
            icon: Icons.water_drop_outlined,
            enabled: settings.ambienceEnabled,
            sliderKey: const Key('ambience_volume_slider'),
            onChanged: (value) => unawaited(
              controller.setAmbienceVolume(value, persist: false)),
            onChangeEnd: (value) => save(controller.setAmbienceVolume(value)),
          ),
          const SizedBox(height: 14),
          _VolumeControl(
            label: 'Music volume',
            value: settings.musicVolume,
            icon: Icons.music_note_rounded,
            sliderKey: const Key('music_volume_slider'),
            onChanged: (value) => unawaited(
              controller.setMusicVolume(value, persist: false)),
            onChangeEnd: (value) => save(controller.setMusicVolume(value)),
          ),
          const SizedBox(height: 13),
          const Text('Music and ambience mix independently. Only your music appears in media controls.',
            style: TextStyle(color: AuvorynColors.mist, fontSize: 12, height: 1.45)),
          const SizedBox(height: 29),
          const _SectionLabel('LIGHTING'),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Desk lamp'),
            value: settings.lampOn,
            onChanged: (value) => save(controller.setLamp(value)),
          ),
          const SizedBox(height: 7),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final palette in LampPalette.values)
              ChoiceChip(
                key: Key('lamp_${palette.name}'),
                label: Text(palette.title),
                selected: settings.lampPalette == palette,
                onSelected: (_) => save(controller.setLampPalette(palette)),
              ),
          ]),
          const SizedBox(height: 14),
          _VolumeControl(
            label: 'Lamp brightness',
            value: settings.lampBrightness,
            enabled: settings.lampOn,
            icon: Icons.wb_incandescent_outlined,
            sliderKey: const Key('lamp_brightness_slider'),
            onChanged: (value) => unawaited(
              controller.setLampBrightness(value, persist: false)),
            onChangeEnd: (value) => save(controller.setLampBrightness(value)),
          ),
          const SizedBox(height: 13),
          const Text('Original local soundscapes. No microphone, location permission, or internet required.',
            style: TextStyle(color: AuvorynColors.mist, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Text(value, style: const TextStyle(
    color: AuvorynColors.champagne, fontSize: 11,
    fontWeight: FontWeight.w600, letterSpacing: 1.7,
  ));
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({
    required this.label,
    required this.value,
    required this.icon,
    required this.sliderKey,
    required this.onChanged,
    required this.onChangeEnd,
    this.enabled = true,
  });
  final String label;
  final double value;
  final IconData icon;
  final Key sliderKey;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(children: [
        Icon(icon, color: AuvorynColors.champagne, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text('${(value * 100).round()}%',
          style: const TextStyle(color: AuvorynColors.mist, fontSize: 13)),
      ]),
      Slider(
        key: sliderKey,
        value: value.clamp(0.0, 1.0),
        onChanged: enabled ? onChanged : null,
        onChangeEnd: enabled ? onChangeEnd : null,
        semanticFormatterCallback: (v) => '${(v * 100).round()} percent',
      ),
    ],
  );
}
