import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final initialRoomSettingsProvider = Provider<RoomSettings>(
  (ref) => const RoomSettings(),
);

final roomSettingsStoreProvider = Provider<RoomSettingsStore>(
  (ref) => RoomSettingsStore(SharedPreferencesAsync()),
);

final roomSettingsProvider =
    NotifierProvider<RoomSettingsController, RoomSettings>(
  RoomSettingsController.new,
);

class RoomSettingsController extends Notifier<RoomSettings> {
  Future<void> _writeQueue = Future<void>.value();

  @override
  RoomSettings build() => ref.read(initialRoomSettingsProvider);

  Future<bool> setMood(RoomMood mood) => _update(state.copyWith(mood: mood));

  Future<bool> setLamp(bool value) => _update(state.copyWith(lampOn: value));

  Future<bool> setReducedMotion(bool value) =>
      _update(state.copyWith(reducedMotion: value));

  Future<bool> _update(RoomSettings next) async {
    final previous = state;
    state = next;
    // Serialize writes so rapid taps cannot persist an older state last.
    final save = _writeQueue.then(
      (_) => ref.read(roomSettingsStoreProvider).save(next),
    );
    _writeQueue = save.catchError((Object _) {});
    try {
      await save;
      return true;
    } catch (_) {
      // Only roll back if a more recent interaction has not superseded it.
      if (identical(state, next)) state = previous;
      return false;
    }
  }
}
