import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/widgets/song_artwork.dart';
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
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedSize(
      duration: reduced ? Duration.zero : AuvorynMotion.normal,
      curve: AuvorynMotion.standardCurve,
      alignment: Alignment.bottomCenter,
      child: song == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(13, 8, 13, 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF32313A), AuvorynColors.raised],
                  ),
                  border: Border.all(color: const Color(0x24D8B78B)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        key: const Key('mini_open_player'),
                        onTap: () => context.push('/now-playing'),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                          child: Row(
                            children: [
                              SongArtwork(
                                artworkPath: song.artworkPath,
                                title: song.title,
                                size: 46,
                                radius: 13,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AuvorynColors.ivory,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      song.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AuvorynColors.mist,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                key: const Key('mini_toggle'),
                                tooltip: music.playing ? 'Pause' : 'Play',
                                onPressed: music.restoring
                                    ? null
                                    : () => ref
                                          .read(musicProvider.notifier)
                                          .togglePlay(),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                icon: Icon(
                                  music.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 28,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Next track',
                                onPressed: () =>
                                    ref.read(musicProvider.notifier).next(),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                icon: const Icon(
                                  Icons.skip_next_rounded,
                                  size: 25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      LinearProgressIndicator(
                        minHeight: 2,
                        value: music.duration.inMilliseconds <= 0
                            ? 0
                            : (music.position.inMilliseconds /
                                      music.duration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                                  .toDouble(),
                        backgroundColor: AuvorynColors.slate,
                        color: AuvorynColors.champagne,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
