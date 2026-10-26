import 'dart:io';
import 'dart:ui' as ui;

import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/features/companion/application/room_companion_controller.dart';
import 'package:auvoryn/features/companion/data/room_companion_store.dart';
import 'package:auvoryn/features/companion/domain/room_companion.dart';
import 'package:auvoryn/features/companion/presentation/room_companion_sheet.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/features/home_room/presentation/room_page.dart';
import 'package:auvoryn/features/home_room/presentation/room_scene.dart';
import 'package:auvoryn/features/home_room/presentation/immersive_room_page.dart';
import 'package:auvoryn/features/scenes/data/listening_scene_store.dart';
import 'package:auvoryn/features/scenes/application/listening_scenes_controller.dart';
import 'package:auvoryn/features/scenes/domain/listening_scene.dart';
import 'package:auvoryn/features/scenes/presentation/listening_scenes_sheet.dart';
import 'package:auvoryn/features/sessions/data/session_store.dart';
import 'package:auvoryn/features/sessions/application/listening_session_controller.dart';
import 'package:auvoryn/features/sessions/domain/listening_session.dart';
import 'package:auvoryn/features/sessions/presentation/listening_session_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _PreviewSceneRepository implements ListeningSceneRepository {
  @override
  Future<List<ListeningScene>> load() async => const [
    ListeningScene(
      id: 'preview-scene',
      name: 'Reading by the Window',
      room: RoomSettings(
        mood: RoomMood.lightRain,
        lampPalette: LampPalette.amber,
        lampBrightness: .54,
        ambienceEnabled: true,
      ),
    ),
  ];
  @override
  Future<void> save(List<ListeningScene> scenes) async {}
}

class _PreviewSessionRepository implements SessionRepository {
  @override
  Future<ListeningSession?> load() async => null;
  @override
  Future<void> save(ListeningSession? value) async {}
}

class _PreviewCompanionRepository implements RoomCompanionRepository {
  @override
  Future<RoomCompanion> load() async => const RoomCompanion();
  @override
  Future<void> save(RoomCompanion companion) async {}
}

// Opt-in CI capture of actual Flutter output. This is not a performance benchmark
// or a golden-image assertion, and does not change production behavior.
void main() {
  testWidgets('capture actual home and room views for visual review', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      for (final entry in {
        'Manrope': 'Manrope-Variable.ttf',
        'InstrumentSerif': 'InstrumentSerif-Regular.ttf',
      }.entries) {
        await (FontLoader(
          entry.key,
        )..addFont(rootBundle.load('assets/fonts/${entry.value}'))).load();
      }
    });
    final root = GlobalKey();
    Future<void> capture(
      String name,
      Widget child,
      Size size, {
      Future<void> Function()? arrange,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        RepaintBoundary(
          key: root,
          child: ProviderScope(
            overrides: [
              initialRoomSettingsProvider.overrideWithValue(
                const RoomSettings(reducedMotion: true),
              ),
              listeningSceneRepositoryProvider.overrideWithValue(
                _PreviewSceneRepository(),
              ),
              sessionRepositoryProvider.overrideWithValue(
                _PreviewSessionRepository(),
              ),
              roomCompanionRepositoryProvider.overrideWithValue(
                _PreviewCompanionRepository(),
              ),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: Scaffold(body: child),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (arrange != null) {
        await arrange();
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/room-previews/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    Widget room(RoomSettings settings, {RoomCompanion? companion}) => Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: RoomScene(
          settings: settings,
          companion: companion,
          hasTrack: true,
          onRecordTap: () {},
          onWindowTap: () {},
          onLampTap: () {},
          onShelfTap: () {},
          onSpeakerTap: () {},
        ),
      ),
    );
    await capture('home', const RoomPage(), const Size(390, 1200));
    await capture('companion-editor', const RoomCompanionSheet(),
        const Size(430, 1100));
    await capture('companion-emo-boy',
        room(const RoomSettings(reducedMotion: true),
          companion: RoomCompanion.forStyle(CompanionStyle.emoBoy)
              .copyWith(pose: CompanionPose.window)),
        const Size(430, 520));
    await capture(
      'listening-scenes',
      const ListeningScenesSheet(),
      const Size(430, 1100),
    );
    await capture(
      'session-setup',
      const ListeningSessionSheet(),
      const Size(430, 1050),
    );
    await capture(
      'immersive-apartment',
      const ImmersiveRoomPage(),
      const Size(430, 900),
    );

    await capture(
      'midnight',
      room(const RoomSettings(reducedMotion: true)),
      const Size(430, 520),
    );
    for (final direction in ['left', 'right']) {
      await capture(
        'orbit-$direction',
        room(const RoomSettings(reducedMotion: true)),
        const Size(430, 520),
        arrange: () async {
          await tester.tap(find.byKey(const Key('room_view_reset')));
          await tester.tap(find.byKey(Key('room_view_$direction')));
          await tester.tap(find.byKey(Key('room_view_$direction')));
          await tester.pump();
        },
      );
    }
    await capture(
      'sunset-coast',
      room(
        const RoomSettings(
          reducedMotion: true,
          mood: RoomMood.warmSunset,
          windowView: WindowView.coast,
        ),
      ),
      const Size(430, 520),
    );
    await capture(
      'rain-mountain',
      room(
        const RoomSettings(
          reducedMotion: true,
          mood: RoomMood.lightRain,
          windowView: WindowView.mountain,
          lampPalette: LampPalette.moonlight,
        ),
      ),
      const Size(430, 520),
    );
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, skip: !const bool.fromEnvironment('CAPTURE_ROOM_PREVIEWS'));
}
