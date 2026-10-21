import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/widgets/auvoryn_logo.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:auvoryn/features/music/domain/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum LibrarySection { songs, favorites, playlists }

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  LibrarySection _section = LibrarySection.songs;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final music = ref.watch(musicProvider);
    final controller = ref.read(musicProvider.notifier);
    final query = _query.trim().toLowerCase();
    final displayed = music.songs.where((s) {
      if (_section == LibrarySection.favorites && !s.isFavorite) return false;
      return s.title.toLowerCase().contains(query) ||
        s.artist.toLowerCase().contains(query) || s.fileName.toLowerCase().contains(query);
    }).toList();

    return SafeArea(child: ListView(
      key: const PageStorageKey('library_scroll'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const AuvorynLogo(),
          IconButton(
            tooltip: 'Settings', onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune_rounded),
            style: IconButton.styleFrom(minimumSize: const Size(48, 48),
              backgroundColor: AuvorynColors.slate),
          ),
        ]),
        const SizedBox(height: 30),
        const Text('YOUR COLLECTION  /  002',
          style: TextStyle(color: AuvorynColors.champagne, fontSize: 11, letterSpacing: 1.8)),
        const SizedBox(height: 10),
        Text('Every song, yours.', style: AppTheme.editorial(size: 39)),
        const SizedBox(height: 12),
        Text('${music.songs.length} songs, safely kept on this device.',
          style: const TextStyle(color: AuvorynColors.mist, fontSize: 14)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          key: const Key('import_music'),
          onPressed: music.loading || music.restoring ? null : () async {
            final count = await controller.importMusic();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
              count > 0 ? 'Imported $count song${count == 1 ? '' : 's'} for offline listening.'
                : 'No new music was imported. Check for duplicates or try again.',
            )));
          },
          icon: music.loading ? const SizedBox(height: 18, width: 18,
            child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_rounded),
          label: Text(music.loading ? 'IMPORTING…' : 'IMPORT MUSIC'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 53),
            backgroundColor: AuvorynColors.champagne, foregroundColor: AuvorynColors.ink,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        )),
        if (music.error != null) Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(music.error!, style: const TextStyle(color: Color(0xFFFF9F9A), fontSize: 13)),
        ),
        const SizedBox(height: 22),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (final section in LibrarySection.values)
            Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
              label: Text(switch (section) {
                LibrarySection.songs => 'Songs',
                LibrarySection.favorites => 'Favorites',
                LibrarySection.playlists => 'Playlists',
              }),
              selected: _section == section,
              onSelected: (_) => setState(() => _section = section),
            )),
        ])),
        const SizedBox(height: 21),
        if (_section != LibrarySection.playlists) ...[
          TextField(
            key: const Key('search_music'),
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search your music',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true, fillColor: AuvorynColors.slate,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
          const SizedBox(height: 19),
          if (displayed.isNotEmpty) Row(children: [
            Expanded(child: Text('${displayed.length} TRACKS',
              style: const TextStyle(color: AuvorynColors.mist,
                fontSize: 11, letterSpacing: 1.5))),
            TextButton.icon(onPressed: () async {
              await controller.playSongs(displayed);
              if (context.mounted && ref.read(musicProvider).currentSong != null) {
                context.push('/now-playing');
              }
            }, icon: const Icon(Icons.play_arrow_rounded, size: 19),
              label: const Text('Play all')),
          ]),
          if (displayed.isEmpty)
            _EmptyCollection(
              icon: _section == LibrarySection.favorites ? Icons.favorite_outline_rounded : Icons.album_outlined,
              title: music.songs.isEmpty ? 'Your soundtrack starts here' : 'Nothing in this collection',
              detail: music.songs.isEmpty
                ? 'Import music from your device. Selected songs are copied into AUVORYN for offline listening.'
                : _section == LibrarySection.favorites
                  ? 'Tap the heart beside a track to save your favorites.'
                  : 'Try a different search.',
            )
          else
            for (var i = 0; i < displayed.length; i++)
              SongRow(song: displayed[i], onTap: () async {
                await controller.playSongs(displayed, startIndex: i);
                if (context.mounted && ref.read(musicProvider).currentSong != null) {
                  context.push('/now-playing');
                }
              }),
        ] else ...[
          Row(children: [
            const Expanded(child: Text('PERSONAL PLAYLISTS',
              style: TextStyle(letterSpacing: 1.4, fontSize: 11, color: AuvorynColors.mist))),
            TextButton.icon(onPressed: () => _createPlaylist(context),
              icon: const Icon(Icons.add_rounded), label: const Text('Create')),
          ]),
          const SizedBox(height: 12),
          if (music.playlists.isEmpty)
            const _EmptyCollection(icon: Icons.queue_music_rounded,
              title: 'Make it yours',
              detail: 'Create a playlist and add your favorite local songs.')
          else
            for (final playlist in music.playlists)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                leading: const _SongArtwork(icon: Icons.queue_music_rounded),
                title: Text(playlist.name),
                subtitle: Text('${playlist.songIds.length} tracks',
                  style: const TextStyle(color: AuvorynColors.mist)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/library/playlist/${playlist.id}'),
              ),
        ],
      ],
    ));
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final name = await playlistNameDialog(context, title: 'New playlist');
    if (name == null || !context.mounted) return;
    try {
      await ref.read(musicProvider.notifier).createPlaylist(name);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create playlist: $error')),
        );
      }
    }
  }
}

Future<String?> playlistNameDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PlaylistNameDialog(
      title: title,
      initialName: initialName,
    ),
  );
}

/// Owns the input controller for the entire lifetime of the dialog route.
///
/// showDialog completes as the route is popped, potentially before its reverse
/// transition finishes. Disposing a controller in a caller's finally block can
/// therefore leave the exiting TextField referencing a disposed controller.
class _PlaylistNameDialog extends StatefulWidget {
  const _PlaylistNameDialog({
    required this.title,
    required this.initialName,
  });

  final String title;
  final String initialName;

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _save() {
    final name = _input.text.trim();
    if (name.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('playlist_name_input'),
        controller: _input,
        autofocus: true,
        maxLength: 60,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(labelText: 'Playlist name'),
      ),
      actions: [
        TextButton(
          key: const Key('playlist_cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('playlist_save'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class SongRow extends ConsumerWidget {
  const SongRow({required this.song, required this.onTap, super.key});
  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        key: Key('song_${song.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 8, 0, 8),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF58434A), Color(0xFF272A34), AuvorynColors.slate],
                ),
              ),
              child: const Icon(Icons.album_rounded,
                color: AuvorynColors.champagne, size: 27),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w600, color: AuvorynColors.ivory)),
                const SizedBox(height: 5),
                Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AuvorynColors.mist)),
              ],
            )),
            if (song.isFavorite)
              const Padding(
                padding: EdgeInsets.only(right: 3),
                child: Icon(Icons.favorite_rounded,
                  color: AuvorynColors.champagne, size: 15),
              ),
            PopupMenuButton<String>(
              tooltip: 'Track actions',
              icon: const Icon(Icons.more_horiz_rounded,
                color: AuvorynColors.mist),
              onSelected: (action) {
                if (action == 'favorite') {
                  ref.read(musicProvider.notifier).toggleFavorite(song);
                } else if (action == 'playlist') {
                  showAddToPlaylistSheet(context, song);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'favorite', child: Text(
                  song.isFavorite ? 'Remove favorite' : 'Add to favorites')),
                const PopupMenuItem(value: 'playlist', child: Text('Add to playlist…')),
              ],
            ),
          ]),
        ),
      ),
    ),
  );
}

class _SongArtwork extends StatelessWidget {
  const _SongArtwork({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 50, height: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(13), color: AuvorynColors.raised,
    ),
    child: Icon(icon, color: AuvorynColors.champagne, size: 24),
  );
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 14), padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(color: AuvorynColors.slate,
      borderRadius: BorderRadius.circular(24)),
    child: Column(children: [
      Icon(icon, size: 53, color: AuvorynColors.champagne),
      const SizedBox(height: 20),
      Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text(detail, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: AuvorynColors.mist, height: 1.5)),
    ]),
  );
}

Future<void> showAddToPlaylistSheet(BuildContext context, Song song) =>
  showModalBottomSheet<void>(
    context: context, showDragHandle: true, isScrollControlled: true,
    builder: (context) => Consumer(builder: (context, ref, _) {
      final playlists = ref.watch(musicProvider).playlists;
      return SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 25),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add to playlist', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (playlists.isEmpty) const Text('Create a playlist from the Library tab first.'),
          for (final playlist in playlists)
            CheckboxListTile(
              title: Text(playlist.name),
              value: playlist.songIds.contains(song.id),
              onChanged: (_) => ref.read(musicProvider.notifier)
                .toggleSongInPlaylist(playlist, song),
            ),
        ]),
      ));
    }),
  );
