import 'package:auvoryn/core/widgets/vinyl_artwork.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:auvoryn/features/music/domain/song.dart';
import 'package:auvoryn/features/music/presentation/now_playing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _PreviewMusicController extends MusicController {
  @override
  MusicState build() => MusicState(
    songs: [Song(
      id: 'test-song',
      title: 'Night Drive',
      artist: 'Local artist',
      album: 'Local collection',
      path: '/tmp/test-song.mp3',
      fileName: 'night-drive.mp3',
      sha256: 'preview',
      importedAt: DateTime(2026),
    )],
    queueIds: const ['test-song'],
    duration: const Duration(minutes: 3, seconds: 42),
    position: const Duration(seconds: 22),
  );
}

void main() {
  testWidgets('vinyl displays its truthful paused state', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: VinylArtwork(
        title: 'Night Drive',
        playing: false,
        size: 180,
      )),
    ));
    expect(find.bySemanticsLabel('Vinyl record paused'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('now playing keeps direct controls and an accessible queue', (tester) async {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        musicProvider.overrideWith(_PreviewMusicController.new),
      ],
      child: const MaterialApp(home: NowPlayingPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Night Drive'), findsOneWidget);
    expect(find.byKey(const Key('player_toggle')), findsOneWidget);
    expect(find.byKey(const Key('player_seek')), findsOneWidget);

    // Queue is reachable from the header even on compact displays.
    await tester.tap(find.byTooltip('Open playback queue'));
    await tester.pumpAndSettle();
    expect(find.text('Your queue'), findsOneWidget);
    expect(find.byKey(const Key('queue_item_0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
