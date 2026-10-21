import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:auvoryn/features/music/data/local_music_store.dart';
import 'package:auvoryn/features/music/domain/song.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final musicStoreProvider = Provider<LocalMusicStore>((ref) =>
    throw StateError('Music store must be provided at app startup.'));
final initialMusicProvider = Provider<MusicBootstrap>((ref) =>
    const MusicBootstrap(songs: [], playlists: [], queue: SavedQueue()));

final musicProvider = NotifierProvider<MusicController, MusicState>(MusicController.new);

class MusicState {
  const MusicState({
    this.songs = const [],
    this.playlists = const [],
    this.queueIds = const [],
    this.currentIndex = 0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.loading = false,
    this.restoring = false,
    this.shuffle = false,
    this.repeat = LoopMode.off,
    this.error,
  });

  final List<Song> songs;
  final List<MusicPlaylist> playlists;
  final List<String> queueIds;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final bool playing;
  final bool loading;
  final bool restoring;
  final bool shuffle;
  final LoopMode repeat;
  final String? error;

  Song? get currentSong {
    if (queueIds.isEmpty || currentIndex < 0 || currentIndex >= queueIds.length) {
      return null;
    }
    for (final s in songs) {
      if (s.id == queueIds[currentIndex]) return s;
    }
    return null;
  }

  MusicState copyWith({
    List<Song>? songs, List<MusicPlaylist>? playlists, List<String>? queueIds,
    int? currentIndex, Duration? position, Duration? duration,
    bool? playing, bool? loading, bool? restoring,
    bool? shuffle, LoopMode? repeat, String? error, bool clearError = false,
  }) => MusicState(
    songs: songs ?? this.songs,
    playlists: playlists ?? this.playlists,
    queueIds: queueIds ?? this.queueIds,
    currentIndex: currentIndex ?? this.currentIndex,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    restoring: restoring ?? this.restoring,
    shuffle: shuffle ?? this.shuffle,
    repeat: repeat ?? this.repeat,
    error: clearError ? null : error ?? this.error,
  );
}

class MusicController extends Notifier<MusicState> {
  AudioPlayer? _player;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _disposed = false;
  Future<void> _saveWrites = Future<void>.value();
  Future<void> _restoration = Future<void>.value();
  DateTime _lastPositionSave = DateTime.fromMillisecondsSinceEpoch(0);

  LocalMusicStore get _store => ref.read(musicStoreProvider);

  @override
  MusicState build() {
    final initial = ref.read(initialMusicProvider);
    ref.onDispose(() {
      _disposed = true;
      for (final subscription in _subscriptions) {
        unawaited(subscription.cancel());
      }
      if (_player != null) unawaited(_player!.dispose());
    });
    // Defer restoration until after build returns a fully initialized state.
    _restoration = Future<void>.microtask(() => _restore(initial.queue));
    return MusicState(
      songs: initial.songs, playlists: initial.playlists,
      restoring: initial.queue.songIds.isNotEmpty,
    );
  }

  Future<AudioPlayer> _audio() async {
    if (_player != null) return _player!;
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
    final player = AudioPlayer(maxSkipsOnError: 2);
    _player = player;
    _subscriptions.add(player.positionStream.listen((position) {
      if (_disposed) return;
      state = state.copyWith(position: position);
      if (state.queueIds.isNotEmpty &&
          DateTime.now().difference(_lastPositionSave).inSeconds >= 8) {
        _lastPositionSave = DateTime.now();
        _persistQueue();
      }
    }));
    _subscriptions.add(player.durationStream.listen((duration) {
      if (!_disposed) state = state.copyWith(duration: duration ?? Duration.zero);
    }));
    _subscriptions.add(player.playerStateStream.listen((event) {
      if (!_disposed) state = state.copyWith(playing: event.playing);
    }));
    _subscriptions.add(player.currentIndexStream.listen((index) {
      if (_disposed || index == null || state.queueIds.isEmpty) return;
      state = state.copyWith(currentIndex: index);
      _persistQueue();
    }));
    _subscriptions.add(player.errorStream.listen((error) {
      if (!_disposed) state = state.copyWith(error: 'Playback error: ${error.message}');
    }));
    return player;
  }

  Future<void> _restore(SavedQueue saved) async {
    if (saved.songIds.isEmpty || _disposed) return;
    try {
      final indexed = {for (final song in state.songs) song.id: song};
      final valid = <Song>[];
      for (final id in saved.songIds) {
        final song = indexed[id];
        if (song != null && await File(song.path).exists()) valid.add(song);
      }
      if (_disposed || valid.isEmpty) return;
      final selectedId = saved.index >= 0 && saved.index < saved.songIds.length
          ? saved.songIds[saved.index] : null;
      final index = valid.indexWhere((s) => s.id == selectedId);
      final player = await _audio();
      if (_disposed) return;
      state = state.copyWith(
        queueIds: valid.map((s) => s.id).toList(),
        currentIndex: index < 0 ? 0 : index,
      );
      await player.setAudioSources(_sources(valid),
        initialIndex: index < 0 ? 0 : index,
        initialPosition: Duration(milliseconds: saved.positionMs.clamp(0, 86400000).toInt()),
      );
    } catch (error) {
      if (!_disposed) state = state.copyWith(error: 'Unable to restore previous queue: $error');
    } finally {
      if (!_disposed) state = state.copyWith(restoring: false);
    }
  }

  List<AudioSource> _sources(List<Song> songs) => [
    for (final song in songs)
      AudioSource.uri(Uri.file(song.path), tag: MediaItem(
        id: song.id, title: song.title, artist: song.artist, album: song.album,
      )),
  ];

  void _persistQueue() {
    if (_disposed) return;
    final snapshot = SavedQueue(
      songIds: List.of(state.queueIds), index: state.currentIndex,
      positionMs: state.position.inMilliseconds,
    );
    _saveWrites = _saveWrites.catchError((Object _) {}).then((_) => _store.saveQueue(snapshot))
      .catchError((Object error) {
        if (!_disposed) state = state.copyWith(error: 'Unable to save playback queue: $error');
      });
  }

  Future<int> importMusic() async {
    await _restoration;
    state = state.copyWith(loading: true, clearError: true);
    var count = 0;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: LocalMusicStore.supportedExtensions.toList(),
        allowMultiple: true,
      );
      if (result == null) return 0;
      final failures = <String>[];
      final next = List<Song>.from(state.songs);
      for (final file in result.files) {
        try {
          final song = await _store.importFile(file);
          if (song == null) continue;
          next.insert(0, song);
          count++;
        } catch (error) {
          failures.add('${file.name}: $error');
        }
      }
      state = state.copyWith(songs: next,
        error: failures.isEmpty ? null : 'Some files could not be imported: ${failures.take(2).join('; ')}',
        clearError: failures.isEmpty);
    } catch (error) {
      state = state.copyWith(error: 'Unable to open the music picker: $error');
    } finally {
      state = state.copyWith(loading: false);
    }
    return count;
  }

  Future<void> playSongs(List<Song> selected, {int startIndex = 0}) async {
    await _restoration;
    if (selected.isEmpty) return;
    final songs = <Song>[];
    for (final song in selected) {
      if (await File(song.path).exists()) songs.add(song);
    }
    if (songs.isEmpty) {
      state = state.copyWith(error: 'These music files are missing. Try importing them again.');
      return;
    }
    final initialId = startIndex >= 0 && startIndex < selected.length
        ? selected[startIndex].id : selected.first.id;
    final index = songs.indexWhere((s) => s.id == initialId);
    final current = index < 0 ? 0 : index;
    state = state.copyWith(
      queueIds: songs.map((s) => s.id).toList(), currentIndex: current,
      position: Duration.zero, duration: Duration.zero, clearError: true,
    );
    _persistQueue();
    try {
      final player = await _audio();
      await player.setAudioSources(_sources(songs), initialIndex: current);
      // Do not await play(): its Future completes when playback ends.
      unawaited(player.play().catchError((Object error) {
        if (!_disposed) state = state.copyWith(error: 'Unable to play: $error');
      }));
    } catch (error) {
      state = state.copyWith(error: 'Unable to load audio: $error', playing: false);
    }
  }

  Future<void> togglePlay() async {
    await _restoration;
    if (state.queueIds.isEmpty) return;
    try {
      final player = await _audio();
      if (player.playing) {
        await player.pause();
        _persistQueue();
      } else {
        if (player.processingState == ProcessingState.completed) {
          await player.seek(Duration.zero, index: state.currentIndex);
        }
        unawaited(player.play().catchError((Object error) {
          if (!_disposed) state = state.copyWith(error: 'Unable to play: $error');
        }));
      }
    } catch (error) {
      state = state.copyWith(error: 'Playback failed: $error');
    }
  }

  Future<void> next() async {
    final player = _player;
    if (player == null) return;
    if (player.hasNext) await player.seekToNext();
  }

  Future<void> previous() async {
    final player = _player;
    if (player == null) return;
    if (state.position.inSeconds > 3) {
      await player.seek(Duration.zero);
    } else if (player.hasPrevious) {
      await player.seekToPrevious();
    } else {
      await player.seek(Duration.zero);
    }
  }

  Future<void> seek(Duration position) async {
    final player = _player;
    if (player == null) return;
    final duration = state.duration;
    final ms = position.inMilliseconds.clamp(0, duration.inMilliseconds);
    await player.seek(Duration(milliseconds: ms.toInt()));
    _persistQueue();
  }

  Future<void> jumpTo(int index) async {
    final player = _player;
    if (player == null || index < 0 || index >= state.queueIds.length) return;
    await player.seek(Duration.zero, index: index);
    _persistQueue();
  }

  Future<void> toggleShuffle() async {
    final player = await _audio();
    final shuffle = !state.shuffle;
    if (shuffle) await player.shuffle();
    await player.setShuffleModeEnabled(shuffle);
    state = state.copyWith(shuffle: shuffle);
  }

  Future<void> cycleRepeat() async {
    final player = await _audio();
    final next = switch (state.repeat) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await player.setLoopMode(next);
    state = state.copyWith(repeat: next);
  }

  Future<void> toggleFavorite(Song song) async {
    final updated = !song.isFavorite;
    await _store.setFavorite(song.id, updated);
    state = state.copyWith(songs: [
      for (final item in state.songs)
        if (item.id == song.id) item.copyWith(isFavorite: updated) else item,
    ]);
  }

  Future<MusicPlaylist> createPlaylist(String name) async {
    if (name.trim().isEmpty) throw const FormatException('Enter a playlist name.');
    final playlist = await _store.createPlaylist(name);
    state = state.copyWith(playlists: [...state.playlists, playlist]);
    return playlist;
  }

  Future<void> renamePlaylist(MusicPlaylist playlist, String name) async {
    if (name.trim().isEmpty) throw const FormatException('Enter a playlist name.');
    await _store.renamePlaylist(playlist.id, name);
    state = state.copyWith(playlists: [
      for (final item in state.playlists)
        if (item.id == playlist.id) item.copyWith(name: name.trim()) else item,
    ]);
  }

  Future<void> deletePlaylist(MusicPlaylist playlist) async {
    await _store.deletePlaylist(playlist.id);
    state = state.copyWith(playlists: [
      for (final item in state.playlists) if (item.id != playlist.id) item,
    ]);
  }

  Future<void> toggleSongInPlaylist(MusicPlaylist playlist, Song song) async {
    final ids = List<String>.from(playlist.songIds);
    ids.contains(song.id) ? ids.remove(song.id) : ids.add(song.id);
    await _store.updatePlaylistTracks(playlist.id, ids);
    state = state.copyWith(playlists: [
      for (final item in state.playlists)
        if (item.id == playlist.id) item.copyWith(songIds: ids) else item,
    ]);
  }
}
