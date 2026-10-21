import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NowPlayingPage extends ConsumerWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final music = ref.watch(musicProvider);
    final controller = ref.read(musicProvider.notifier);
    final song = music.currentSong;
    if (song == null) {
      return Scaffold(appBar: AppBar(title: const Text('Now playing')),
        body: const Center(child: Text('Choose a track from your library.')));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AuvorynColors.ink,
        leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 31),
          onPressed: () => Navigator.of(context).pop(), tooltip: 'Close player'),
        title: const Text('NOW PLAYING', style: TextStyle(fontSize: 11, letterSpacing: 2.5)),
        centerTitle: true,
      ),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final artwork = (constraints.maxHeight * .43).clamp(160.0, 340.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(27, 12, 27, 26),
          children: [
            const SizedBox(height: 12),
            Center(child: Container(
              width: artwork, height: artwork,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF292D3A), Color(0xFF584954), Color(0xFF15171E)]),
                boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 34, offset: Offset(0, 18))],
              ),
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: artwork * .68, height: artwork * .68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF101116),
                    border: Border.all(color: const Color(0xFF373843), width: 7),
                  ),
                  child: Center(child: Container(
                    width: artwork * .25, height: artwork * .25,
                    decoration: const BoxDecoration(shape: BoxShape.circle,
                      color: AuvorynColors.champagne),
                    child: const Icon(Icons.music_note_rounded, color: AuvorynColors.ink),
                  )),
                ),
                Positioned(bottom: 14, right: 18, child: Text('auvoryn',
                  style: TextStyle(color: AuvorynColors.ivory.withValues(alpha: .65),
                    letterSpacing: 2, fontSize: 12))),
              ]),
            )),
            const SizedBox(height: 32),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(song.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(song.artist, style: const TextStyle(color: AuvorynColors.mist)),
              ])),
              IconButton(
                onPressed: () => controller.toggleFavorite(song),
                tooltip: song.isFavorite ? 'Remove favorite' : 'Add favorite',
                icon: Icon(song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: song.isFavorite ? AuvorynColors.champagne : AuvorynColors.mist),
              ),
            ]),
            const SizedBox(height: 24),
            SliderTheme(data: SliderTheme.of(context).copyWith(
              trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ), child: Slider(
              value: music.duration.inMilliseconds == 0 ? 0 :
                music.position.inMilliseconds.toDouble().clamp(0.0, music.duration.inMilliseconds.toDouble()).toDouble(),
              max: music.duration.inMilliseconds > 0 ? music.duration.inMilliseconds.toDouble() : 1,
              onChanged: music.duration.inMilliseconds <= 0 ? null :
                (value) => controller.seek(Duration(milliseconds: value.round())),
            )),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(_time(music.position)), Text(_time(music.duration))],
            )),
            const SizedBox(height: 13),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              IconButton(
                onPressed: controller.toggleShuffle,
                icon: Icon(Icons.shuffle_rounded,
                  color: music.shuffle ? AuvorynColors.champagne : AuvorynColors.mist),
                tooltip: 'Shuffle',
              ),
              IconButton(iconSize: 35, onPressed: controller.previous,
                tooltip: 'Previous track', icon: const Icon(Icons.skip_previous_rounded)),
              Material(color: AuvorynColors.champagne, shape: const CircleBorder(),
                child: IconButton(
                  key: const Key('player_toggle'),
                  iconSize: 41,
                  constraints: const BoxConstraints(minWidth: 76, minHeight: 76),
                  color: AuvorynColors.ink,
                  onPressed: controller.togglePlay,
                  tooltip: music.playing ? 'Pause' : 'Play',
                  icon: Icon(music.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
              ),
              IconButton(iconSize: 35, onPressed: controller.next,
                tooltip: 'Next track', icon: const Icon(Icons.skip_next_rounded)),
              IconButton(
                onPressed: controller.cycleRepeat,
                tooltip: 'Repeat mode',
                icon: Icon(music.repeat.name == 'one' ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                  color: music.repeat.name == 'off' ? AuvorynColors.mist : AuvorynColors.champagne),
              ),
            ]),
            const SizedBox(height: 25),
            ExpansionTile(
              title: Text('Up next · ${music.queueIds.length} tracks',
                style: const TextStyle(fontWeight: FontWeight.w600)),
              iconColor: AuvorynColors.champagne,
              children: [
                for (var i = 0; i < music.queueIds.length; i++)
                  Builder(builder: (context) {
                    final match = music.songs.where((s) => s.id == music.queueIds[i]);
                    if (match.isEmpty) return const SizedBox.shrink();
                    return ListTile(
                      dense: true, selected: i == music.currentIndex,
                      title: Text(match.first.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      leading: Icon(i == music.currentIndex ? Icons.graphic_eq_rounded : Icons.music_note_outlined),
                      onTap: () => controller.jumpTo(i),
                    );
                  }),
              ],
            ),
            if (music.error != null) Padding(padding: const EdgeInsets.only(top: 16),
              child: Text(music.error!, style: const TextStyle(color: Color(0xFFFF9F9A)))),
          ],
        );
      })),
    );
  }

  static String _time(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
