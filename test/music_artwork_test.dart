import 'dart:typed_data';

import 'package:auvoryn/core/widgets/song_artwork.dart';
import 'package:auvoryn/features/music/data/music_tag_reader.dart';
import 'package:auvoryn/features/music/domain/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes image signatures and rejects unexpected bytes', () {
    expect(MusicTagReader.pictureExtension(Uint8List.fromList(
      [0xFF, 0xD8, 0xFF, 0xE0])), 'jpg');
    expect(MusicTagReader.pictureExtension(Uint8List.fromList(
      [0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A])), 'png');
    expect(MusicTagReader.pictureExtension(Uint8List.fromList(
      [82,73,70,70,0,0,0,0,87,69,66,80])), 'webp');
    expect(MusicTagReader.pictureExtension(Uint8List.fromList(
      [0x47,0x49,0x46,0x38])), isNull);
  });

  test('song metadata retains older rows and favorites', () {
    final row = <String, Object?>{
      'id': 'one', 'title': 'Before', 'artist': 'Unknown artist',
      'album': 'Local files', 'path': '/some/song.mp3',
      'filename': 'song.mp3', 'sha256': 'abcd', 'imported_at': 0,
      'favorite': 1, 'artwork_path': null,
    };
    final updated = Song.fromRow(row).copyWith(
      title: 'After', artist: 'An Artist', artworkPath: '/local/cover.jpg',
    );
    expect(updated.title, 'After');
    expect(updated.artist, 'An Artist');
    expect(updated.isFavorite, isTrue);
    expect(updated.toRow()['artwork_path'], '/local/cover.jpg');
  });

  testWidgets('artwork renders a branded fallback without an image', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SongArtwork(title: 'Night Drive', size: 100),
    )));
    expect(find.byIcon(Icons.album_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
