import 'dart:convert';

import 'package:auvoryn/features/companion/domain/room_companion.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class RoomCompanionRepository {
  Future<RoomCompanion> load();
  Future<void> save(RoomCompanion companion);
}

/// Separate versioned preference. Never migrates the music SQLite database.
class RoomCompanionStore implements RoomCompanionRepository {
  RoomCompanionStore(this.preferences);

  final SharedPreferencesAsync preferences;
  static const key = 'auvoryn.room_companion.v1';

  @override
  Future<RoomCompanion> load() async {
    final raw = await preferences.getString(key);
    if (raw == null) return const RoomCompanion();
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid saved companion.');
    }
    return RoomCompanion.fromJson(Map<String, dynamic>.from(decoded));
  }

  @override
  Future<void> save(RoomCompanion companion) =>
      preferences.setString(key, jsonEncode(companion.toJson()));
}
