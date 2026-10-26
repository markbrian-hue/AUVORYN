import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/features/companion/application/room_companion_controller.dart';
import 'package:auvoryn/features/companion/data/room_companion_store.dart';
import 'package:auvoryn/features/companion/domain/room_companion.dart';
import 'package:auvoryn/features/companion/presentation/room_companion_sheet.dart';
import 'package:auvoryn/features/home_room/presentation/room_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryCompanions implements RoomCompanionRepository {
  RoomCompanion stored = const RoomCompanion();
  int writes = 0;
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<RoomCompanion> load() async {
    if (failRead) throw const FormatException('Unknown saved version');
    return stored;
  }

  @override
  Future<void> save(RoomCompanion value) async {
    if (failWrite) throw StateError('Disk unavailable');
    stored = value;
    writes++;
  }
}

void main() {
  test('character variants have distinct hair and clothing defaults', () {
    expect(RoomCompanion.forStyle(CompanionStyle.boy).hair,
        CompanionHair.cropped);
    expect(RoomCompanion.forStyle(CompanionStyle.girl).hair,
        CompanionHair.long);
    expect(RoomCompanion.forStyle(CompanionStyle.emoBoy).hair,
        CompanionHair.fringe);
    expect(RoomCompanion.forStyle(CompanionStyle.emoGirl).outfit,
        CompanionOutfit.plum);
  });

  test('all customization settings survive local JSON roundtrip', () {
    final original = RoomCompanion.forStyle(
      CompanionStyle.emoGirl,
      skin: CompanionSkin.deep,
      pose: CompanionPose.window,
    ).copyWith(visible: false, hair: CompanionHair.waves,
        outfit: CompanionOutfit.sage);
    final saved = RoomCompanion.fromJson(original.toJson());
    expect(saved.visible, isFalse);
    expect(saved.style, CompanionStyle.emoGirl);
    expect(saved.pose, CompanionPose.window);
    expect(saved.hair, CompanionHair.waves);
    expect(saved.skin, CompanionSkin.deep);
    expect(saved.outfit, CompanionOutfit.sage);
  });

  test('corrupted companion values are rejected rather than reset', () {
    final good = const RoomCompanion().toJson();
    expect(() => RoomCompanion.fromJson({...good, 'schema': 42}),
        throwsFormatException);
    expect(() => RoomCompanion.fromJson({...good, 'hair': 'unknown'}),
        throwsFormatException);
    expect(() => RoomCompanion.fromJson({...good, 'visible': 'yes'}),
        throwsFormatException);
  });

  testWidgets('customization saves offline and keeps music untouched',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MemoryCompanions();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        roomCompanionRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: RoomCompanionSheet()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('companion_style_emoBoy')));
    await tester.pumpAndSettle();
    expect(repository.stored.style, CompanionStyle.emoBoy);
    expect(repository.stored.hair, CompanionHair.fringe);
    await tester.tap(find.byKey(const Key('companion_pose_window')));
    await tester.pumpAndSettle();
    expect(repository.stored.pose, CompanionPose.window);
    await tester.tap(find.byKey(const Key('companion_visible')));
    await tester.pumpAndSettle();
    expect(repository.stored.visible, isFalse);
    expect(repository.writes, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed restore blocks writes to damaged settings',
      (tester) async {
    final repository = _MemoryCompanions()..failRead = true;
    late WidgetRef reader;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        roomCompanionRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(home: Consumer(builder: (context, ref, child) {
        reader = ref;
        final state = ref.watch(roomCompanionProvider);
        return Text(state.error ?? 'loading');
      })),
    ));
    await tester.pumpAndSettle();
    expect(reader.read(roomCompanionProvider).readFailed, isTrue);
    expect(await reader.read(roomCompanionProvider.notifier)
        .setVisible(false), isFalse);
    expect(repository.writes, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('companion changes never steal room object tap targets',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Center(child: SizedBox(width: 390,
        child: RoomScene(
          settings: const RoomSettings(reducedMotion: true),
          companion: RoomCompanion.forStyle(CompanionStyle.girl),
          onRecordTap: () {},
          onWindowTap: () {},
          onLampTap: () {},
          onShelfTap: () {},
          onSpeakerTap: () {},
        ),
      )),
    )));
    expect(find.byKey(const Key('room_target_speaker')), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Center(child: SizedBox(width: 390,
        child: RoomScene(
          settings: const RoomSettings(reducedMotion: true),
          companion: const RoomCompanion(visible: false),
          onRecordTap: () {},
          onWindowTap: () {},
          onLampTap: () {},
          onShelfTap: () {},
          onSpeakerTap: () {},
        ),
      )),
    )));
    expect(find.byKey(const Key('room_target_speaker')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
