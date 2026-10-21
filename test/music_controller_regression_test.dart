import 'dart:async';
import 'dart:io';

import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:auvoryn/features/music/data/local_music_store.dart';
import 'package:auvoryn/features/music/domain/song.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

class MemoryStore implements LocalMusicStore {
  final favorites = <bool>[];
  final playlistWrites = <List<String>>[];
  Completer<List<Song>>? metadata;
  bool failWrite = false;
  @override
  Future<void> setFavorite(String id, bool value) async {
    await Future<void>.delayed(Duration.zero);
    if (failWrite) throw StateError('Disk full');
    favorites.add(value);
  }

  @override
  Future<void> updatePlaylistTracks(String id, List<String> ids) async {
    await Future<void>.delayed(Duration.zero);
    playlistWrites.add(List.of(ids));
  }

  @override
  Future<List<Song>> refreshMetadata(List<Song> songs) => metadata!.future;
  @override
  Future<void> saveQueue(SavedQueue state) async {}
  @override
  Future<void> recordListening(
    String songId,
    int ms, {
    bool qualifiedPlay = false,
  }) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAudio implements AudioPlayer {
  final events = StreamController<PlayerState>.broadcast(sync: true);
  int loads = 0, activeLoads = 0, maximumLoads = 0, plays = 0;
  bool closed = false;
  @override
  bool playing = false;
  @override
  ProcessingState processingState = ProcessingState.ready;
  @override
  Duration position = Duration.zero;
  @override
  Duration? get duration => const Duration(minutes: 3);
  @override
  int? currentIndex = 0;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Stream<PlayerException> get errorStream => const Stream.empty();
  @override
  Stream<PlayerState> get playerStateStream => events.stream;
  @override
  Future<void> setVolume(double value) async {}
  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> sources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    activeLoads++;
    if (activeLoads > maximumLoads) maximumLoads = activeLoads;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    loads++;
    currentIndex = initialIndex ?? 0;
    position = initialPosition ?? Duration.zero;
    activeLoads--;
    return duration;
  }

  @override
  Future<void> pause() async {
    playing = false;
    emit();
  }

  @override
  Future<void> play() async {
    plays++;
    playing = true;
    emit();
  }

  void emit() => events.add(PlayerState(playing, processingState));
  @override
  Future<void> seek(Duration? position, {int? index}) async {
    this.position = position ?? Duration.zero;
    currentIndex = index ?? currentIndex;
    processingState = ProcessingState.ready;
  }

  @override
  Future<void> dispose() async {
    closed = true;
    await events.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory directory;
  late Song first, second;
  late MemoryStore store;
  late ProviderContainer container;
  late FakeAudio audio;
  var creations = 0;
  const playlist = MusicPlaylist(id: 'p', name: 'Night');
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('auvoryn-controller-');
    Song song(String id) => Song(
      id: id,
      title: id,
      path: '${directory.path}/$id.mp3',
      fileName: '$id.mp3',
      sha256: id,
      importedAt: DateTime(2026),
    );
    first = song('a');
    second = song('b');
    await File(first.path).writeAsBytes([1]);
    await File(second.path).writeAsBytes([2]);
    store = MemoryStore();
    audio = FakeAudio();
    creations = 0;
    container = ProviderContainer(
      overrides: [
        musicStoreProvider.overrideWithValue(store),
        initialMusicProvider.overrideWithValue(
          MusicBootstrap(
            songs: [first, second],
            playlists: [playlist],
            queue: const SavedQueue(),
          ),
        ),
        musicAudioFactoryProvider.overrideWithValue(() async {
          creations++;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return audio;
        }),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await directory.delete(recursive: true);
  });

  test(
    'rapid playlist selections preserve both additions from stale UI snapshots',
    () async {
      final controller = container.read(musicProvider.notifier);
      await Future.wait([
        controller.toggleSongInPlaylist(playlist, first),
        controller.toggleSongInPlaylist(playlist, second),
      ]);
      expect(container.read(musicProvider).playlists.single.songIds, [
        'a',
        'b',
      ]);
      expect(store.playlistWrites.last, ['a', 'b']);
    },
  );

  test('two quick favorite toggles use latest state and a failed write stays recoverable', () async {
    final controller = container.read(musicProvider.notifier);
    await Future.wait([
      controller.toggleFavorite(first),
      controller.toggleFavorite(first),
    ]);
    expect(store.favorites, [true, false]);
    store.failWrite = true;
    await controller.toggleFavorite(first);
    expect(container.read(musicProvider).songs.first.isFavorite, false);
    expect(container.read(musicProvider).error, contains('Unable to save'));
    store.failWrite = false;
    await controller.toggleFavorite(first);
    expect(container.read(musicProvider).songs.first.isFavorite, true);
  });

  test(
    'metadata refresh preserves a favorite changed while decoding tags',
    () async {
      store.metadata = Completer<List<Song>>();
      final controller = container.read(musicProvider.notifier);
      final refresh = controller.refreshMetadata();
      await Future<void>.delayed(Duration.zero);
      await controller.toggleFavorite(first);
      store.metadata!.complete([first.copyWith(title: 'Updated'), second]);
      expect(await refresh, 1);
      expect(container.read(musicProvider).songs.first.title, 'Updated');
      expect(container.read(musicProvider).songs.first.isFavorite, true);
    },
  );

  test(
    'rapid play requests use one audio engine and never overlap source loads',
    () async {
      final controller = container.read(musicProvider.notifier);
      await Future.wait([
        controller.playSongs([first]),
        controller.playSongs([second]),
      ]);
      expect(creations, 1);
      expect(audio.maximumLoads, 1);
      expect(audio.loads, 2);
      expect(container.read(musicProvider).currentSong?.id, 'b');
    },
  );

  test('completed playback shows play and restarts on the first tap', () async {
    final controller = container.read(musicProvider.notifier);
    await controller.playSongs([first]);
    audio.processingState = ProcessingState.completed;
    audio.emit();
    expect(container.read(musicProvider).playing, false);
    await controller.togglePlay();
    expect(audio.plays, 2);
    expect(container.read(musicProvider).playing, true);
  });

  test(
    'disposing during audio initialization disposes the late native player',
    () async {
      final ready = Completer<AudioPlayer>();
      final pendingContainer = ProviderContainer(
        overrides: [
          musicStoreProvider.overrideWithValue(store),
          musicAudioFactoryProvider.overrideWithValue(() => ready.future),
        ],
      );
      final operation = pendingContainer
          .read(musicProvider.notifier)
          .toggleShuffle();
      await Future<void>.delayed(Duration.zero);
      pendingContainer.dispose();
      final lateAudio = FakeAudio();
      ready.complete(lateAudio);
      await operation;
      expect(lateAudio.closed, true);
    },
  );
}
