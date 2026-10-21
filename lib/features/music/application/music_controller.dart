import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/features/music/data/local_music_store.dart';
import 'package:auvoryn/features/memories/domain/listening_snapshot.dart';
import 'package:auvoryn/features/memories/domain/listening_tracker.dart';
import 'package:auvoryn/features/music/domain/song.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final musicStoreProvider = Provider<LocalMusicStore>(
  (ref) => throw StateError('Music store must be provided at app startup.'),
);
final initialMusicProvider = Provider<MusicBootstrap>(
  (ref) => const MusicBootstrap(songs: [], playlists: [], queue: SavedQueue()),
);

// Injectable at the native boundary for deterministic race-condition tests.
final musicAudioFactoryProvider = Provider<Future<AudioPlayer> Function()>(
  (ref) => () async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
    return AudioPlayer(maxSkipsOnError: 2);
  },
);

final musicProvider = NotifierProvider<MusicController, MusicState>(
  MusicController.new,
);
final listeningSnapshotProvider = FutureProvider<ListeningSnapshot>(
  (ref) => ref.read(musicStoreProvider).loadListeningSnapshot(),
);

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
    if (queueIds.isEmpty ||
        currentIndex < 0 ||
        currentIndex >= queueIds.length) {
      return null;
    }
    for (final s in songs) {
      if (s.id == queueIds[currentIndex]) {
        return s;
      }
    }
    return null;
  }

  MusicState copyWith({
    List<Song>? songs,
    List<MusicPlaylist>? playlists,
    List<String>? queueIds,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    bool? playing,
    bool? loading,
    bool? restoring,
    bool? shuffle,
    LoopMode? repeat,
    String? error,
    bool clearError = false,
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
  Future<AudioPlayer>? _audioInitialization;
  Future<void> _transportWrites = Future<void>.value();
  Future<void> _libraryWrites = Future<void>.value();
  bool _changingQueue = false;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _disposed = false;
  Future<void> _saveWrites = Future<void>.value();
  Future<void> _restoration = Future<void>.value();
  DateTime _lastPositionSave = DateTime.fromMillisecondsSinceEpoch(0);
  late final ListeningTracker _listening = ListeningTracker(_recordListening);
  Future<void> _listeningWrites = Future<void>.value();

  LocalMusicStore? _cachedStore;
  LocalMusicStore get _store {
    final cached = _cachedStore;
    if (cached != null) return cached;
    final store = ref.read(musicStoreProvider);
    _cachedStore = store;
    return store;
  }

  @override
  MusicState build() {
    // The app's one background-enabled music engine owns notification controls.
    // Atmospheric sound uses a separate backend without audio focus requests.
    ref.listen<RoomSettings>(roomSettingsProvider, (previous, next) {
      if (previous?.musicVolume != next.musicVolume && _player != null) {
        unawaited(
          _player!.setVolume(next.musicVolume).catchError((Object error) {
            if (!_disposed) {
              state = state.copyWith(error: 'Unable to change volume: $error');
            }
          }),
        );
      }
    });
    final initial = ref.read(initialMusicProvider);
    ref.onDispose(() {
      _listening.flush();
      _disposed = true;
      for (final subscription in _subscriptions) {
        unawaited(subscription.cancel());
      }
      if (_player != null) {
        unawaited(_player!.dispose());
      }
    });
    // Defer restoration until after build returns a fully initialized state.
    _restoration = Future<void>.microtask(() => _restore(initial.queue));
    return MusicState(
      songs: initial.songs,
      playlists: initial.playlists,
      restoring: initial.queue.songIds.isNotEmpty,
    );
  }

  Future<AudioPlayer> _audio() => _audioInitialization ??= _createAudio();

  Future<AudioPlayer> _createAudio() async {
    AudioPlayer? created;
    try {
      final player = await ref.read(musicAudioFactoryProvider)();
      created = player;
      if (_disposed) {
        throw StateError('Music controller is closed.');
      }
      await player.setVolume(ref.read(roomSettingsProvider).musicVolume);
      if (_disposed) {
        throw StateError('Music controller is closed.');
      }
      _player = player;
      _subscriptions.add(
        player.positionStream.listen((position) {
          if (_disposed || _changingQueue) {
            return;
          }
          _sampleListening(player, position);
          state = state.copyWith(position: position);
          if (state.queueIds.isNotEmpty &&
              DateTime.now().difference(_lastPositionSave).inSeconds >= 8) {
            _lastPositionSave = DateTime.now();
            _persistQueue();
          }
        }),
      );
      _subscriptions.add(
        player.durationStream.listen((duration) {
          if (!_disposed && !_changingQueue) {
            state = state.copyWith(duration: duration ?? Duration.zero);
          }
        }),
      );
      _subscriptions.add(
        player.playerStateStream.listen((event) {
          if (_disposed || _changingQueue) {
            return;
          }
          _sampleListening(player, player.position);
          state = state.copyWith(
            playing:
                event.playing &&
                event.processingState != ProcessingState.completed,
          );
          if (event.playing &&
              event.processingState == ProcessingState.completed) {
            // Also update the native media session after its completion event.
            unawaited(
              _transport(() async {
                if (player.playing &&
                    player.processingState == ProcessingState.completed) {
                  await player.pause();
                }
              }),
            );
          }
        }),
      );
      _subscriptions.add(
        player.currentIndexStream.listen((index) {
          if (_disposed ||
              _changingQueue ||
              index == null ||
              index >= state.queueIds.length) {
            return;
          }
          state = state.copyWith(
            currentIndex: index,
            position: player.position,
          );
          _persistQueue();
        }),
      );
      _subscriptions.add(
        player.errorStream.listen((error) {
          if (!_disposed) {
            state = state.copyWith(error: 'Playback error: ${error.message}');
          }
        }),
      );
      return player;
    } catch (_) {
      _audioInitialization = null;
      _player = null;
      if (created != null) {
        await created.dispose();
      }
      rethrow;
    }
  }

  // Do not await play() here: just_audio completes it when playback ends.
  // Serialize load/seek/mode commands, but leave music running independently.
  Future<void> _transport(Future<void> Function() action) {
    final next = _transportWrites
        .then((_) async {
          await _restoration;
          if (!_disposed) {
            await action();
          }
        })
        .catchError((Object error) {
          if (!_disposed) {
            state = state.copyWith(error: 'Playback failed: $error');
          }
        });
    _transportWrites = next;
    return next;
  }

  Future<T> _libraryEdit<T>(Future<T> Function() action) {
    final next = _libraryWrites.then((_) {
      if (_disposed) {
        throw StateError('Music controller is closed.');
      }
      return action();
    });
    _libraryWrites = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }

  Future<void> _safeLibraryEdit(Future<void> Function() action) =>
      _libraryEdit(action).catchError((Object error) {
        if (!_disposed) {
          state = state.copyWith(
            error: 'Unable to save library change: $error',
          );
        }
      });

  void _sampleListening(AudioPlayer player, Duration position) {
    final index = player.currentIndex;
    final ids = state.queueIds;
    final songId = index != null && index >= 0 && index < ids.length
        ? ids[index]
        : null;
    _listening.sample(
      songId: songId,
      positionMs: position.inMilliseconds,
      nowMs: DateTime.now().millisecondsSinceEpoch,
      playing: player.playing,
      ready: player.processingState == ProcessingState.ready,
    );
  }

  void _recordListening(ListeningCheckpoint checkpoint) {
    final store = _store;
    _listeningWrites = _listeningWrites
        .catchError((Object _) {})
        .then(
          (_) => store.recordListening(
            checkpoint.songId,
            checkpoint.listenedMs,
            qualifiedPlay: checkpoint.qualifiedPlay,
          ),
        );
    unawaited(
      _listeningWrites
          .then((_) {
            if (!_disposed) {
              ref.invalidate(listeningSnapshotProvider);
            }
          })
          .catchError((Object error) {
            if (!_disposed) {
              state = state.copyWith(error: 'History save failed: $error');
            }
          }),
    );
  }

  Future<void> clearListeningHistory() async {
    _listening.reset();
    final store = _store;
    // New playback checkpoints must be queued after the clear operation.
    final clearing = _listeningWrites
        .catchError((Object _) {})
        .then((_) => store.clearListeningHistory());
    _listeningWrites = clearing;
    await clearing;
    if (!_disposed) {
      ref.invalidate(listeningSnapshotProvider);
    }
  }

  Future<void> _restore(SavedQueue saved) async {
    if (saved.songIds.isEmpty || _disposed) {
      return;
    }
    try {
      final indexed = {for (final song in state.songs) song.id: song};
      final valid = <Song>[];
      for (final id in saved.songIds) {
        final song = indexed[id];
        if (song != null && await File(song.path).exists()) {
          valid.add(song);
        }
      }
      if (_disposed || valid.isEmpty) {
        return;
      }
      final selectedId = saved.index >= 0 && saved.index < saved.songIds.length
          ? saved.songIds[saved.index]
          : null;
      final index = valid.indexWhere((s) => s.id == selectedId);
      final player = await _audio();
      if (_disposed) {
        return;
      }
      state = state.copyWith(
        queueIds: valid.map((s) => s.id).toList(),
        currentIndex: index < 0 ? 0 : index,
      );
      _changingQueue = true;
      await player.setAudioSources(
        _sources(valid),
        initialIndex: index < 0 ? 0 : index,
        initialPosition: Duration(
          milliseconds: index < 0
              ? 0
              : saved.positionMs.clamp(0, 86400000).toInt(),
        ),
      );
    } catch (error) {
      if (!_disposed) {
        state = state.copyWith(
          error: 'Unable to restore previous queue: $error',
        );
      }
    } finally {
      _changingQueue = false;
      if (!_disposed) {
        final player = _player;
        state = state.copyWith(
          restoring: false,
          position: player?.position ?? Duration.zero,
          duration: player?.duration ?? Duration.zero,
        );
      }
    }
  }

  List<AudioSource> _sources(List<Song> songs) => [
    for (final song in songs)
      AudioSource.uri(
        Uri.file(song.path),
        tag: MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          album: song.album,
          artUri: song.artworkPath == null ? null : Uri.file(song.artworkPath!),
        ),
      ),
  ];

  void _persistQueue() {
    if (_disposed) {
      return;
    }
    final snapshot = SavedQueue(
      songIds: List.of(state.queueIds),
      index: state.currentIndex,
      positionMs: state.position.inMilliseconds,
    );
    final store = _store;
    _saveWrites = _saveWrites
        .catchError((Object _) {})
        .then((_) => store.saveQueue(snapshot))
        .catchError((Object error) {
          if (!_disposed) {
            state = state.copyWith(
              error: 'Unable to save playback queue: $error',
            );
          }
        });
  }

  Future<int> importMusic() async {
    await _restoration;
    if (_disposed || state.loading) {
      return 0;
    }
    state = state.copyWith(loading: true, clearError: true);
    var count = 0;
    try {
      final selectedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: LocalMusicStore.supportedExtensions.toList(),
      );
      if (selectedFiles.isEmpty) {
        return 0;
      }
      final failures = <String>[];
      final imported = <Song>[];
      for (final file in selectedFiles) {
        try {
          final song = await _store.importFile(file);
          if (song == null) {
            continue;
          }
          imported.insert(0, song);
          count++;
        } catch (error) {
          failures.add('${file.name}: $error');
        }
      }
      if (_disposed) {
        return count;
      }
      final existingById = {for (final song in state.songs) song.id: song};
      final importedIds = imported.map((song) => song.id).toSet();
      state = state.copyWith(
        songs: [
          for (final song in imported)
            song.copyWith(
              isFavorite: existingById[song.id]?.isFavorite ?? song.isFavorite,
            ),
          for (final song in state.songs)
            if (!importedIds.contains(song.id)) song,
        ],
        error: failures.isEmpty
            ? null
            : 'Some files could not be imported: ${failures.take(2).join('; ')}',
        clearError: failures.isEmpty,
      );
    } catch (error) {
      if (!_disposed) {
        state = state.copyWith(
          error: 'Unable to open the music picker: $error',
        );
      }
    } finally {
      if (!_disposed) {
        state = state.copyWith(loading: false);
      }
    }
    return count;
  }

  /// Refresh tags on demand without blocking startup or audio playback.
  Future<int> refreshMetadata() async {
    await _restoration;
    if (_disposed || state.loading || state.songs.isEmpty) {
      return 0;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final beforeById = {for (final song in state.songs) song.id: song};
      final updated = await _store.refreshMetadata(state.songs);
      if (_disposed) {
        return 0;
      }
      final changed = updated.where((song) {
        final before = beforeById[song.id]!;
        return song.title != before.title ||
            song.artist != before.artist ||
            song.album != before.album ||
            song.artworkPath != before.artworkPath;
      }).length;
      final details = {for (final song in updated) song.id: song};
      state = state.copyWith(
        songs: [
          for (final current in state.songs)
            details[current.id]?.copyWith(isFavorite: current.isFavorite) ??
                current,
        ],
      );
      return changed;
    } catch (error) {
      if (!_disposed) {
        state = state.copyWith(error: 'Metadata refresh failed: $error');
      }
      return 0;
    } finally {
      if (!_disposed) {
        state = state.copyWith(loading: false);
      }
    }
  }

  Future<void> playSongs(List<Song> selected, {int startIndex = 0}) =>
      _transport(() async {
        if (selected.isEmpty) {
          return;
        }
        final songs = <Song>[];
        for (final song in selected) {
          if (await File(song.path).exists()) {
            songs.add(song);
          }
        }
        if (_disposed) {
          return;
        }
        if (songs.isEmpty) {
          state = state.copyWith(
            error: 'These music files are missing. Try importing them again.',
          );
          return;
        }
        final initialId = startIndex >= 0 && startIndex < selected.length
            ? selected[startIndex].id
            : selected.first.id;
        final index = songs.indexWhere((s) => s.id == initialId);
        final current = index < 0 ? 0 : index;
        final player = await _audio();
        if (_disposed) {
          return;
        }
        await player.pause();
        _listening.flush();
        _listening.reset();
        _changingQueue = true;
        state = state.copyWith(
          queueIds: songs.map((s) => s.id).toList(),
          currentIndex: current,
          position: Duration.zero,
          duration: Duration.zero,
          clearError: true,
        );
        _persistQueue();
        try {
          await player.setAudioSources(_sources(songs), initialIndex: current);
          if (_disposed) {
            return;
          }
          _changingQueue = false;
          state = state.copyWith(
            position: player.position,
            duration: player.duration ?? Duration.zero,
            currentIndex: player.currentIndex ?? current,
          );
          // Do not await play(): its Future completes when playback ends.
          unawaited(
            player.play().catchError((Object error) {
              if (!_disposed) {
                state = state.copyWith(error: 'Unable to play: $error');
              }
            }),
          );
        } catch (error) {
          if (!_disposed) {
            state = state.copyWith(
              error: 'Unable to load audio: $error',
              playing: false,
            );
          }
        } finally {
          _changingQueue = false;
        }
      });

  Future<void> togglePlay() => _transport(() async {
    if (state.queueIds.isEmpty) {
      return;
    }
    try {
      final player = await _audio();
      if (player.playing &&
          player.processingState != ProcessingState.completed) {
        await player.pause();
        _persistQueue();
      } else {
        if (player.processingState == ProcessingState.completed) {
          await player.seek(Duration.zero, index: state.currentIndex);
        }
        unawaited(
          player.play().catchError((Object error) {
            if (!_disposed) {
              state = state.copyWith(error: 'Unable to play: $error');
            }
          }),
        );
      }
    } catch (error) {
      if (!_disposed) {
        state = state.copyWith(error: 'Playback failed: $error');
      }
    }
  });

  Future<void> next() => _transport(() async {
    final player = _player;
    if (player == null) {
      return;
    }
    if (player.hasNext) {
      await player.seekToNext();
    }
    if (!_disposed) {
      state = state.copyWith(
        position: player.position,
        currentIndex: player.currentIndex ?? state.currentIndex,
      );
      _persistQueue();
    }
  });

  Future<void> previous() => _transport(() async {
    final player = _player;
    if (player == null) {
      return;
    }
    if (state.position.inSeconds > 3) {
      await player.seek(Duration.zero);
    } else if (player.hasPrevious) {
      await player.seekToPrevious();
    } else {
      await player.seek(Duration.zero);
    }
    if (!_disposed) {
      state = state.copyWith(
        position: player.position,
        currentIndex: player.currentIndex ?? state.currentIndex,
      );
      _persistQueue();
    }
  });

  Future<void> seek(Duration position) => _transport(() async {
    final player = _player;
    if (player == null) {
      return;
    }
    final duration = state.duration;
    final ms = position.inMilliseconds.clamp(0, duration.inMilliseconds);
    _listening.discontinuity();
    await player.seek(Duration(milliseconds: ms.toInt()));

    if (!_disposed) {
      state = state.copyWith(
        position: player.position,
        currentIndex: player.currentIndex ?? state.currentIndex,
      );
      _persistQueue();
    }
  });

  Future<void> jumpTo(int index) => _transport(() async {
    final player = _player;
    if (player == null || index < 0 || index >= state.queueIds.length) {
      return;
    }
    await player.seek(Duration.zero, index: index);

    if (!_disposed) {
      state = state.copyWith(
        position: player.position,
        currentIndex: player.currentIndex ?? state.currentIndex,
      );
      _persistQueue();
    }
  });

  Future<void> toggleShuffle() => _transport(() async {
    final player = await _audio();
    final shuffle = !state.shuffle;
    if (shuffle) {
      await player.shuffle();
    }
    await player.setShuffleModeEnabled(shuffle);
    if (!_disposed) {
      state = state.copyWith(shuffle: shuffle);
    }
  });

  Future<void> cycleRepeat() => _transport(() async {
    final player = await _audio();
    final next = switch (state.repeat) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await player.setLoopMode(next);
    if (!_disposed) {
      state = state.copyWith(repeat: next);
    }
  });

  Future<void> toggleFavorite(Song song) => _safeLibraryEdit(() async {
    final matching = state.songs.where((item) => item.id == song.id);
    if (matching.isEmpty) {
      return;
    }
    final updated = !matching.first.isFavorite;
    await _store.setFavorite(song.id, updated);
    if (_disposed) {
      return;
    }
    state = state.copyWith(
      songs: [
        for (final item in state.songs)
          if (item.id == song.id) item.copyWith(isFavorite: updated) else item,
      ],
    );
  });

  Future<MusicPlaylist> createPlaylist(String name) => _libraryEdit(() async {
    if (name.trim().isEmpty) {
      throw const FormatException('Enter a playlist name.');
    }
    final playlist = await _store.createPlaylist(name);
    if (!_disposed) {
      state = state.copyWith(playlists: [...state.playlists, playlist]);
    }
    return playlist;
  });

  Future<void> renamePlaylist(MusicPlaylist playlist, String name) =>
      _libraryEdit(() async {
        if (name.trim().isEmpty) {
          throw const FormatException('Enter a playlist name.');
        }
        await _store.renamePlaylist(playlist.id, name);
        if (_disposed) {
          return;
        }
        state = state.copyWith(
          playlists: [
            for (final item in state.playlists)
              if (item.id == playlist.id)
                item.copyWith(name: name.trim())
              else
                item,
          ],
        );
      });

  Future<void> deletePlaylist(MusicPlaylist playlist) => _libraryEdit(() async {
    await _store.deletePlaylist(playlist.id);
    if (_disposed) {
      return;
    }
    state = state.copyWith(
      playlists: [
        for (final item in state.playlists)
          if (item.id != playlist.id) item,
      ],
    );
  });

  Future<void> toggleSongInPlaylist(
    MusicPlaylist playlist,
    Song song,
  ) => _safeLibraryEdit(() async {
    final matching = state.playlists.where((item) => item.id == playlist.id);
    if (matching.isEmpty || !state.songs.any((item) => item.id == song.id)) {
      return;
    }
    final ids = List<String>.from(matching.first.songIds);
    ids.contains(song.id) ? ids.remove(song.id) : ids.add(song.id);
    await _store.updatePlaylistTracks(playlist.id, ids);
    if (_disposed) {
      return;
    }
    state = state.copyWith(
      playlists: [
        for (final item in state.playlists)
          if (item.id == playlist.id) item.copyWith(songIds: ids) else item,
      ],
    );
  });
}
