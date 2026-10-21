import 'dart:async';

import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/features/scenes/data/listening_scene_store.dart';
import 'package:auvoryn/features/scenes/domain/listening_scene.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final listeningSceneRepositoryProvider = Provider<ListeningSceneRepository>(
  (ref) => ListeningSceneStore(SharedPreferencesAsync()),
);

final listeningScenesProvider =
    NotifierProvider<ListeningScenesController, ListeningScenesState>(
  ListeningScenesController.new,
);

class ListeningScenesState {
  const ListeningScenesState({
    this.saved = const [],
    this.loading = true,
    this.saving = false,
    this.error,
  });

  final List<ListeningScene> saved;
  final bool loading;
  final bool saving;
  final String? error;

  ListeningScenesState copyWith({
    List<ListeningScene>? saved,
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
  }) => ListeningScenesState(
        saved: saved ?? this.saved,
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        error: clearError ? null : error ?? this.error,
      );
}

class ListeningScenesController extends Notifier<ListeningScenesState> {
  Future<void> _writes = Future<void>.value();
  bool _disposed = false;
  static const _uuid = Uuid();

  @override
  ListeningScenesState build() {
    ref.onDispose(() => _disposed = true);
    unawaited(Future<void>.microtask(_load));
    return const ListeningScenesState();
  }

  Future<void> _load() async {
    try {
      final scenes = await ref.read(listeningSceneRepositoryProvider).load();
      if (!_disposed) state = ListeningScenesState(saved: scenes, loading: false);
    } catch (error) {
      if (!_disposed) {
        // Fail closed: do not overwrite damaged stored data with empty scenes.
        state = ListeningScenesState(
          loading: false,
          error: 'Unable to read your saved scenes: $error',
        );
      }
    }
  }

  Future<bool> _commit(List<ListeningScene> scenes) async {
    if (state.loading || state.error != null || state.saving) return false;
    state = state.copyWith(saving: true, clearError: true);
    try {
      final operation = _writes.then(
        (_) => ref.read(listeningSceneRepositoryProvider).save(scenes),
      );
      _writes = operation.catchError((Object _) {});
      await operation;
      if (_disposed) return false;
      state = ListeningScenesState(saved: scenes, loading: false);
      return true;
    } catch (error) {
      if (!_disposed) {
        state = state.copyWith(saving: false, error: 'Could not save scene: $error');
      }
      return false;
    }
  }

  Future<bool> create(String name, {String? playlistId}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 60) return Future.value(false);
    final snapshot = ref.read(roomSettingsProvider);
    return _commit([
      ...state.saved,
      ListeningScene(
        id: _uuid.v4(),
        name: trimmed,
        room: snapshot,
        playlistId: playlistId,
      ),
    ]);
  }

  Future<bool> renameAndLink(
    ListeningScene scene,
    String name, {
    String? playlistId,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 60) return Future.value(false);
    if (!state.saved.any((s) => s.id == scene.id)) return Future.value(false);
    return _commit([
      for (final saved in state.saved)
        if (saved.id == scene.id)
          saved.copyWith(name: trimmed, playlistId: playlistId,
            clearPlaylist: playlistId == null)
        else saved,
    ]);
  }

  /// Capture current room values into a saved scene, without changing music.
  Future<bool> updateFromRoom(ListeningScene scene) {
    if (!state.saved.any((s) => s.id == scene.id)) return Future.value(false);
    final current = ref.read(roomSettingsProvider);
    return _commit([
      for (final saved in state.saved)
        if (saved.id == scene.id) saved.copyWith(room: current) else saved,
    ]);
  }

  Future<bool> duplicate(ListeningScene scene) => _commit([
        ...state.saved,
        scene.copyWith(
          id: _uuid.v4(),
          name: '${scene.name} copy',
          starter: false,
        ),
      ]);

  Future<bool> delete(ListeningScene scene) => _commit([
        for (final saved in state.saved)
          if (saved.id != scene.id) saved,
      ]);

  /// Room state is written once and visuals transition using the existing
  /// animated scene. The music player's queue and play/pause state are untouched.
  Future<bool> apply(ListeningScene scene) async {
    final current = ref.read(roomSettingsProvider);
    return ref.read(roomSettingsProvider.notifier).applySceneSettings(
      scene.applyTo(current),
    );
  }
}
