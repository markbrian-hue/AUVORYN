import 'package:auvoryn/features/memories/domain/listening_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pause and seek do not inflate listening time', () {
    final saved = <ListeningCheckpoint>[];
    final t = ListeningTracker(saved.add);
    t.sample(songId: 'a', positionMs: 0, nowMs: 0, playing: true, ready: true);
    t.sample(
      songId: 'a',
      positionMs: 5200,
      nowMs: 5200,
      playing: true,
      ready: true,
    );
    t.sample(
      songId: 'a',
      positionMs: 5200,
      nowMs: 9200,
      playing: false,
      ready: true,
    );
    t.sample(
      songId: 'a',
      positionMs: 5200,
      nowMs: 9300,
      playing: true,
      ready: true,
    );
    t.sample(
      songId: 'a',
      positionMs: 10500,
      nowMs: 14600,
      playing: true,
      ready: true,
    );
    t.sample(
      songId: 'a',
      positionMs: 45000,
      nowMs: 14700,
      playing: true,
      ready: true,
    );
    t.flush();
    expect(saved.fold<int>(0, (v, x) => v + x.listenedMs), 10500);
    expect(saved.where((x) => x.qualifiedPlay).length, 1);
  });
  test('changes of track checkpoint listening time', () {
    final saved = <ListeningCheckpoint>[];
    final t = ListeningTracker(saved.add);
    t.sample(songId: 'a', positionMs: 0, nowMs: 0, playing: true, ready: true);
    t.sample(
      songId: 'a',
      positionMs: 3000,
      nowMs: 3000,
      playing: true,
      ready: true,
    );
    t.sample(
      songId: 'b',
      positionMs: 0,
      nowMs: 3200,
      playing: true,
      ready: true,
    );
    t.sample(
      songId: 'b',
      positionMs: 6000,
      nowMs: 9200,
      playing: true,
      ready: true,
    );
    expect(saved[0].songId, 'a');
    expect(saved[0].listenedMs, 3000);
    expect(saved.last.songId, 'b');
  });
  test('explicit small seek is excluded from listening progress', () {
    final saved = <ListeningCheckpoint>[];
    final tracker = ListeningTracker(saved.add);
    tracker.sample(
      songId: 'a',
      positionMs: 0,
      nowMs: 0,
      playing: true,
      ready: true,
    );
    tracker.sample(
      songId: 'a',
      positionMs: 1000,
      nowMs: 1000,
      playing: true,
      ready: true,
    );
    tracker.discontinuity();
    tracker.sample(
      songId: 'a',
      positionMs: 1900,
      nowMs: 1100,
      playing: true,
      ready: true,
    );
    tracker.sample(
      songId: 'a',
      positionMs: 2900,
      nowMs: 2100,
      playing: true,
      ready: true,
    );
    tracker.flush();
    expect(
      saved.fold<int>(0, (total, entry) => total + entry.listenedMs),
      2000,
    );
  });
}
