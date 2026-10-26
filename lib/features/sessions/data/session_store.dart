import 'dart:convert';

import 'package:auvoryn/features/sessions/domain/listening_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SessionRepository {
  Future<ListeningSession?> load();
  Future<void> save(ListeningSession? session);
}

class SessionStore implements SessionRepository {
  SessionStore(this.preferences);
  final SharedPreferencesAsync preferences;
  static const key = 'auvoryn.listening_session.v1';

  @override
  Future<ListeningSession?> load() async {
    final raw = await preferences.getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('Invalid session data.');
    return ListeningSession.fromJson(Map<String, dynamic>.from(decoded));
  }

  @override
  Future<void> save(ListeningSession? session) async {
    if (session == null) {
      await preferences.remove(key);
    } else {
      await preferences.setString(key, jsonEncode(session.toJson()));
    }
  }
}
