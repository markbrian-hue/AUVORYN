import 'dart:convert';

import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores lightweight settings, not critical music or user-library data.
/// One JSON key prevents partially written groups of preferences.
class RoomSettingsStore {
  RoomSettingsStore(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _key = 'auvoryn.room_settings.v1';

  Future<RoomSettings> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const RoomSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const RoomSettings();
      return RoomSettings.fromMap(decoded);
    } on FormatException {
      return const RoomSettings();
    }
  }

  Future<void> save(RoomSettings value) async {
    await _preferences.setString(_key, jsonEncode(value.toMap()));
  }
}
