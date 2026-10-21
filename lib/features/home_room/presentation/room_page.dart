import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/core/widgets/auvoryn_logo.dart';
import 'package:auvoryn/features/atmosphere/presentation/atmosphere_sheet.dart';
import 'package:auvoryn/features/customization/presentation/window_view_sheet.dart';
import 'package:auvoryn/features/home_room/presentation/room_scene.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RoomPage extends ConsumerWidget {
  const RoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(roomSettingsProvider);
    // Select only the current title so high-frequency position updates do not
    // rebuild the heavyweight room scene every few milliseconds.
    final currentTitle = ref.watch(musicProvider.select(
      (music) => music.currentSong?.title,
    ));
    // Only playback transitions matter for the room. Progress ticks must not
    // rebuild its expensive decorative painter.
    final isPlaying = ref.watch(musicProvider.select(
      (music) => music.playing,
    ));
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
                    hasTrack: currentTitle != null,
                    isPlaying: isPlaying,
                    onRecordTap: () => currentTitle == null
                        ? context.go('/library') : context.push('/now-playing'),
                    onSpeakerTap: () {
                      if (currentTitle == null) {
                        context.go('/library');
                      } else {
                        ref.read(musicProvider.notifier).togglePlay();
                      }
                    },
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
                  const SizedBox(height: 11),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Row(children: [
                      Icon(Icons.touch_app_outlined,
                        size: 15, color: AuvorynColors.champagne),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'Explore: record · speakers · lamp · window · shelf',
                        style: TextStyle(color: AuvorynColors.mist, fontSize: 11),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 11),
                  Align(alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const Key('customize_window'),
                      onPressed: () => showWindowViewSheet(context),
                      icon: const Icon(Icons.wallpaper_outlined,size: 19),
                      label: Text('View: ${settings.windowView.title}'),
                    ),
                  ),
                  if (currentTitle != null) ...[
                    const SizedBox(height: 17),
                    Material(
                      color: AuvorynColors.raised,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => context.push('/now-playing'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17, vertical: 12),
                          child: Row(children: [
                            const Icon(Icons.album_rounded,
                              color: AuvorynColors.champagne, size: 25),
                            const SizedBox(width: 13),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ON THE TURNTABLE',
                                  style: TextStyle(fontSize: 10,
                                    letterSpacing: 1.5,
                                    color: AuvorynColors.champagne)),
                                const SizedBox(height: 4),
                                Text(currentTitle, maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                              ],
                            )),
                            Icon(isPlaying ? Icons.equalizer_rounded : Icons.pause_circle_outline,
                              color: AuvorynColors.champagne, size: 19),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_outward_rounded,
                              color: AuvorynColors.mist, size: 19),
                          ]),
                        ),
                      ),
                    ),
                  ],
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
