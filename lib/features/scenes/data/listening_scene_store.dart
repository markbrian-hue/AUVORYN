import 'dart:convert';

import 'package:auvoryn/features/scenes/domain/listening_scene.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ListeningSceneRepository {
  Future<List<ListeningScene>> load();
  Future<void> save(List<ListeningScene> scenes);
}

/// Separate versioned key: legacy room/music data and its SQLite schema are
/// never reset, migrated or overwritten by listening-scene storage.
class ListeningSceneStore implements ListeningSceneRepository {
  ListeningSceneStore(this.preferences);

  final SharedPreferencesAsync preferences;
  static const key = 'auvoryn.listening_scenes.v1';

  @override
  Future<List<ListeningScene>> load() async {
    final stored = await preferences.getString(key);
    if (stored == null) return const [];
    final decoded = jsonDecode(stored);
    if (decoded is! List) throw const FormatException('Invalid scenes data.');
    final scenes = <ListeningScene>[];
    for (final value in decoded) {
      if (value is! Map) {
        throw const FormatException('Invalid scenes data.');
      }
      scenes.add(ListeningScene.fromJson(Map<String, dynamic>.from(value)));
    }
    return scenes;
  }

  @override
  Future<void> save(List<ListeningScene> scenes) =>
      preferences.setString(
        key,
        jsonEncode(scenes.map((scene) => scene.toJson()).toList()),
      );
}
