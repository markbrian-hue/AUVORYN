import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
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
    final song = ref.watch(musicProvider.select((m) => m.currentSong));
    final playing = ref.watch(musicProvider.select((m) => m.playing));
    final controller = ref.read(roomSettingsProvider.notifier);
    Future<void> save(Future<bool> operation) async {
      if (!await operation && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your room could not be saved. Please try again.'),
          ),
        );
      }
    }

    void openRecord() {
      if (song == null) {
        context.go('/library');
      } else {
        context.push('/now-playing');
      }
    }

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('room_scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AuvorynLogo(),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AuvorynColors.slate,
                          minimumSize: const Size(48, 48),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 27),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AuvorynColors.champagne,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'A LITTLE WORLD OF YOUR OWN',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.8,
                            color: AuvorynColors.champagne,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Midnight Apartment',
                    style: AppTheme.editorial(size: 43),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Settle in. Let the world wait.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AuvorynColors.mist),
                  ),
                  const SizedBox(height: 24),
                  RoomScene(
                    settings: settings,
                    hasTrack: song != null,
                    isPlaying: playing,
                    onRecordTap: openRecord,
                    onSpeakerTap: () {
                      if (song == null) {
                        context.go('/library');
                      } else {
                        ref.read(musicProvider.notifier).togglePlay();
                      }
                    },
                    onWindowTap: () => showAtmosphereSheet(context),
                    onLampTap: () => save(
                      controller.setLamp(
                        !ref.read(roomSettingsProvider).lampOn,
                      ),
                    ),
                    onShelfTap: () => context.go('/library'),
                  ),
                  const SizedBox(height: 19),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RoomAction(
                        label: 'Atmosphere',
                        icon: Icons.blur_on_rounded,
                        onTap: () => showAtmosphereSheet(context),
                      ),
                      _RoomAction(
                        label: settings.lampOn ? 'Lamp on' : 'Lamp off',
                        icon: settings.lampOn
                            ? Icons.lightbulb_outline
                            : Icons.lightbulb_outline_rounded,
                        selected: settings.lampOn,
                        onTap: () => save(
                          controller.setLamp(
                            !ref.read(roomSettingsProvider).lampOn,
                          ),
                        ),
                      ),
                      _RoomAction(
                        key: const Key('customize_window'),
                        label: 'Window view',
                        icon: Icons.landscape_outlined,
                        onTap: () => showWindowViewSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 29),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Make it your moment',
                          style: AppTheme.editorial(size: 27),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => showAtmosphereSheet(context),
                        child: const Text(
                          'Fine-tune',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, bounds) {
                      final largeText =
                          MediaQuery.textScalerOf(context).scale(12) > 18;
                      final width = largeText
                          ? bounds.maxWidth
                          : (bounds.maxWidth - 16) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final preset in const [
                            (
                              RoomMood.quietMidnight,
                              'After hours',
                              Icons.nights_stay_outlined,
                              Color(0xFF303A53),
                            ),
                            (
                              RoomMood.lightRain,
                              'Soft rain',
                              Icons.water_drop_outlined,
                              Color(0xFF314A55),
                            ),
                            (
                              RoomMood.warmSunset,
                              'Golden hour',
                              Icons.wb_twilight_rounded,
                              Color(0xFF755342),
                            ),
                          ])
                            SizedBox(
                              width: width,
                              child: _MoodCard(
                                key: Key('home_mood_${preset.$1.name}'),
                                label: preset.$2,
                                icon: preset.$3,
                                color: preset.$4,
                                selected: settings.mood == preset.$1,
                                onTap: () =>
                                    save(controller.setMood(preset.$1)),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${settings.mood.title} · ${settings.windowView.title}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 25),
                  _ListeningCard(
                    title: song?.title,
                    artist: song?.artist,
                    playing: playing,
                    onTap: openRecord,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AuvorynColors.raised),
                      ),
                      Flexible(
                        flex: 8,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'Sound, somewhere yours.',
                            textAlign: TextAlign.center,
                            style: AppTheme.editorial(
                              size: 20,
                              color: AuvorynColors.mist,
                            ),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AuvorynColors.raised),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomAction extends StatelessWidget {
  const _RoomAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    super.key,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF2C2823) : AuvorynColors.slate,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(
        color: selected ? const Color(0xFF65543F) : AuvorynColors.raised,
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AuvorynColors.champagne : AuvorynColors.mist,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(label, style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: reduced ? Duration.zero : AuvorynMotion.normal,
        decoration: BoxDecoration(
          color: selected ? color : AuvorynColors.slate,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFBBA78A) : AuvorynColors.raised,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: 21,
                        color: selected
                            ? AuvorynColors.ivory
                            : AuvorynColors.mist,
                      ),
                      const Spacer(),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          size: 12,
                          color: AuvorynColors.champagne,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListeningCard extends StatelessWidget {
  const _ListeningCard({
    required this.title,
    required this.artist,
    required this.playing,
    required this.onTap,
  });
  final String? title;
  final String? artist;
  final bool playing;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF1D222B),
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6E6355)),
                gradient: const RadialGradient(
                  colors: [Color(0xFF76614A), Color(0xFF25282F)],
                  stops: [.2, .24],
                ),
              ),
              child: Icon(
                title == null ? Icons.add_rounded : Icons.music_note_rounded,
                color: AuvorynColors.champagne,
                size: 19,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title == null
                        ? 'YOUR COLLECTION STARTS HERE'
                        : playing
                        ? 'ON THE TURNTABLE'
                        : 'READY WHEN YOU ARE',
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.1,
                      color: AuvorynColors.champagne,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title ?? 'Choose your first record',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title == null
                        ? 'Import music. Make yourself at home.'
                        : artist ?? 'Your personal collection',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AuvorynColors.mist,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_outward_rounded,
              size: 18,
              color: AuvorynColors.champagne,
            ),
          ],
        ),
      ),
    ),
  );
}
