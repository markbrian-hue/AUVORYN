class ListeningTrack {
  const ListeningTrack({required this.id, required this.title, required this.artist,
    required this.listenedMs, required this.plays, required this.lastPlayedAt});
  final String id, title, artist;
  final int listenedMs, plays;
  final DateTime lastPlayedAt;
  factory ListeningTrack.fromRow(Map<String, Object?> row) => ListeningTrack(
    id: row['song_id'] as String, title: row['title'] as String,
    artist: row['artist'] as String, listenedMs: (row['listened_ms'] as num).toInt(),
    plays: (row['plays'] as num).toInt(),
    lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(
      (row['last_played_at'] as num).toInt()));
}
class ListeningSnapshot {
  const ListeningSnapshot({required this.totalMs, required this.totalPlays,
    required this.tracks, required this.recent, required this.topTracks,
    required this.topArtist});
  final int totalMs, totalPlays, tracks;
  final List<ListeningTrack> recent, topTracks;
  final String? topArtist;
}
