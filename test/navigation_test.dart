import 'package:auvoryn/app/app.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:auvoryn/features/memories/domain/listening_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('room and primary navigation show the expected destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialRoomSettingsProvider.overrideWithValue(const RoomSettings()),
          listeningSnapshotProvider.overrideWith((ref) async =>
              const ListeningSnapshot(totalMs: 0, totalPlays: 0,
                tracks: 0, recent: [], topTracks: [], topArtist: null)),
        ],
        child: const AuvorynApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Midnight Apartment'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tab_library')));
    await tester.pumpAndSettle();
    expect(find.text('Every song, yours.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tab_memories')));
    await tester.pumpAndSettle();
    expect(find.text('Moments in music.'), findsOneWidget);
  });
}
