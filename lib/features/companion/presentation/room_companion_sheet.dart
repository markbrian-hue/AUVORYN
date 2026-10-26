import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/features/companion/application/room_companion_controller.dart';
import 'package:auvoryn/features/companion/domain/room_companion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showRoomCompanionSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AuvorynColors.slate,
      builder: (_) => const FractionallySizedBox(
        heightFactor: .86,
        child: RoomCompanionSheet(),
      ),
    );

/// A calm, offline character editor, separate from room and music persistence.
class RoomCompanionSheet extends ConsumerWidget {
  const RoomCompanionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(roomCompanionProvider);
    final companion = status.companion;
    final controller = ref.read(roomCompanionProvider.notifier);
    final editable = !status.loading && !status.saving && !status.readFailed;

    Future<void> apply(Future<bool> change) async {
      if (!await change && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Companion could not be saved.')),
        );
      }
    }

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(
        letterSpacing: 1.6, fontSize: 10, color: AuvorynColors.champagne,
      )),
    );

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 34),
        children: [
          Row(children: [
            Expanded(child: Text('Someone to share the quiet.',
                style: AppTheme.editorial(size: 32))),
            IconButton(
              tooltip: 'Close companion editor',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ]),
          const SizedBox(height: 8),
          const Text(
            'A little presence in your apartment. Choose a look and a place '
            'to settle. Everything stays on this device.',
            style: TextStyle(color: AuvorynColors.mist, height: 1.5),
          ),
          if (status.loading) const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
          if (status.error != null) Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Text(status.error!,
                style: const TextStyle(color: Color(0xFFFFB2B2))),
          ),
          const SizedBox(height: 19),
          SwitchListTile.adaptive(
            key: const Key('companion_visible'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Companion in the room'),
            subtitle: const Text('Hide at any time, without losing your look.'),
            value: companion.visible,
            onChanged: editable
                ? (value) => apply(controller.setVisible(value))
                : null,
          ),
          const SizedBox(height: 23),
          label('CHOOSE YOUR COMPANION'),
          Wrap(spacing: 9, runSpacing: 8, children: [
            for (final style in CompanionStyle.values)
              ChoiceChip(
                key: Key('companion_style_${style.name}'),
                selected: companion.style == style,
                label: Text(style.label),
                onSelected: editable ? (_) => apply(controller.setStyle(style))
                    : null,
              ),
          ]),
          const SizedBox(height: 25),
          label('WHERE THEY RELAX'),
          Wrap(spacing: 9, runSpacing: 8, children: [
            for (final pose in CompanionPose.values)
              ChoiceChip(
                key: Key('companion_pose_${pose.name}'),
                selected: companion.pose == pose,
                label: Text(pose.label),
                onSelected: editable ? (_) => apply(controller.setPose(pose))
                    : null,
              ),
          ]),
          const SizedBox(height: 25),
          label('HAIR'),
          Wrap(spacing: 9, runSpacing: 8, children: [
            for (final hair in CompanionHair.values)
              ChoiceChip(
                key: Key('companion_hair_${hair.name}'),
                selected: companion.hair == hair,
                label: Text(hair.label),
                onSelected: editable ? (_) => apply(controller.setHair(hair))
                    : null,
              ),
          ]),
          const SizedBox(height: 25),
          label('COMPLEXION'),
          Wrap(spacing: 9, runSpacing: 8, children: [
            for (final skin in CompanionSkin.values)
              ChoiceChip(
                key: Key('companion_skin_${skin.name}'),
                selected: companion.skin == skin,
                label: Text(skin.label),
                onSelected: editable ? (_) => apply(controller.setSkin(skin))
                    : null,
              ),
          ]),
          const SizedBox(height: 25),
          label('COZY LAYERS'),
          Wrap(spacing: 9, runSpacing: 8, children: [
            for (final outfit in CompanionOutfit.values)
              ChoiceChip(
                key: Key('companion_outfit_${outfit.name}'),
                selected: companion.outfit == outfit,
                label: Text(outfit.label),
                onSelected: editable
                    ? (_) => apply(controller.setOutfit(outfit))
                    : null,
              ),
          ]),
          const SizedBox(height: 22),
          const Text(
            'Saved automatically · No camera, account or connection required. '
            'The companion does not affect your music or listening sessions.',
            style: TextStyle(fontSize: 12, color: AuvorynColors.mist,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}
