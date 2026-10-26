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

  /// Applies an entire listening scene as one settings write. Accessibility
  /// preferences remain outside scene ownership and are never overwritten.
  Future<bool> applySceneSettings(RoomSettings next) => _update(
    state.copyWith(
      mood: next.mood,
      windowView: next.windowView,
      lampOn: next.lampOn,
      lampPalette: next.lampPalette,
      lampBrightness: next.lampBrightness,
      ambienceEnabled: next.ambienceEnabled,
      ambienceVolume: next.ambienceVolume,
      musicVolume: next.musicVolume,
    ),
  );

  Future<bool> setWindowView(WindowView view) =>
    _update(state.copyWith(windowView: view));

  Future<bool> setReducedMotion(bool value) =>
      _update(state.copyWith(reducedMotion: value));

  Future<bool> setAmbienceEnabled(bool enabled) =>
      _update(state.copyWith(ambienceEnabled: enabled));

  Future<bool> setLampPalette(LampPalette palette) =>
      _update(state.copyWith(lampPalette: palette));

  /// Preview changes are reflected in the audio immediately, while persistence
  /// occurs when the gesture ends. This avoids dozens of flash/disk writes.
  Future<bool> setAmbienceVolume(double value, {bool persist = true}) =>
      _update(state.copyWith(ambienceVolume: value), persist: persist);

  Future<bool> setMusicVolume(double value, {bool persist = true}) =>
      _update(state.copyWith(musicVolume: value), persist: persist);

  Future<bool> setLampBrightness(double value, {bool persist = true}) =>
      _update(state.copyWith(lampBrightness: value), persist: persist);

  Future<bool> _update(RoomSettings next, {bool persist = true}) async {
    final previous = state;
    state = next;
    if (!persist) return true;

    // Serialize writes so rapid taps cannot persist an older state last.
    final save = _writeQueue.then(
      (_) => ref.read(roomSettingsStoreProvider).save(next),
    );
    _writeQueue = save.catchError((Object _) {});
    try {
      await save;
      return true;
    } catch (_) {
      if (identical(state, next)) state = previous;
      return false;
    }
  }
}
