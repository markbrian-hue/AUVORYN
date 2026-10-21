import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ambient;
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ambienceProvider = NotifierProvider<AmbienceController, AmbienceStatus>(
  AmbienceController.new,
);

class AmbienceStatus {
  const AmbienceStatus({this.active = false, this.busy = false, this.error});

  final bool active;
  final bool busy;
  final String? error;
}

/// An *independent* soundscape player. just_audio_background is single-player,
/// so using a second just_audio instance would hijack its media notification.
/// audioplayers uses a separate native backend with audio focus disabled.
class AmbienceController extends Notifier<AmbienceStatus> {
  ambient.AudioPlayer? _player;
  String? _asset;
  bool _disposed = false;
  Future<void> _serial = Future<void>.value();

  @override
  AmbienceStatus build() {
    ref.onDispose(() {
      _disposed = true;
      final player = _player;
      _player = null;
      if (player != null) unawaited(player.dispose());
    });
    return const AmbienceStatus();
  }

  /// Serialize preset changes and enable/disable toggles to prevent race
  /// conditions while native setSource and stop calls are in progress.
  Future<void> sync(RoomSettings settings) {
    final next = _serial.catchError((Object _) {}).then((_) => _apply(settings));
    _serial = next;
    return next;
  }

  Future<void> _apply(RoomSettings settings) async {
    if (_disposed) return;
    try {
      if (!settings.ambienceEnabled) {
        if (_player != null) await _player!.stop();
        _asset = null;
        if (!_disposed) state = const AmbienceStatus();
        return;
      }
      final asset = settings.mood.ambienceAsset;
      // No plugin or native player is created until a user enables ambience.
      if (_player == null) {
        state = const AmbienceStatus(busy: true);
        final player = ambient.AudioPlayer();
        _player = player;
        final context = ambient.AudioContextConfig(
          focus: ambient.AudioContextConfigFocus.mixWithOthers,
          stayAwake: true,
        ).build();
        await player.setAudioContext(context);
        await player.setReleaseMode(ambient.ReleaseMode.loop);
      }
      if (_disposed) return;
      final player = _player!;
      if (_asset != asset) {
        state = const AmbienceStatus(busy: true);
        await player.stop();
        await player.play(
          ambient.AssetSource(asset),
          volume: settings.ambienceVolume,
        );
        _asset = asset;
      } else {
        await player.setVolume(settings.ambienceVolume);
      }
      if (!_disposed) state = const AmbienceStatus(active: true);
    } catch (error) {
      _asset = null;
      if (!_disposed) {
        state = AmbienceStatus(error: 'Unable to play offline ambience: $error');
      }
    }
  }
}
