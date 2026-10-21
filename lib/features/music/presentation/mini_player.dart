import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final music = ref.watch(musicProvider);
    final song = music.currentSong;
    if (song == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 4),
      child: Material(
        color: AuvorynColors.raised,
        borderRadius: BorderRadius.circular(19),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => context.push('/now-playing'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 6, 5, 6),
                child: Row(children: [
                  const _MiniArtwork(),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AuvorynColors.mist, fontSize: 12)),
                    ],
                  )),
                  IconButton(
                    key: const Key('mini_toggle'),
                    onPressed: music.restoring ? null : () => ref.read(musicProvider.notifier).togglePlay(),
                    icon: Icon(music.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    tooltip: music.playing ? 'Pause' : 'Play',
                    iconSize: 29,
                  ),
                  IconButton(
                    tooltip: 'Next track',
                    onPressed: () => ref.read(musicProvider.notifier).next(),
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ]),
              ),
            ),
            LinearProgressIndicator(
              minHeight: 2,
              value: music.duration.inMilliseconds <= 0 ? 0 :
                (music.position.inMilliseconds / music.duration.inMilliseconds).clamp(0.0, 1.0).toDouble(),
              backgroundColor: AuvorynColors.slate,
              color: AuvorynColors.champagne,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniArtwork extends StatelessWidget {
  const _MiniArtwork();
  @override
  Widget build(BuildContext context) => Container(
    width: 47, height: 47,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AuvorynColors.slate, Color(0xFF5E4B50)]),
      borderRadius: BorderRadius.circular(13),
    ),
    child: const Icon(Icons.album_rounded, color: AuvorynColors.champagne),
  );
}
