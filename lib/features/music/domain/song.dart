/// A private, locally-owned copy of a selected audio file.
class Song {
  const Song({
    required this.id,
    required this.title,
    required this.path,
    required this.fileName,
    required this.sha256,
    required this.importedAt,
    this.artist = 'Unknown artist',
    this.album = 'Local files',
    this.isFavorite = false,
    this.artworkPath,
  });

  final String id;
  final String title;
  final String path;
  final String fileName;
  final String sha256;
  final DateTime importedAt;
  final String artist;
  final String album;
  final bool isFavorite;
  /// Path to independently stored, locally extracted album artwork.
  final String? artworkPath;

  Song copyWith({bool? isFavorite, String? title, String? artist,
    String? album, String? artworkPath}) => Song(
    id: id,
    title: title ?? this.title,
    path: path,
    fileName: fileName,
    sha256: sha256,
    importedAt: importedAt,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    isFavorite: isFavorite ?? this.isFavorite,
    artworkPath: artworkPath ?? this.artworkPath,
  );

  static String titleFromFileName(String name) {
    final dot = name.lastIndexOf('.');
    final base = dot >= 0 ? name.substring(0, dot) : name;
    final cleaned = base.replaceAll(RegExp(r'[_]+'), ' ').trim();
    return cleaned.isEmpty ? 'Untitled recording' : cleaned;
  }

  factory Song.fromRow(Map<String, Object?> row) => Song(
    id: row['id'] as String,
    title: row['title'] as String,
    path: row['path'] as String,
    fileName: row['filename'] as String,
    sha256: row['sha256'] as String,
    importedAt: DateTime.fromMillisecondsSinceEpoch(row['imported_at'] as int),
    artist: row['artist'] as String,
    album: row['album'] as String,
    artworkPath: row['artwork_path'] as String?,
    isFavorite: (row['favorite'] as int) == 1,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'title': title,
    'path': path,
    'filename': fileName,
    'sha256': sha256,
    'imported_at': importedAt.millisecondsSinceEpoch,
    'artist': artist,
    'album': album,
    'artwork_path': artworkPath,
    'favorite': isFavorite ? 1 : 0,
  };
}

class MusicPlaylist {
  const MusicPlaylist({required this.id, required this.name, this.songIds = const []});
  final String id;
  final String name;
  final List<String> songIds;

  MusicPlaylist copyWith({String? name, List<String>? songIds}) => MusicPlaylist(
    id: id, name: name ?? this.name, songIds: songIds ?? this.songIds,
  );
}

class SavedQueue {
  const SavedQueue({this.songIds = const [], this.index = 0, this.positionMs = 0});
  final List<String> songIds;
  final int index;
  final int positionMs;
}

class MusicBootstrap {
  const MusicBootstrap({required this.songs, required this.playlists, required this.queue});
  final List<Song> songs;
  final List<MusicPlaylist> playlists;
  final SavedQueue queue;
}
