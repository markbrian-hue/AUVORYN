import 'package:auvoryn/features/sessions/domain/listening_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session deadline accounts for time spent in background', () {
    const start = 1000000;
    const session = ListeningSession(
      id: 'a',
      kind: SessionKind.sleep,
      durationMs: 1200000,
      deadlineMs: start + 1200000,
      remainingOnPauseMs: 1200000,
      endBehavior: SessionEndBehavior.fadeAndPause,
    );
    expect(session.remainingMs(start), 1200000);
    expect(session.remainingMs(start + 330000), 870000);
    expect(session.remainingMs(start + 3000000), 0);
  });

  test('pausing freezes the remaining time and resume moves deadline', () {
    const original = ListeningSession(
      id: 'b',
      kind: SessionKind.focus,
      durationMs: 1500000,
      deadlineMs: 2500000,
      remainingOnPauseMs: 1500000,
      endBehavior: SessionEndBehavior.keepPlaying,
    );
    final paused = original.pause(1300000);
    expect(paused.paused, isTrue);
    expect(paused.remainingMs(10000000), 1200000);
    final resumed = paused.resume(10000000);
    expect(resumed.paused, isFalse);
    expect(resumed.remainingMs(10500000), 700000);
  });

  test('persisted sessions preserve end choice and paused status', () {
    const original = ListeningSession(
      id: 'c',
      kind: SessionKind.sleep,
      durationMs: 2700000,
      deadlineMs: 12345678,
      remainingOnPauseMs: 49000,
      paused: true,
      endBehavior: SessionEndBehavior.fadeAndPause,
      sceneId: 'scene-123',
    );
    final restored = ListeningSession.fromJson(original.toJson());
    expect(restored.paused, isTrue);
    expect(restored.remainingOnPauseMs, 49000);
    expect(restored.sceneId, 'scene-123');
    expect(restored.endBehavior, SessionEndBehavior.fadeAndPause);
    expect(() => ListeningSession.fromJson({
      'id': 'x', 'durationMs': -10, 'deadlineMs': 0,
      'remainingOnPauseMs': 0,
    }), throwsFormatException);
  });
}
