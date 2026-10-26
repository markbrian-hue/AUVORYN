import 'dart:async';

import 'package:auvoryn/features/companion/data/room_companion_store.dart';
import 'package:auvoryn/features/companion/domain/room_companion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final roomCompanionRepositoryProvider = Provider<RoomCompanionRepository>(
  (ref) => RoomCompanionStore(SharedPreferencesAsync()),
);

final roomCompanionProvider =
    NotifierProvider<RoomCompanionController, RoomCompanionStatus>(
      RoomCompanionController.new,
    );

class RoomCompanionStatus {
  const RoomCompanionStatus({
    this.companion = const RoomCompanion(),
    this.loading = true,
    this.saving = false,
    this.readFailed = false,
    this.error,
  });

  final RoomCompanion companion;
  final bool loading;
  final bool saving;
  final bool readFailed;
  final String? error;
}

class RoomCompanionController extends Notifier<RoomCompanionStatus> {
  Future<void> _writes = Future<void>.value();
  bool _disposed = false;

  @override
  RoomCompanionStatus build() {
    ref.onDispose(() => _disposed = true);
    unawaited(Future<void>.microtask(_restore));
    return const RoomCompanionStatus();
  }

  Future<void> _restore() async {
    try {
      final saved = await ref.read(roomCompanionRepositoryProvider).load();
      if (!_disposed) {
        state = RoomCompanionStatus(companion: saved, loading: false);
      }
    } catch (error) {
      if (!_disposed) {
        // Preserve corrupted or future-version data: never save over it.
        state = RoomCompanionStatus(
          loading: false,
          readFailed: true,
          error: 'Unable to read your companion settings: $error',
        );
      }
    }
  }

  Future<bool> _change(RoomCompanion Function(RoomCompanion) transform) async {
    if (_disposed || state.loading || state.readFailed || state.saving) {
      return false;
    }
    final before = state.companion;
    final next = transform(before);
    state = RoomCompanionStatus(companion: before, loading: false, saving: true);
    try {
      final operation = _writes.then(
        (_) => ref.read(roomCompanionRepositoryProvider).save(next),
      );
      _writes = operation.catchError((Object _) {});
      await operation;
      if (_disposed) return false;
      state = RoomCompanionStatus(companion: next, loading: false);
      return true;
    } catch (error) {
      if (!_disposed) {
        state = RoomCompanionStatus(
          companion: before,
          loading: false,
          error: 'Could not save companion: $error',
        );
      }
      return false;
    }
  }

  Future<bool> setVisible(bool value) =>
      _change((before) => before.copyWith(visible: value));

  Future<bool> setStyle(CompanionStyle style) =>
      _change((before) => RoomCompanion.forStyle(
        style,
        skin: before.skin,
        pose: before.pose,
      ).copyWith(visible: before.visible));

  Future<bool> setPose(CompanionPose pose) =>
      _change((before) => before.copyWith(pose: pose));

  Future<bool> setHair(CompanionHair hair) =>
      _change((before) => before.copyWith(hair: hair));

  Future<bool> setSkin(CompanionSkin skin) =>
      _change((before) => before.copyWith(skin: skin));

  Future<bool> setOutfit(CompanionOutfit outfit) =>
      _change((before) => before.copyWith(outfit: outfit));
}
