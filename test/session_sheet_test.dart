import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/features/scenes/application/listening_scenes_controller.dart';
import 'package:auvoryn/features/scenes/data/listening_scene_store.dart';
import 'package:auvoryn/features/scenes/domain/listening_scene.dart';
import 'package:auvoryn/features/sessions/application/listening_session_controller.dart';
import 'package:auvoryn/features/sessions/data/session_store.dart';
import 'package:auvoryn/features/sessions/domain/listening_session.dart';
import 'package:auvoryn/features/sessions/presentation/listening_session_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sessions implements SessionRepository {
  ListeningSession? saved;
  @override
  Future<ListeningSession?> load() async => saved;
  @override
  Future<void> save(ListeningSession? value) async { saved = value; }
}
class _Scenes implements ListeningSceneRepository {
  @override
  Future<List<ListeningScene>> load() async => [];
  @override
  Future<void> save(List<ListeningScene> values) async {}
}
class _Audio implements SessionAudioDriver {
  int invoked = 0;
  @override
  Future<void> fadeAndPause({required bool fade}) async { invoked++; }
}

void main() {
  testWidgets('start, pause, resume and cancel never command music playback',
      (tester) async {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = _Sessions();
    final audio = _Audio();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(sessions),
        listeningSceneRepositoryProvider.overrideWithValue(_Scenes()),
        sessionAudioDriverProvider.overrideWithValue(audio),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: ListeningSessionSheet()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('session_start')));
    await tester.tap(find.byKey(const Key('session_start')));
    await tester.pumpAndSettle();
    expect(sessions.saved?.kind, SessionKind.focus);
    expect(find.byKey(const Key('session_countdown')), findsOneWidget);

    await tester.tap(find.byKey(const Key('session_pause')));
    await tester.pumpAndSettle();
    expect(sessions.saved?.paused, isTrue);
    await tester.tap(find.byKey(const Key('session_pause')));
    await tester.pumpAndSettle();
    expect(sessions.saved?.paused, isFalse);
    await tester.tap(find.byKey(const Key('session_cancel')));
    await tester.pumpAndSettle();
    expect(sessions.saved, isNull);
    expect(audio.invoked, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
