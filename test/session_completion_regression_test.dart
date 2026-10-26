import 'dart:async';

import 'package:auvoryn/features/sessions/application/listening_session_controller.dart';
import 'package:auvoryn/features/sessions/data/session_store.dart';
import 'package:auvoryn/features/sessions/domain/listening_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _expiredSleepSession = ListeningSession(
  id: 'expired-sleep',
  kind: SessionKind.sleep,
  durationMs: 60000,
  deadlineMs: 1,
  remainingOnPauseMs: 60000,
  endBehavior: SessionEndBehavior.fadeAndPause,
);

class _MemorySessionRepository implements SessionRepository {
  ListeningSession? saved = _expiredSleepSession;
  int clears = 0;

  @override
  Future<ListeningSession?> load() async => saved;

  @override
  Future<void> save(ListeningSession? session) async {
    if (session == null) clears++;
    saved = session;
  }
}

class _DelayedAudioDriver implements SessionAudioDriver {
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> fadeAndPause({required bool fade}) async {
    entered.complete();
    await release.future;
  }
}

class _FailingAudioDriver implements SessionAudioDriver {
  @override
  Future<void> fadeAndPause({required bool fade}) async {
    throw StateError('Audio engine unavailable');
  }
}

Widget _probe(
  SessionRepository repository,
  SessionAudioDriver driver,
) => ProviderScope(
  overrides: [
    sessionRepositoryProvider.overrideWithValue(repository),
    sessionAudioDriverProvider.overrideWithValue(driver),
  ],
  child: Consumer(
    builder: (context, ref, child) {
      ref.watch(listeningSessionProvider);
      return const SizedBox.shrink();
    },
  ),
);

void main() {
  testWidgets('an expired sleep session persists until audio stop completes',
      (tester) async {
    final repository = _MemorySessionRepository();
    final driver = _DelayedAudioDriver();
    await tester.pumpWidget(_probe(repository, driver));
    await tester.pumpAndSettle();

    expect(driver.entered.isCompleted, isTrue);
    expect(repository.saved?.id, 'expired-sleep');
    expect(repository.clears, 0);

    driver.release.complete();
    await tester.pumpAndSettle();
    expect(repository.saved, isNull);
    expect(repository.clears, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('audio shutdown failure preserves the deadline for restoration',
      (tester) async {
    final repository = _MemorySessionRepository();
    await tester.pumpWidget(_probe(repository, _FailingAudioDriver()));
    await tester.pumpAndSettle();

    expect(repository.saved?.id, 'expired-sleep');
    expect(repository.clears, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
