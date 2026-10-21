import 'dart:io';
import 'dart:ui' as ui;

import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/features/home_room/presentation/room_page.dart';
import 'package:auvoryn/features/home_room/presentation/room_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Opt-in CI capture of actual Flutter output. This is not a performance benchmark
// or a golden-image assertion, and does not change production behavior.
void main() {
  testWidgets('capture actual home and room views for visual review', (
    tester,
  ) async {
    await tester.runAsync(() async {
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
    Future<void> capture(String name, Widget child, Size size) async {
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
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: Scaffold(body: child),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
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

    Widget room(RoomSettings settings) => Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: RoomScene(
          settings: settings,
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
    await capture(
      'midnight',
      room(const RoomSettings(reducedMotion: true)),
      const Size(430, 520),
    );
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
