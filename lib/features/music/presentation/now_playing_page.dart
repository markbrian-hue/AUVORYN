import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/widgets/vinyl_artwork.dart';
import 'package:auvoryn/core/widgets/song_artwork.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NowPlayingPage extends ConsumerStatefulWidget {
  const NowPlayingPage({super.key});

  @override
  ConsumerState<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends ConsumerState<NowPlayingPage> {
  double? _scrubbingMs;
  String? _trackId;
  bool _preferVinyl = false;

  @override
  Widget build(BuildContext context) {
    final music = ref.watch(musicProvider);
    final controller = ref.read(musicProvider.notifier);
    final song = music.currentSong;
    if (song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Now playing')),
        body: const Center(child: Text('Choose a track from your library.')),
      );
    }

    if (_trackId != song.id) {
      _trackId = song.id;
      _scrubbingMs = null;
      _preferVinyl = false;
    }
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final totalMs = music.duration.inMilliseconds.toDouble();
    final maxMs = totalMs > 0 ? totalMs : 1.0;
    final currentMs = (_scrubbingMs ?? music.position.inMilliseconds.toDouble())
        .clamp(0.0, maxMs);
    final remaining = music.duration - Duration(milliseconds: currentMs.round());

    return Scaffold(
      backgroundColor: AuvorynColors.ink,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.58),
            radius: 1.28,
            colors: [Color(0xFF34303B), Color(0xFF181923), AuvorynColors.ink],
            stops: [0, .53, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final diameter = (constraints.maxWidth - 104)
                .clamp(172.0, 324.0)
                .toDouble();
            return ListView(
              key: const PageStorageKey('now_playing_scroll'),
              padding: const EdgeInsets.fromLTRB(24, 5, 24, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      key: const Key('player_close'),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close player',
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                    ),
                    const Expanded(
                      child: Column(children: [
                        Text('AUVORYN / LISTENING',
                          style: TextStyle(color: AuvorynColors.mist,
                            fontSize: 10, letterSpacing: 2.3)),
                        SizedBox(height: 3),
                        Text('Now playing',
                          style: TextStyle(color: AuvorynColors.ivory,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                      ]),
                    ),
                    IconButton(
                      tooltip: 'Open playback queue',
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      onPressed: () => _openQueue(context),
                      icon: const Icon(Icons.queue_music_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: diameter + 34),
                    child: AnimatedSwitcher(
                      duration: reduceMotion ? Duration.zero : AuvorynMotion.normal,
                      switchInCurve: Curves.easeOutCubic,
                      child: Container(
                        key: ValueKey('${song.id}_${_preferVinyl ? 'vinyl' : 'cover'}'),
                        width: diameter + 26,
                        height: diameter + 30,
                        alignment: Alignment.center,
                        child: song.artworkPath != null && !_preferVinyl
                            ? DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(29),
                                  boxShadow: [BoxShadow(
                                    color: Colors.black.withValues(alpha: .38),
                                    blurRadius: 36, offset: const Offset(0, 15),
                                  )],
                                ),
                                child: SongArtwork(
                                  artworkPath: song.artworkPath,
                                  title: song.title,
                                  size: diameter,
                                  radius: 28,
                                ),
                              )
                            : VinylArtwork(
                                title: song.title,
                                size: diameter,
                                playing: music.playing,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                if (song.artworkPath != null)
                  Center(child: TextButton.icon(
                    key: const Key('toggle_artwork_view'),
                    onPressed: () => setState(() => _preferVinyl = !_preferVinyl),
                    icon: Icon(_preferVinyl ? Icons.image_outlined : Icons.album_rounded,
                      size: 16),
                    label: Text(_preferVinyl ? 'VIEW COVER' : 'VIEW VINYL'),
                    style: TextButton.styleFrom(
                      foregroundColor: AuvorynColors.champagne,
                    ),
                  ))
                else
                  Center(child: Text('YOUR PRIVATE PRESSING',
                    style: TextStyle(color: AuvorynColors.champagne.withValues(alpha: .82),
                      fontSize: 10, letterSpacing: 2.8))),
                const SizedBox(height: 29),
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: reduceMotion ? Duration.zero :
                            const Duration(milliseconds: 220),
                        child: Text(song.title,
                          key: ValueKey('title_${song.id}'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.trackHeading(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AuvorynColors.mist, fontSize: 15)),
                      if (song.album != 'Local files') ...[
                        const SizedBox(height: 3),
                        Text(song.album, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AuvorynColors.champagne, fontSize: 12)),
                      ],
                    ],
                  )),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: song.isFavorite ? 'Remove favorite' : 'Add to favorites',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => controller.toggleFavorite(song),
                    icon: Icon(song.isFavorite ? Icons.favorite_rounded :
                      Icons.favorite_outline_rounded,
                      color: song.isFavorite ? AuvorynColors.champagne : AuvorynColors.ivory),
                  ),
                ]),
                const SizedBox(height: 25),
                Semantics(
                  label: 'Playback position',
                  value: '${_time(Duration(milliseconds: currentMs.round()))} of ${_time(music.duration)}',
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 17),
                    ),
                    child: Slider(
                      key: const Key('player_seek'),
                      value: currentMs,
                      max: maxMs,
                      onChanged: totalMs <= 0 ? null : (value) =>
                        setState(() => _scrubbingMs = value),
                      onChangeEnd: totalMs <= 0 ? null : (value) {
                        setState(() => _scrubbingMs = null);
                        controller.seek(Duration(milliseconds: value.round()));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_time(Duration(milliseconds: currentMs.round())),
                      style: const TextStyle(color: AuvorynColors.mist, fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()])),
                    Text('-${_time(remaining.isNegative ? Duration.zero : remaining)}',
                      style: const TextStyle(color: AuvorynColors.mist, fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()])),
                  ]),
                ),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _TransportButton(
                    tooltip: music.shuffle ? 'Disable shuffle' : 'Enable shuffle',
                    onPressed: controller.toggleShuffle,
                    icon: Icons.shuffle_rounded,
                    active: music.shuffle,
                  ),
                  _TransportButton(
                    tooltip: 'Previous track',
                    onPressed: controller.previous,
                    icon: Icons.skip_previous_rounded,
                    size: 34,
                  ),
                  Material(
                    shape: const CircleBorder(),
                    color: AuvorynColors.champagne,
                    child: IconButton(
                      key: const Key('player_toggle'),
                      tooltip: music.playing ? 'Pause' : 'Play',
                      onPressed: music.restoring ? null : controller.togglePlay,
                      constraints: const BoxConstraints(minWidth: 78, minHeight: 78),
                      color: AuvorynColors.ink,
                      iconSize: 40,
                      icon: Icon(music.playing ? Icons.pause_rounded :
                        Icons.play_arrow_rounded),
                    ),
                  ),
                  _TransportButton(
                    tooltip: 'Next track',
                    onPressed: controller.next,
                    icon: Icons.skip_next_rounded,
                    size: 34,
                  ),
                  _TransportButton(
                    tooltip: 'Repeat ${music.repeat.name}',
                    onPressed: controller.cycleRepeat,
                    icon: music.repeat.name == 'one' ?
                      Icons.repeat_one_rounded : Icons.repeat_rounded,
                    active: music.repeat.name != 'off',
                  ),
                ]),
                const SizedBox(height: 31),
                Material(
                  color: AuvorynColors.slate.withValues(alpha: .93),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    key: const Key('open_queue'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openQueue(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                      child: Row(children: [
                        const Icon(Icons.queue_music_rounded,
                          color: AuvorynColors.champagne, size: 22),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Up next', style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${music.queueIds.length} tracks in your queue',
                              style: const TextStyle(color: AuvorynColors.mist,
                                fontSize: 12)),
                          ],
                        )),
                        const Icon(Icons.chevron_right_rounded,
                          color: AuvorynColors.mist),
                      ]),
                    ),
                  ),
                ),
                if (music.error != null) Padding(
                  padding: const EdgeInsets.only(top: 17),
                  child: Text(music.error!,
                    style: const TextStyle(color: Color(0xFFFF9F9A))),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _openQueue(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Consumer(builder: (context, ref, _) {
        final music = ref.watch(musicProvider);
        final indexed = {for (final song in music.songs) song.id: song};
        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: .72,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Row(children: [
                  Expanded(child: Text('Your queue',
                    style: AppTheme.editorial(size: 31))),
                  Text('${music.queueIds.length} tracks',
                    style: const TextStyle(color: AuvorynColors.mist)),
                ]),
              ),
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: music.queueIds.length,
                itemBuilder: (context, index) {
                  final track = indexed[music.queueIds[index]];
                  if (track == null) return const SizedBox.shrink();
                  final current = index == music.currentIndex;
                  return ListTile(
                    key: Key('queue_item_$index'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    leading: Icon(current ? Icons.graphic_eq_rounded :
                      Icons.album_outlined,
                      color: current ? AuvorynColors.champagne : AuvorynColors.mist),
                    title: Text(track.title, maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                    subtitle: Text(track.artist, maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                    selected: current,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await ref.read(musicProvider.notifier).jumpTo(index);
                    },
                  );
                },
              )),
            ]),
          ),
        );
      }),
    );
  }

  static String _time(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.active = false,
    this.size = 23,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: size,
      color: active ? AuvorynColors.champagne : AuvorynColors.ivory),
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
  );
}
