import 'package:auvoryn/app/app.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/core/settings/room_settings_store.dart';
import 'package:flutter/foundation.dart';
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

  runApp(
    ProviderScope(
      overrides: [
        initialRoomSettingsProvider.overrideWithValue(initialSettings),
        roomSettingsStoreProvider.overrideWithValue(store),
      ],
      child: const AuvorynApp(),
    ),
  );
}
