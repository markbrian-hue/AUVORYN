import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
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
    builder: (context) => const _AtmosphereSheet(),
  );
}

class _AtmosphereSheet extends ConsumerWidget {
  const _AtmosphereSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(roomSettingsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set the atmosphere', style: AppTheme.editorial(size: 33)),
          const SizedBox(height: 8),
          const Text(
            'Your room changes with your mood. No internet required.',
            style: TextStyle(color: AuvorynColors.mist, fontSize: 14),
          ),
          const SizedBox(height: 19),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: RoomMood.values.length,
              separatorBuilder: (_, _) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                final mood = RoomMood.values[index];
                final active = mood == settings.mood;
                return Semantics(
                  selected: active,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    tileColor: active ? AuvorynColors.raised : null,
                    title: Text(mood.title),
                    subtitle: Text(
                      mood.description,
                      style: const TextStyle(color: AuvorynColors.mist),
                    ),
                    trailing: active
                        ? const Icon(Icons.check_circle, color: AuvorynColors.champagne)
                        : const Icon(Icons.circle_outlined, color: AuvorynColors.mist),
                    onTap: () async {
                      final saved = await ref
                          .read(roomSettingsProvider.notifier)
                          .setMood(mood);
                      if (context.mounted && !saved) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not save your atmosphere.'),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Visual atmosphere only in this foundation build. '
            'Ambient sound arrives with the audio system.',
            style: TextStyle(color: AuvorynColors.mist, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
