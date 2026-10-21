import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/widgets/auvoryn_logo.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:auvoryn/features/memories/domain/listening_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MemoriesPage extends ConsumerWidget {
  const MemoriesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(listeningSnapshotProvider);
    return SafeArea(child: RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(listeningSnapshotProvider);
        await ref.read(listeningSnapshotProvider.future);
      },
      child: ListView(padding: const EdgeInsets.fromLTRB(24,16,24,36),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const AuvorynLogo(),
            IconButton(tooltip: 'Settings', icon: const Icon(Icons.tune_rounded),
              onPressed: () => context.push('/settings')),
          ]),
          const SizedBox(height: 36),
          const Text('YOUR JOURNAL  /  003', style: TextStyle(
            color: AuvorynColors.champagne,fontSize: 11,letterSpacing: 1.8)),
          const SizedBox(height: 10),
          Text('Moments in music.',style: AppTheme.editorial(size: 39)),
          const SizedBox(height: 12),
          const Text('Your listening story, stored only on this device.',
            style: TextStyle(color: AuvorynColors.mist,height: 1.5)),
          const SizedBox(height: 26),
          history.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Column(children: [
              const Text('Unable to load local listening history.'),
              TextButton(onPressed: () => ref.invalidate(listeningSnapshotProvider),
                child: const Text('Retry')),
            ]),
            data: (snapshot) => snapshot.tracks == 0
              ? const _EmptyJournal() : _Journal(snapshot: snapshot)),
          const SizedBox(height: 22),
          const Text('History begins with this update. Paused time and seeking do not count. '
            'Times are estimates and may undercount if Android suspends playback callbacks.',
            style: TextStyle(color: AuvorynColors.mist,fontSize: 12,height: 1.5)),
        ],
      ),
    ));
  }
}
class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(color: AuvorynColors.slate,
      borderRadius: BorderRadius.circular(24)),
    child: const Column(children: [
      Icon(Icons.auto_stories_outlined,size: 49,color: AuvorynColors.champagne),
      SizedBox(height: 18),
      Text('Your story starts with a song.',textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18)),
      SizedBox(height: 10),
      Text('Play some music, then return to see real listening statistics.',
        textAlign: TextAlign.center,style: TextStyle(color: AuvorynColors.mist)),
    ]),
  );
}
class _Journal extends ConsumerWidget {
  const _Journal({required this.snapshot});
  final ListeningSnapshot snapshot;
  String _duration(int ms) {
    final seconds = ms ~/ 1000;
    if (seconds < 60) return '$seconds sec';
    final hours = seconds ~/ 3600, minutes = (seconds % 3600) ~/ 60;
    return hours > 0 ? '$hours hr $minutes min' : '$minutes min';
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: _StatCard('LISTENING TIME',_duration(snapshot.totalMs))),
      const SizedBox(width: 9),
      Expanded(child: _StatCard('QUALIFIED PLAYS','${snapshot.totalPlays}')),
    ]),
    const SizedBox(height: 12),
    Text('${snapshot.tracks} tracks played',style: const TextStyle(color: AuvorynColors.mist)),
    if (snapshot.topArtist != null) ...[
      const SizedBox(height: 23),
      const Text('MOST LISTENED ARTIST',style: TextStyle(color: AuvorynColors.champagne,fontSize: 11,letterSpacing: 1.5)),
      const SizedBox(height: 8),
      Text(snapshot.topArtist!,style: AppTheme.editorial(size: 28)),
    ],
    const SizedBox(height: 23),
    const Text('MOST LISTENED TRACKS',style: TextStyle(color: AuvorynColors.champagne,fontSize: 11,letterSpacing: 1.5)),
    for (final song in snapshot.topTracks) _TrackRow(song,_duration(song.listenedMs)),
    const SizedBox(height: 23),
    const Text('RECENTLY LISTENED',style: TextStyle(color: AuvorynColors.champagne,fontSize: 11,letterSpacing: 1.5)),
    for (final song in snapshot.recent.take(10)) _TrackRow(song,
      '${song.lastPlayedAt.toLocal().month}/${song.lastPlayedAt.toLocal().day}'),
    const SizedBox(height: 12),
    const Text('A qualified play means 10 seconds of listening, not an entire track.',
      style: TextStyle(color: AuvorynColors.mist,fontSize: 12)),
    Align(alignment: Alignment.centerRight,child: TextButton.icon(
      key: const Key('clear_listening_history'),
      icon: const Icon(Icons.delete_outline), label: const Text('Clear history'),
      onPressed: () async {
        final confirm = await showDialog<bool>(context: context,builder: (dialog) => AlertDialog(
          title: const Text('Clear listening history?'),
          content: const Text('This keeps your music, playlists, and favorites.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog,false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialog,true), child: const Text('Clear')),
          ]));
        if (confirm != true || !context.mounted) return;
        try {
          await ref.read(musicProvider.notifier).clearListeningHistory();
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to clear listening history.')),
            );
          }
        }
      })),
  ]);
}
class _StatCard extends StatelessWidget {
  const _StatCard(this.label,this.value);
  final String label,value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: AuvorynColors.slate,
      borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      Text(value,maxLines: 1,overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 23,fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(label,style: const TextStyle(fontSize: 10,color: AuvorynColors.mist)),
    ]));
}
class _TrackRow extends StatelessWidget {
  const _TrackRow(this.track,this.detail);
  final ListeningTrack track;
  final String detail;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.album_outlined,color: AuvorynColors.champagne),
    title: Text(track.title,maxLines: 1,overflow: TextOverflow.ellipsis),
    subtitle: Text(track.artist,maxLines: 1,overflow: TextOverflow.ellipsis),
    trailing: Text(detail,style: const TextStyle(color: AuvorynColors.mist)),
  );
}
