import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/core/settings/room_settings_store.dart';
import 'package:auvoryn/features/home_room/domain/room_camera.dart';
import 'package:auvoryn/features/home_room/presentation/room_diorama.dart';
import 'package:auvoryn/features/home_room/presentation/room_page.dart';
import 'package:auvoryn/features/home_room/presentation/room_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class SavedRoomSettings implements RoomSettingsStore {
  RoomSettings? last;
  @override
  Future<void> save(RoomSettings settings) async {
    last = settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget scene({
  double width = 280,
  RoomSettings settings = const RoomSettings(reducedMotion: true),
  ValueChanged<String>? onTap,
}) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: RoomScene(
          settings: settings,
          hasTrack: true,
          isPlaying: true,
          onRecordTap: () => onTap?.call('record'),
          onWindowTap: () => onTap?.call('window'),
          onLampTap: () => onTap?.call('lamp'),
          onShelfTap: () => onTap?.call('shelf'),
          onSpeakerTap: () => onTap?.call('speaker'),
        ),
      ),
    ),
  ),
);

RoomDioramaPainter painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<RoomDioramaPainter>()
    .single;

void main() {
  test('camera keeps authored room vertices in front of its near plane', () {
    for (final orbit in [0.0, .25, .5, .75, 1.0]) {
      final camera = RoomCamera(orbit: orbit);
      for (final x in [-3.24, 3.20]) {
        for (final y in [-.20, 4.0]) {
          for (final z in [-2.94, 2.85]) {
            final p = camera.project(RoomPoint(x, y, z), 320, 348);
            expect(p.depth, greaterThan(1));
            expect(p.x.isFinite && p.y.isFinite, isTrue);
            expect(p.x, inInclusiveRange(0, 320));
            expect(p.y, inInclusiveRange(0, 348));
          }
        }
      }
    }
  });
  test('perspective scales foreground objects and clamps invalid orbit', () {
    const camera = RoomCamera(orbit: 0);
    final far = camera.project(const RoomPoint(1, 1.45, -2), 320, 348);
    final near = camera.project(const RoomPoint(1, 1.45, 2), 320, 348);
    expect(near.depth, lessThan(far.depth));
    expect(
      const RoomCamera(orbit: -2).project(RoomCamera.lamp, 320, 348).x,
      camera.project(RoomCamera.lamp, 320, 348).x,
    );
  });
  testWidgets(
    'orbit changes projection, clamps and resets without moving hit targets away',
    (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(scene(onTap: calls.add));
      final initial = tester.getCenter(
        find.byKey(const Key('room_target_lamp')),
      );
      await tester.drag(
        find.byKey(const Key('room_camera_gesture')),
        const Offset(500, 0),
      );
      await tester.pump();
      expect(painter(tester).camera.orbit, 1);
      expect(
        tester.getCenter(find.byKey(const Key('room_target_lamp'))),
        isNot(initial),
      );
      for (final key in ['record', 'window', 'lamp', 'shelf', 'speaker']) {
        await tester.tap(find.byKey(Key('room_target_$key')));
        await tester.pump();
      }
      expect(calls, ['record', 'window', 'lamp', 'shelf', 'speaker']);
      final regions = [
        for (final key in ['record', 'window', 'lamp', 'shelf', 'speaker'])
          tester.getRect(find.byKey(Key('room_target_$key'))),
      ];
      for (var i = 0; i < regions.length; i++) {
        expect(regions[i].size, const Size(48, 48));
        for (var j = i + 1; j < regions.length; j++) {
          expect(regions[i].overlaps(regions[j]), isFalse);
        }
      }
      await tester.tap(find.byKey(const Key('room_view_reset')));
      await tester.pump();
      expect(painter(tester).camera.orbit, .5);
      expect(
        tester.getCenter(find.byKey(const Key('room_target_lamp'))),
        initial,
      );
    },
  );
  testWidgets(
    'camera controls work with reduced motion and scene animation stops in background',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        scene(settings: const RoomSettings(mood: RoomMood.lightRain)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        scene(
          settings: const RoomSettings(
            mood: RoomMood.lightRain,
            reducedMotion: true,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('room_view_left')));
      await tester.pumpAndSettle();
      expect(painter(tester).camera.orbit, .25);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('room controls can be hidden and restored', (tester) async {
    await tester.pumpWidget(scene());
    await tester.tap(find.byTooltip('Hide room controls'));
    await tester.pump();
    expect(find.byKey(const Key('room_target_record')), findsNothing);
    await tester.tap(find.byTooltip('Show room controls'));
    await tester.pump();
    expect(find.byKey(const Key('room_target_record')), findsOneWidget);
  });
  testWidgets(
    'large-text home presets update persisted settings without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = SavedRoomSettings();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialRoomSettingsProvider.overrideWithValue(
              const RoomSettings(reducedMotion: true),
            ),
            roomSettingsStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const Scaffold(body: RoomPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final preset = find.byKey(const Key('home_mood_warmSunset'));
      await tester.scrollUntilVisible(
        preset,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(preset), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(preset);
      await tester.pumpAndSettle();
      expect(store.last?.mood, RoomMood.warmSunset);
      expect(tester.takeException(), isNull);
    },
  );
}
