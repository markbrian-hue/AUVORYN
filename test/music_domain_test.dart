import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:auvoryn/features/music/domain/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sample = Song(
    id: 'a1', title: 'A quiet song', fileName: 'A quiet song.mp3',
    path: '/private/audio/a1.mp3', sha256: 'abcd',
    importedAt: DateTime.utc(2026, 10, 21),
  );

  test('filename title extraction preserves Unicode and spaces', () {
    expect(Song.titleFromFileName('Moonlight_Sonata.mp3'), 'Moonlight Sonata');
    expect(Song.titleFromFileName('달빛.m4a'), '달빛');
    expect(Song.titleFromFileName('.mp3'), 'Untitled recording');
  });

  test('track database round trip preserves identity and favorites', () {
    final row = sample.copyWith(isFavorite: true).toRow();
    final restored = Song.fromRow(row);
    expect(restored.id, 'a1');
    expect(restored.path, sample.path);
    expect(restored.isFavorite, true);
    expect(restored.importedAt, sample.importedAt);
  });

  test('queue current song resolves to real library song', () {
    final state = MusicState(songs: [sample], queueIds: ['a1']);
    expect(state.currentSong?.title, 'A quiet song');
    expect(state.copyWith(currentIndex: 1).currentSong, null);
  });

  test('empty queue does not fabricate a currently playing track', () {
    expect(const MusicState().currentSong, null);
  });
}
