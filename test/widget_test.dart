import 'package:auvoryn/features/music/domain/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AUVORYN song titles are inferred from imported filenames', () {
    expect(Song.titleFromFileName('Midnight_Piano.mp3'), 'Midnight Piano');
  });
}
