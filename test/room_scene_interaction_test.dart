import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/features/home_room/presentation/room_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('room hotspots trigger their corresponding actions', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 390, child: RoomScene(
            settings: const RoomSettings(),
            hasTrack: true,
            isPlaying: false,
            onRecordTap: () => calls.add('record'),
            onWindowTap: () => calls.add('window'),
            onLampTap: () => calls.add('lamp'),
            onShelfTap: () => calls.add('shelf'),
            onSpeakerTap: () => calls.add('speaker'),
          )),
        ),
      ),
    ));

    for (final label in [
      'Open now playing',
      'Change weather',
      'Turn lamp off',
      'Open playlists',
      'Open music and ambience mixer',
    ]) {
      await tester.tap(find.byTooltip(label));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(calls, ['record', 'window', 'lamp', 'shelf', 'speaker']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rain and record respond to updated settings and reduced motion',
      (tester) async {
    Widget room(RoomSettings settings, {required bool playing}) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 300,
        child: RoomScene(
          settings: settings,
          hasTrack: true,
          isPlaying: playing,
          onRecordTap: () {}, onWindowTap: () {}, onLampTap: () {},
          onShelfTap: () {}, onSpeakerTap: () {},
        ),
      ))),
    );

    await tester.pumpWidget(room(
      const RoomSettings(mood: RoomMood.lightRain), playing: true));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byTooltip('Open music and ambience mixer'), findsOneWidget);
    await tester.pumpWidget(room(const RoomSettings(
      mood: RoomMood.thunderstorm, lampOn: false, reducedMotion: true,
    ), playing: false));
    await tester.pump(const Duration(milliseconds: 25));
    expect(find.byTooltip('Turn lamp on'), findsOneWidget);
    expect(find.byTooltip('Open music and ambience mixer'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Reduced motion removes continuously scheduled scene frames.
    await tester.pump(const Duration(seconds: 6));
    expect(tester.takeException(), isNull);
  });
}
