import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:auvoryn/features/music/domain/song.dart';
import 'package:auvoryn/features/scenes/application/listening_scenes_controller.dart';
import 'package:auvoryn/features/scenes/domain/listening_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> showListeningScenesSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AuvorynColors.slate,
      builder: (_) => const FractionallySizedBox(
        heightFactor: .88,
        child: ListeningScenesSheet(),
      ),
    );

/// The scene editor never owns an audio player or an app-level route.
class ListeningScenesSheet extends ConsumerWidget {
  const ListeningScenesSheet({super.key});

  void _message(BuildContext context, String text) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    ListeningScene? scene,
  }) async {
    final playlists = ref.read(musicProvider).playlists;
    final result = await showDialog<SceneFormResult>(
      context: context,
      builder: (_) => _SceneForm(scene: scene, playlists: playlists),
    );
    if (result == null || !context.mounted) return;
    final controller = ref.read(listeningScenesProvider.notifier);
    final ok = scene == null
        ? await controller.create(result.name, playlistId: result.playlistId)
        : await controller.renameAndLink(
            scene, result.name, playlistId: result.playlistId);
    if (context.mounted) {
      _message(context, ok ? 'Scene saved on this device.' :
          'Unable to save this scene. Try again.');
    }
  }

  Future<void> _delete(
    BuildContext context, WidgetRef ref, ListeningScene scene,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Delete ${scene.name}?'),
        content: const Text(
          'Only this saved scene will be deleted. Your music and room settings stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await ref.read(listeningScenesProvider.notifier).delete(scene);
    if (context.mounted) {
      _message(context, ok ? 'Scene deleted.' : 'Unable to delete scene.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(listeningScenesProvider);
    final music = ref.watch(musicProvider);
    final busy = data.loading || data.saving;
    final palettes = <String, MusicPlaylist>{
      for (final p in music.playlists) p.id: p,
    };

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 38),
        children: [
          Row(children: [
            Expanded(child: Text('Your listening scenes',
                style: AppTheme.editorial(size: 34))),
            IconButton(
              tooltip: 'Close scenes',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
          const SizedBox(height: 9),
          const Text(
            'Save an entire atmosphere. Applying a scene changes the room and '
            'ambient sound—not the active music queue.',
            style: TextStyle(color: AuvorynColors.mist, height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('scene_create'),
            onPressed: busy || data.readFailed
                ? null : () => _edit(context, ref),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Save the room as a scene'),
          ),
          if (data.error != null) ...[
            const SizedBox(height: 10),
            Text(data.error!, style: const TextStyle(color: Color(0xFFFFAFAF))),
          ],
          if (data.loading) const Padding(
            padding: EdgeInsets.all(22),
            child: Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 28),
          const Text('SOMEWHERE TO BEGIN',
              style: TextStyle(color: AuvorynColors.champagne,
                  fontSize: 10, letterSpacing: 1.7)),
          const SizedBox(height: 10),
          for (final scene in ListeningScene.starters)
            _SceneTile(
              key: Key('scene_${scene.id}'),
              scene: scene,
              busy: busy,
              playlistName: null,
              onApply: () async {
                final ok = await ref.read(listeningScenesProvider.notifier)
                    .apply(scene);
                if (!context.mounted) return;
                _message(context,
                    ok ? '${scene.name} is ready. Music stays as it was.' :
                    'Unable to update room settings.');
              },
              onDuplicate: busy || data.readFailed ? null : () async {
                final ok = await ref.read(listeningScenesProvider.notifier)
                    .duplicate(scene);
                if (!context.mounted) return;
                _message(context, ok ? 'Saved a customizable copy.' :
                    'Unable to save a copy.');
              },
            ),
          const SizedBox(height: 27),
          const Text('YOUR SAVED SCENES',
              style: TextStyle(color: AuvorynColors.champagne,
                  fontSize: 10, letterSpacing: 1.7)),
          const SizedBox(height: 10),
          if (!data.loading && data.saved.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 17),
              child: Text('Nothing saved yet. Set your room just how you like '
                  'it, then save the moment.',
                  style: TextStyle(color: AuvorynColors.mist, height: 1.5)),
            ),
          for (final scene in data.saved)
            _SceneTile(
              key: Key('scene_${scene.id}'),
              scene: scene,
              busy: busy,
              playlistName: scene.playlistId == null
                  ? null
                  : palettes[scene.playlistId]?.name ?? 'Missing playlist',
              onApply: () async {
                final ok = await ref.read(listeningScenesProvider.notifier)
                    .apply(scene);
                if (!context.mounted) return;
                _message(context, ok ? '${scene.name} applied. Music unchanged.' :
                    'Unable to update room settings.');
              },
              onEdit: busy ? null : () => _edit(context, ref, scene: scene),
              onReplace: busy ? null : () async {
                final ok = await ref.read(listeningScenesProvider.notifier)
                    .updateFromRoom(scene);
                if (!context.mounted) return;
                _message(context, ok ? 'Saved the current room to this scene.' :
                    'Unable to update scene.');
              },
              onDuplicate: busy ? null : () async {
                final ok = await ref.read(listeningScenesProvider.notifier)
                    .duplicate(scene);
                if (!context.mounted) return;
                _message(context, ok ? 'Scene duplicated.' :
                    'Unable to duplicate scene.');
              },
              onDelete: busy ? null : () => _delete(context, ref, scene),
              onPlay: scene.playlistId != null &&
                      palettes.containsKey(scene.playlistId)
                  ? () async {
                      final playlist = palettes[scene.playlistId]!;
                      final songById = {for (final s in music.songs) s.id: s};
                      final songs = <Song>[
                        for (final id in playlist.songIds)
                          if (songById.containsKey(id)) songById[id]!,
                      ];
                      if (songs.isEmpty) {
                        _message(context, 'This playlist has no available songs.');
                        return;
                      }
                      // Explicit user action: only this control replaces the
                      // active queue or initiates music playback.
                      await ref.read(musicProvider.notifier).playSongs(songs);
                      if (context.mounted &&
                          ref.read(musicProvider).currentSong != null) {
                        Navigator.pop(context);
                        context.push('/now-playing');
                      }
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}

class _SceneTile extends StatelessWidget {
  const _SceneTile({
    required this.scene,
    required this.busy,
    required this.onApply,
    this.playlistName,
    this.onEdit,
    this.onReplace,
    this.onDuplicate,
    this.onDelete,
    this.onPlay,
    super.key,
  });

  final ListeningScene scene;
  final bool busy;
  final String? playlistName;
  final VoidCallback onApply;
  final VoidCallback? onEdit;
  final VoidCallback? onReplace;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(
      color: AuvorynColors.raised,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.auto_awesome_outlined,
                color: AuvorynColors.champagne, size: 23),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scene.name, maxLines: 2,
                    style: const TextStyle(fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text('${scene.room.mood.title} · ${scene.room.windowView.title}',
                    style: const TextStyle(color: AuvorynColors.mist,
                        fontSize: 12)),
              ],
            )),
            TextButton(
              onPressed: busy ? null : onApply,
              child: const Text('Apply'),
            ),
            if (onEdit != null || onDelete != null || onReplace != null)
              PopupMenuButton<String>(
                tooltip: 'Scene options for ${scene.name}',
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'replace') onReplace?.call();
                  if (value == 'duplicate') onDuplicate?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit name & playlist')),
                  PopupMenuItem(value: 'replace',
                      child: Text('Update from current room')),
                  PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
          ]),
          if (playlistName != null || onPlay != null || scene.starter) ...[
            const SizedBox(height: 5),
            Row(children: [
              if (playlistName != null)
                Expanded(child: Text('Playlist · $playlistName',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AuvorynColors.mist,
                      fontSize: 11))),
              if (onPlay != null)
                TextButton.icon(
                  key: Key('scene_play_${scene.id}'),
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow_rounded, size: 17),
                  label: const Text('Play playlist'),
                ),
              if (scene.starter && onDuplicate != null)
                TextButton(
                  onPressed: onDuplicate,
                  child: const Text('Save a copy'),
                ),
            ]),
          ],
        ]),
      ),
    ),
  );
}

class SceneFormResult {
  const SceneFormResult(this.name, this.playlistId);
  final String name;
  final String? playlistId;
}

class _SceneForm extends StatefulWidget {
  const _SceneForm({this.scene, required this.playlists});
  final ListeningScene? scene;
  final List<MusicPlaylist> playlists;
  @override
  State<_SceneForm> createState() => _SceneFormState();
}

class _SceneFormState extends State<_SceneForm> {
  late final TextEditingController _name;
  late String _playlistId;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.scene?.name ?? '');
    _playlistId = widget.scene?.playlistId ?? '';
    if (_playlistId.isNotEmpty &&
        !widget.playlists.any((p) => p.id == _playlistId)) {
      _playlistId = '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.scene == null ? 'Save a scene' : 'Edit scene'),
      content: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('scene_name_input'),
            autofocus: true,
            maxLength: 60,
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Scene name'),
          ),
          const SizedBox(height: 13),
          DropdownButtonFormField<String>(
            key: const Key('scene_playlist_picker'),
            initialValue: _playlistId,
            decoration: const InputDecoration(labelText: 'Linked playlist'),
            isExpanded: true,
            items: [
              const DropdownMenuItem(
                value: '', child: Text('No playlist'),
              ),
              for (final playlist in widget.playlists)
                DropdownMenuItem(
                  value: playlist.id,
                  child: Text(playlist.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) => _playlistId = value ?? '',
          ),
          const SizedBox(height: 10),
          const Text('A linked playlist only plays when you explicitly tap '
              'Play playlist. Your current queue remains untouched when '
              'applying the scene.',
              style: TextStyle(fontSize: 12, color: AuvorynColors.mist)),
        ],
      )),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('scene_save'),
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, SceneFormResult(
              name, _playlistId.isEmpty ? null : _playlistId));
          },
          child: const Text('Save scene'),
        ),
      ],
    );
  }
}
