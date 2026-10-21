import 'package:auvoryn/app/app.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/core/settings/room_settings_store.dart';
import 'package:auvoryn/features/music/data/local_music_store.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = RoomSettingsStore(SharedPreferencesAsync());
  RoomSettings initialSettings;
  try {
    initialSettings = await store.load();
  } catch (error) {
    debugPrint('Room settings could not be loaded: $error');
    initialSettings = const RoomSettings();
  }

  // Single background media service. No account or network connection required.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'app.auvoryn.music',
    androidNotificationChannelName: 'AUVORYN playback',
    androidNotificationOngoing: true,
  );
  final musicStore = await LocalMusicStore.open();
  final initialMusic = await musicStore.load();

  runApp(
    ProviderScope(
      overrides: [
        initialRoomSettingsProvider.overrideWithValue(initialSettings),
        roomSettingsStoreProvider.overrideWithValue(store),
        musicStoreProvider.overrideWithValue(musicStore),
        initialMusicProvider.overrideWithValue(initialMusic),
      ],
      child: const AuvorynApp(),
    ),
  );
}
