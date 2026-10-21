import 'dart:io';

import 'package:auvoryn/features/music/data/local_music_store.dart';
import 'package:auvoryn/features/music/domain/song.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SelectedAudio implements PlatformFile {
  SelectedAudio(this.path, this.name);
  @override
  final String path;
  @override
  final String name;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory directory;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('auvoryn-db-');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  for (final version in [1, 2]) {
    test(
      'v$version upgrade preserves tracks, favorites, playlists and saved queue',
      () async {
        final path = '${directory.path}/auvoryn_music.db';
        final db = await openDatabase(
          path,
          version: version,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE tracks (id TEXT PRIMARY KEY, title TEXT NOT NULL, '
              'artist TEXT NOT NULL, album TEXT NOT NULL, filename TEXT NOT NULL, path TEXT NOT NULL, '
              'sha256 TEXT NOT NULL UNIQUE, imported_at INTEGER NOT NULL, favorite INTEGER NOT NULL DEFAULT 0'
              '${version == 2 ? ', artwork_path TEXT' : ''})',
            );
            await db.execute(
              'CREATE TABLE playlists (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
            );
            await db.execute(
              'CREATE TABLE playlist_tracks (playlist_id TEXT NOT NULL REFERENCES playlists(id) ON DELETE CASCADE, '
              'song_id TEXT NOT NULL REFERENCES tracks(id) ON DELETE CASCADE, position INTEGER NOT NULL, '
              'PRIMARY KEY (playlist_id, song_id))',
            );
            await db.execute(
              'CREATE TABLE app_state (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
            );
          },
        );
        await db.insert('tracks', {
          'id': 'old',
          'title': 'Original',
          'artist': 'Artist',
          'album': 'Album',
          'filename': 'old.mp3',
          'path': '/original/private/old.mp3',
          'sha256': 'old',
          'imported_at': 100,
          'favorite': 1,
        });
        await db.insert('playlists', {'id': 'p', 'name': 'Preserve me'});
        await db.insert('playlist_tracks', {
          'playlist_id': 'p',
          'song_id': 'old',
          'position': 0,
        });
        await db.insert('app_state', {
          'key': 'last_queue',
          'value': '{"ids":["old"],"index":0,"positionMs":1200}',
        });
        await db.close();
        final store = await LocalMusicStore.open(supportDirectory: directory);
        final data = await store.load();
        expect(data.songs.single.isFavorite, true);
        expect(data.songs.single.path, '/original/private/old.mp3');
        expect(data.playlists.single.songIds, ['old']);
        expect(data.queue.positionMs, 1200);
        await store.recordListening('old', 10000, qualifiedPlay: true);
        expect((await store.loadListeningSnapshot()).totalPlays, 1);
        await store.clearListeningHistory();
        expect((await store.load()).songs.single.isFavorite, true);
        expect((await store.load()).playlists.single.songIds, ['old']);
        await store.dispose();
      },
    );
  }

  test(
    'imports persist private bytes, deduplicate and reject empty files',
    () async {
      final store = await LocalMusicStore.open(supportDirectory: directory);
      final source = File('${directory.path}/source.wav');
      // Tiny valid PCM wave file: metadata is optional and audio decoding is a device check.
      final bytes = <int>[
        82,
        73,
        70,
        70,
        38,
        0,
        0,
        0,
        87,
        65,
        86,
        69,
        102,
        109,
        116,
        32,
        16,
        0,
        0,
        0,
        1,
        0,
        1,
        0,
        64,
        31,
        0,
        0,
        128,
        62,
        0,
        0,
        2,
        0,
        16,
        0,
        100,
        97,
        116,
        97,
        2,
        0,
        0,
        0,
        0,
        0,
      ];
      await source.writeAsBytes(bytes);
      final file = SelectedAudio(source.path, 'Rain.wav');
      final imported = await store.importFile(file);
      expect(imported, isNotNull);
      expect(await store.importFile(file), isNull);
      await source.delete();
      expect(await File(imported!.path).readAsBytes(), bytes);
      await store.saveQueue(
        SavedQueue(songIds: [imported.id], positionMs: 123),
      );
      await store.dispose();
      final reopened = await LocalMusicStore.open(supportDirectory: directory);
      expect((await reopened.load()).queue.positionMs, 123);
      await source.writeAsBytes([]);
      await expectLater(
        reopened.importFile(file),
        throwsA(isA<FileSystemException>()),
      );
      await reopened.dispose();
    },
  );
}
