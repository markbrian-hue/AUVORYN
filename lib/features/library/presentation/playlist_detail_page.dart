import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/features/library/presentation/library_page.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:auvoryn/features/music/domain/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlaylistDetailPage extends ConsumerWidget {
  const PlaylistDetailPage({required this.playlistId, super.key});
  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final music = ref.watch(musicProvider);
    final matching = music.playlists.where((p) => p.id == playlistId);
    if (matching.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('This playlist no longer exists.')),
      );
    }
    final playlist = matching.first;
    final indexed = {for (final s in music.songs) s.id: s};
    final songs = [for (final id in playlist.songIds) if (indexed[id] != null) indexed[id]!];
    final controller = ref.read(musicProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AuvorynColors.ink, title: const Text('YOUR PLAYLIST'),
        actions: [
          PopupMenuButton<String>(itemBuilder: (_) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete playlist')),
          ], onSelected: (value) async {
            if (value == 'rename') {
              final name = await playlistNameDialog(context,
                title: 'Rename playlist', initialName: playlist.name);
              if (name != null) await controller.renamePlaylist(playlist, name);
            } else {
              final confirmed = await showDialog<bool>(context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete playlist?'),
                  content: const Text('The songs will remain in your library.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete')),
                  ],
                ));
              if (confirmed == true) {
                await controller.deletePlaylist(playlist);
                if (context.mounted) context.pop();
              }
            }
          }),
        ],
      ),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          const SizedBox(height: 21),
          Text(playlist.name, style: AppTheme.editorial(size: 39)),
          const SizedBox(height: 12),
          Text('${songs.length} tracks · offline',
            style: const TextStyle(color: AuvorynColors.mist)),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: songs.isEmpty ? null : () async {
            await controller.playSongs(songs);
            if (context.mounted) context.push('/now-playing');
          }, icon: const Icon(Icons.play_arrow_rounded), label: const Text('PLAY PLAYLIST')),
          const SizedBox(height: 21),
          if (songs.isEmpty) const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Text('Use the menu next to a song in your Library to add it here.',
              textAlign: TextAlign.center),
          ),
          for (var i = 0; i < songs.length; i++)
            SongRow(song: songs[i], onTap: () async {
              await controller.playSongs(songs, startIndex: i);
              if (context.mounted) context.push('/now-playing');
            }),
          const SizedBox(height: 18),
          if (songs.isNotEmpty) OutlinedButton.icon(
            onPressed: () => _selectSongs(context, ref, playlist),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Manage songs'),
          ) else OutlinedButton.icon(
            onPressed: () => _selectSongs(context, ref, playlist),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add songs'),
          ),
        ],
      )),
    );
  }

  Future<void> _selectSongs(BuildContext context, WidgetRef ref,
    MusicPlaylist playlist) async {
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (context) => Consumer(builder: (context, modalRef, _) {
        final state = modalRef.watch(musicProvider);
        // The playlist may disappear while this modal route is still mounted.
        // Do not call .first on an empty collection during reverse transitions.
        final matching = state.playlists.where((p) => p.id == playlist.id);
        if (matching.isEmpty) {
          return const SafeArea(child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('This playlist is no longer available.'),
          ));
        }
        final updated = matching.first;
        return SafeArea(child: FractionallySizedBox(
          heightFactor: .70,
          child: Column(children: [
            const Padding(padding: EdgeInsets.all(16),
              child: Text('Choose tracks', style: TextStyle(fontSize: 19))),
            Expanded(child: ListView(children: [
              for (final song in state.songs)
                CheckboxListTile(
                  title: Text(song.title), subtitle: Text(song.artist),
                  value: updated.songIds.contains(song.id),
                  onChanged: (_) => modalRef.read(musicProvider.notifier)
                    .toggleSongInPlaylist(updated, song),
                ),
            ])),
          ]),
        ));
      }),
    );
  }
}
