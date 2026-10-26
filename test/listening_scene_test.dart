import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/core/settings/room_settings_store.dart';
import 'package:auvoryn/features/scenes/application/listening_scenes_controller.dart';
import 'package:auvoryn/features/scenes/data/listening_scene_store.dart';
import 'package:auvoryn/features/scenes/domain/listening_scene.dart';
import 'package:auvoryn/features/scenes/presentation/listening_scenes_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryScenes implements ListeningSceneRepository {
  List<ListeningScene> saved = [];
  @override
  Future<List<ListeningScene>> load() async => List.of(saved);
  @override
  Future<void> save(List<ListeningScene> value) async {
    saved = List.of(value);
  }
}

class _MemoryRoomStore implements RoomSettingsStore {
  RoomSettings? last;
  @override
  Future<void> save(RoomSettings settings) async {
    last = settings;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('scenes roundtrip with playlist and do not overwrite reduced motion', () {
    const original = ListeningScene(
      id: 'one',
      name: 'Rainy Study Night',
      room: RoomSettings(
        mood: RoomMood.lightRain,
        lampPalette: LampPalette.moonlight,
        ambienceEnabled: true,
        ambienceVolume: .27,
      ),
      playlistId: 'playlist-1',
    );
    final restored = ListeningScene.fromJson(original.toJson());
    expect(restored.id, 'one');
    expect(restored.playlistId, 'playlist-1');
    expect(restored.room.mood, RoomMood.lightRain);
    const current = RoomSettings(reducedMotion: true);
    final applied = restored.applyTo(current);
    expect(applied.reducedMotion, isTrue);
    expect(applied.ambienceEnabled, isTrue);
    expect(applied.ambienceVolume, .27);
    expect(applied.musicVolume, original.room.musicVolume);
  });

  test('starter scenes are independent from imported media', () {
    expect(ListeningScene.starters.length, 3);
    for (final scene in ListeningScene.starters) {
      expect(scene.starter, isTrue);
      expect(scene.playlistId, isNull);
    }
  });

  testWidgets('scene create, apply and duplicate use local persistence',
      (tester) async {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scenes = _MemoryScenes();
    final room = _MemoryRoomStore();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        initialRoomSettingsProvider.overrideWithValue(
          const RoomSettings(reducedMotion: true)),
        listeningSceneRepositoryProvider.overrideWithValue(scenes),
        roomSettingsStoreProvider.overrideWithValue(room),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ListeningScenesSheet()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scene_create')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('scene_name_input')),
        '  Quiet Work  ');
    await tester.tap(find.byKey(const Key('scene_save')));
    await tester.pumpAndSettle();
    expect(scenes.saved.length, 1);
    expect(scenes.saved.single.name, 'Quiet Work');

    await tester.tap(find.text('Apply').first);
    await tester.pumpAndSettle();
    expect(room.last?.reducedMotion, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
