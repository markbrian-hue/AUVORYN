import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showWindowViewSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _WindowViewSheet(),
    );

class _WindowViewSheet extends ConsumerWidget {
  const _WindowViewSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(roomSettingsProvider).windowView;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A different view.', style: AppTheme.editorial(size: 34)),
            const SizedBox(height: 8),
            const Text(
              'Change the landscape beyond your window. Saved offline.',
              style: TextStyle(color: AuvorynColors.mist),
            ),
            const SizedBox(height: 16),
            for (final view in WindowView.values) ...[
              ListTile(
                key: Key('window_view_${view.name}'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                tileColor: selected == view
                    ? AuvorynColors.raised
                    : AuvorynColors.slate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                leading: Icon(switch (view) {
                  WindowView.skyline => Icons.location_city_outlined,
                  WindowView.mountain => Icons.landscape_outlined,
                  WindowView.coast => Icons.waves_outlined,
                }, color: AuvorynColors.champagne),
                title: Text(view.title),
                subtitle: Text(
                  view.description,
                  style: const TextStyle(color: AuvorynColors.mist),
                ),
                trailing: selected == view
                    ? const Icon(
                        Icons.check_circle,
                        color: AuvorynColors.champagne,
                      )
                    : null,
                onTap: () async {
                  final saved = await ref
                      .read(roomSettingsProvider.notifier)
                      .setWindowView(view);
                  if (!saved && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not save window view.'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
