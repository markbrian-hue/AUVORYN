import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/features/atmosphere/presentation/atmosphere_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sheet exposes independently labeled volume controls', (tester) async {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        initialRoomSettingsProvider.overrideWithValue(const RoomSettings()),
      ],
      child: MaterialApp(home: Scaffold(
        body: Builder(builder: (context) => FilledButton(
          onPressed: () => showAtmosphereSheet(context),
          child: const Text('Open ambience'),
        )),
      )),
    ));
    await tester.tap(find.text('Open ambience'));
    await tester.pumpAndSettle();

    expect(find.text('Set the atmosphere'), findsOneWidget);
    expect(find.byKey(const Key('ambience_enable')), findsOneWidget);
    // The content scrolls on compact phones; do not assume every slider is
    // laid out at once by the viewport's lazy delegate.
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ambience_volume_slider')), findsOneWidget);
    expect(find.byKey(const Key('music_volume_slider')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
