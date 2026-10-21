import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auvoryn/features/music/domain/song.dart';
import 'package:auvoryn/features/music/data/music_tag_reader.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class LocalMusicStore {
  LocalMusicStore._(this._db, this._musicDirectory, this._artworkDirectory);

  final Database _db;
  final Directory _musicDirectory;
  final Directory _artworkDirectory;
  static const _uuid = Uuid();
  static const supportedExtensions = {'mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg', 'opus'};

  static Future<LocalMusicStore> open() async {
    final support = await getApplicationSupportDirectory();
    final musicDir = Directory(p.join(support.path, 'imported_music'));
    await musicDir.create(recursive: true);
    final artworkDir = Directory(p.join(support.path, 'album_artwork'));
    await artworkDir.create(recursive: true);
    final db = await openDatabase(
      p.join(support.path, 'auvoryn_music.db'),
      version: 2,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tracks (
            id TEXT PRIMARY KEY, title TEXT NOT NULL, artist TEXT NOT NULL,
            album TEXT NOT NULL, filename TEXT NOT NULL, path TEXT NOT NULL,
            sha256 TEXT NOT NULL UNIQUE, imported_at INTEGER NOT NULL,
            favorite INTEGER NOT NULL DEFAULT 0,
            artwork_path TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE playlists (id TEXT PRIMARY KEY, name TEXT NOT NULL)
        ''');
        await db.execute('''
          CREATE TABLE playlist_tracks (
            playlist_id TEXT NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
            song_id TEXT NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
            position INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, song_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE app_state (key TEXT PRIMARY KEY, value TEXT NOT NULL)
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE tracks ADD COLUMN artwork_path TEXT');
        }
      },
    );
    return LocalMusicStore._(db, musicDir, artworkDir);
  }

  Future<MusicBootstrap> load() async {
    final songRows = await _db.query('tracks', orderBy: 'imported_at DESC');
    final playlistRows = await _db.query('playlists', orderBy: 'name COLLATE NOCASE');
    final playlists = <MusicPlaylist>[];
    for (final row in playlistRows) {
      final id = row['id'] as String;
      final rows = await _db.query('playlist_tracks',
        columns: ['song_id'], where: 'playlist_id = ?', whereArgs: [id], orderBy: 'position ASC');
      playlists.add(MusicPlaylist(
        id: id, name: row['name'] as String,
        songIds: rows.map((e) => e['song_id'] as String).toList(),
      ));
    }
    final state = await _db.query('app_state', where: 'key = ?', whereArgs: ['last_queue']);
    SavedQueue queue = const SavedQueue();
    if (state.isNotEmpty) {
      try {
        final map = jsonDecode(state.first['value'] as String) as Map<String, dynamic>;
        queue = SavedQueue(
          songIds: (map['ids'] as List<dynamic>).whereType<String>().toList(),
          index: (map['index'] as num).toInt(),
          positionMs: (map['positionMs'] as num?)?.toInt() ?? 0,
        );
      } catch (_) {
        // Damaged queue state never prevents the user's library from opening.
      }
    }
    return MusicBootstrap(
      songs: songRows.map(Song.fromRow).toList(), playlists: playlists, queue: queue,
    );
  }

  /// Documents selected by the OS picker may exist only in temporary cache.
  /// Copy a permanent private file before inserting its reference in SQLite.
  /// Returns null when the same audio contents were already imported.
  Future<Song?> importFile(PlatformFile picked) async {
    final ext = p.extension(picked.name).replaceFirst('.', '').toLowerCase();
    if (!supportedExtensions.contains(ext)) {
      throw const FormatException('Unsupported audio format. Try MP3, M4A, FLAC, WAV, OGG or OPUS.');
    }
    final selectedPath = picked.path;
    if (selectedPath == null) {
      throw const FileSystemException('The selected file was not accessible.');
    }
    final source = File(selectedPath);
    if (!await source.exists() || await source.length() == 0) {
      throw const FileSystemException('This file is empty or no longer accessible.');
    }
    final digest = await sha256.bind(source.openRead()).first;
    final checksum = digest.toString();
    final existing = await _db.query('tracks', columns: ['id'],
      where: 'sha256 = ?', whereArgs: [checksum], limit: 1);
    if (existing.isNotEmpty) return null;

    final id = _uuid.v4();
    final destination = File(p.join(_musicDirectory.path, '$id.$ext'));
    try {
      await source.copy(destination.path);
      // Tag decoding runs off the main isolate and is non-fatal for old files.
      final tags = await MusicTagReader.fromFile(destination.path);
      final artPath = await _saveArtwork(id, tags?.picture);
      final song = Song(
        id: id, title: tags?.title ?? Song.titleFromFileName(picked.name),
        artist: tags?.artist ?? 'Unknown artist',
        album: tags?.album ?? 'Local files',
        artworkPath: artPath,
        path: destination.path, fileName: picked.name,
        sha256: checksum, importedAt: DateTime.now(),
      );
      try {
        await _db.insert('tracks', song.toRow());
      } catch (_) {
        if (artPath != null) {
          final art = File(artPath);
          if (await art.exists()) await art.delete();
        }
        rethrow;
      }
      return song;
    } catch (_) {
      if (await destination.exists()) await destination.delete();
      rethrow;
    }
  }


  Future<String?> _saveArtwork(String id, List<int>? bytes) async {
    if (bytes == null || bytes.isEmpty || bytes.length > 8 * 1024 * 1024) return null;
    final data = Uint8List.fromList(bytes);
    final extension = MusicTagReader.pictureExtension(data);
    if (extension == null) return null;
    final file = File(p.join(_artworkDirectory.path, '$id.$extension'));
    try {
      await file.writeAsBytes(data, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Opt-in background refresh for songs imported before metadata support.
  /// Preserves playlist IDs, favorites, positions and audio file bytes.
  Future<List<Song>> refreshMetadata(List<Song> songs) async {
    final result = <Song>[];
    for (final song in songs) {
      if (!await File(song.path).exists()) {
        result.add(song);
        continue;
      }
      final tags = await MusicTagReader.fromFile(song.path);
      if (tags == null) {
        result.add(song);
        continue;
      }
      String? artPath = song.artworkPath;
      if (artPath == null && tags.picture != null) {
        artPath = await _saveArtwork(song.id, tags.picture);
      }
      final updated = song.copyWith(
        title: tags.title ?? song.title,
        artist: tags.artist ?? song.artist,
        album: tags.album ?? song.album,
        artworkPath: artPath,
      );
      if (song.title != updated.title || song.artist != updated.artist ||
          song.album != updated.album || song.artworkPath != updated.artworkPath) {
        await _db.update('tracks', {
          'title': updated.title, 'artist': updated.artist,
          'album': updated.album, 'artwork_path': updated.artworkPath,
        }, where: 'id = ?', whereArgs: [song.id]);
      }
      result.add(updated);
    }
    return result;
  }

  Future<void> setFavorite(String id, bool value) async => _db.update(
    'tracks', {'favorite': value ? 1 : 0}, where: 'id = ?', whereArgs: [id],
  );

  Future<MusicPlaylist> createPlaylist(String name) async {
    final playlist = MusicPlaylist(id: _uuid.v4(), name: name.trim());
    await _db.insert('playlists', {'id': playlist.id, 'name': playlist.name});
    return playlist;
  }

  Future<void> renamePlaylist(String id, String name) async => _db.update(
    'playlists', {'name': name.trim()}, where: 'id = ?', whereArgs: [id],
  );

  Future<void> deletePlaylist(String id) async => _db.delete(
    'playlists', where: 'id = ?', whereArgs: [id],
  );

  Future<void> updatePlaylistTracks(String id, List<String> ids) async {
    await _db.transaction((txn) async {
      await txn.delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [id]);
      for (var i = 0; i < ids.length; i++) {
        await txn.insert('playlist_tracks', {
          'playlist_id': id, 'song_id': ids[i], 'position': i,
        });
      }
    });
  }

  Future<void> saveQueue(SavedQueue state) async {
    final value = jsonEncode({
      'ids': state.songIds,
      'index': state.index,
      'positionMs': state.positionMs,
    });
    await _db.insert('app_state', {'key': 'last_queue', 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> dispose() => _db.close();
}
