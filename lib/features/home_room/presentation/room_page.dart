import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/core/widgets/auvoryn_logo.dart';
import 'package:auvoryn/features/atmosphere/presentation/atmosphere_sheet.dart';
import 'package:auvoryn/features/home_room/presentation/room_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RoomPage extends ConsumerWidget {
  const RoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(roomSettingsProvider);
    final titleStyle = AppTheme.editorial(size: 40);
    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('room_scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AuvorynLogo(),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.tune_rounded),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: AuvorynColors.slate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 27),
                  Text(
                    'YOUR SPACE  /  001',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AuvorynColors.champagne,
                          fontSize: 11,
                          letterSpacing: 2.0,
                        ),
                  ),
                  const SizedBox(height: 11),
                  Text('Midnight Apartment', style: titleStyle),
                  const SizedBox(height: 9),
                  Text(
                    'A place for the music you own.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AuvorynColors.mist,
                        ),
                  ),
                  const SizedBox(height: 23),
                  RoomScene(
                    settings: settings,
                    onRecordTap: () => context.go('/library'),
                    onWindowTap: () => showAtmosphereSheet(context),
                    onLampTap: () async {
                      final saved = await ref
                          .read(roomSettingsProvider.notifier)
                          .setLamp(!settings.lampOn);
                      if (!saved && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Unable to save lamp settings.'),
                          ),
                        );
                      }
                    },
                    onShelfTap: () => context.go('/library'),
                  ),
                  const SizedBox(height: 19),
                  _AtmosphereCard(
                    moodName: settings.mood.title,
                    moodDetail: settings.mood.description,
                    onTap: () => showAtmosphereSheet(context),
                  ),
                  const SizedBox(height: 23),
                  Text(
                    'Sound, somewhere yours.',
                    style: AppTheme.editorial(
                      size: 25,
                      color: AuvorynColors.mist,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AtmosphereCard extends StatelessWidget {
  const _AtmosphereCard({
    required this.moodName,
    required this.moodDetail,
    required this.onTap,
  });

  final String moodName;
  final String moodDetail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AuvorynColors.slate,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const SizedBox(
                  width: 45,
                  height: 45,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AuvorynColors.raised,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.nights_stay_outlined,
                      color: AuvorynColors.champagne,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(moodName, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        moodDetail,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 15, color: AuvorynColors.mist),
              ],
            ),
          ),
        ),
      );
}
