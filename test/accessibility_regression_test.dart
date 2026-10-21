import 'package:auvoryn/app/app.dart';
import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/core/widgets/vinyl_artwork.dart';
import 'package:auvoryn/features/customization/presentation/window_view_sheet.dart';
import 'package:auvoryn/features/library/presentation/library_page.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:auvoryn/features/music/domain/song.dart';
import 'package:auvoryn/features/music/presentation/now_playing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class PreviewController extends MusicController {
  @override
  MusicState build() => MusicState(
    songs: [
      Song(
        id: 's',
        title: 'A very long song title for small screens',
        fileName: 's.mp3',
        path: '/s.mp3',
        sha256: 's',
        importedAt: DateTime(2026),
      ),
    ],
    queueIds: const ['s'],
    playlists: List.generate(
      30,
      (i) => MusicPlaylist(id: '$i', name: 'Playlist $i'),
    ),
  );
}

void main() {
  testWidgets('app Reduce motion reaches every route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialRoomSettingsProvider.overrideWithValue(
            const RoomSettings(reducedMotion: true),
          ),
        ],
        child: const AuvorynApp(),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Midnight Apartment'));
    expect(MediaQuery.of(context).disableAnimations, true);
  });

  testWidgets('player fits a 320-wide display with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [musicProvider.overrideWith(PreviewController.new)],
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const NowPlayingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('player_toggle')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('playlist picker scrolls to the last playlist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [musicProvider.overrideWith(PreviewController.new)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showAddToPlaylistSheet(
                  context,
                  ref.read(musicProvider).songs.first,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Playlist 29'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('window customization remains scrollable in compact landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showWindowViewSheet(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('window_view_coast')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('vinyl stops scheduling animation frames in background', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VinylArtwork(title: 'Song', playing: true, size: 180),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 30));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
