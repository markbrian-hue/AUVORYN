import 'dart:async';

import 'package:auvoryn/features/atmosphere/application/ambience_controller.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:auvoryn/features/sessions/data/session_store.dart';
import 'package:auvoryn/features/sessions/domain/listening_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionStore(SharedPreferencesAsync()),
);

abstract class SessionAudioDriver {
  Future<void> fadeAndPause({required bool fade});
}

/// Works with the existing music and ambience players; never creates another
/// audio player or changes user volume preferences.
class _RealSessionAudioDriver implements SessionAudioDriver {
  _RealSessionAudioDriver(this.ref);
  final Ref ref;
  @override
  Future<void> fadeAndPause({required bool fade}) async {
    await Future.wait([
      ref.read(musicProvider.notifier).pauseForSleep(fade: fade),
      ref.read(ambienceProvider.notifier).stopForSleep(fade: fade),
    ]);
  }
}

final sessionAudioDriverProvider = Provider<SessionAudioDriver>(
  (ref) => _RealSessionAudioDriver(ref),
);
final listeningSessionProvider =
    NotifierProvider<ListeningSessionController, SessionStatus>(
  ListeningSessionController.new,
);

class SessionStatus {
  const SessionStatus({
    this.active,
    this.restoring = true,
    this.busy = false,
    this.remainingMs = 0,
    this.error,
  });

  final ListeningSession? active;
  final bool restoring;
  final bool busy;
  final int remainingMs;
  final String? error;
}

class _SessionLifecycle extends WidgetsBindingObserver {
  _SessionLifecycle(this.resumed);
  final VoidCallback resumed;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) resumed();
  }
}

class ListeningSessionController extends Notifier<SessionStatus> {
  Timer? _ticker;
  late final _SessionLifecycle _observer;
  bool _disposed = false;
  bool _completing = false;
  Future<void> _writes = Future<void>.value();

  @override
  SessionStatus build() {
    _observer = _SessionLifecycle(_tick);
    WidgetsBinding.instance.addObserver(_observer);
    ref.onDispose(() {
      _disposed = true;
      _ticker?.cancel();
      WidgetsBinding.instance.removeObserver(_observer);
    });
    unawaited(Future<void>.microtask(_restore));
    return const SessionStatus();
  }

  int get _now => DateTime.now().millisecondsSinceEpoch;

  Future<void> _restore() async {
    try {
      final saved = await ref.read(sessionRepositoryProvider).load();
      if (_disposed) {
        return;
      }
      state = SessionStatus(
        active: saved, restoring: false,
        remainingMs: saved?.remainingMs(_now) ?? 0,
      );
      if (saved != null) {
        _startTicker();
        _tick();
      }
    } catch (error) {
      if (!_disposed) {
        state = SessionStatus(
        restoring: false, error: 'Could not restore session: $error');
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _persist(ListeningSession? session) {
    final operation = _writes.catchError((Object _) {}).then(
      (_) => ref.read(sessionRepositoryProvider).save(session));
    _writes = operation.catchError((Object _) {});
    return operation;
  }

  Future<bool> start({
    required SessionKind kind,
    required Duration duration,
    required SessionEndBehavior endBehavior,
    String? sceneId,
  }) async {
    if (state.restoring || state.active != null || state.busy ||
        state.error != null || duration.inMinutes < 1 ||
        duration.inMinutes > 240) {
      return false;
    }
    final now = _now;
    final session = ListeningSession(
      id: const Uuid().v4(),
      kind: kind,
      durationMs: duration.inMilliseconds,
      endBehavior: endBehavior,
      deadlineMs: now + duration.inMilliseconds,
      remainingOnPauseMs: duration.inMilliseconds,
      sceneId: sceneId,
    );
    state = SessionStatus(busy: true, restoring: false);
    try {
      await _persist(session);
      if (_disposed) {
        return false;
      }
      state = SessionStatus(active: session, restoring: false,
          remainingMs: duration.inMilliseconds);
      _startTicker();
      return true;
    } catch (error) {
      if (!_disposed) {
        state = SessionStatus(restoring: false,
          error: 'Could not start session: $error');
      }
      return false;
    }
  }

  Future<bool> togglePause() async {
    final old = state.active;
    if (old == null || state.busy) {
      return false;
    }
    final next = old.paused ? old.resume(_now) : old.pause(_now);
    state = SessionStatus(active: old, restoring: false, busy: true,
        remainingMs: old.remainingMs(_now));
    try {
      await _persist(next);
      if (_disposed) {
        return false;
      }
      state = SessionStatus(active: next, restoring: false,
          remainingMs: next.remainingMs(_now));
      _tick();
      return true;
    } catch (error) {
      if (!_disposed) {
        state = SessionStatus(active: old, restoring: false,
          remainingMs: old.remainingMs(_now),
          error: 'Unable to update session: $error');
      }
      return false;
    }
  }

  Future<bool> cancel() async {
    final old = state.active;
    if (old == null || state.busy) return false;
    state = SessionStatus(active: old, restoring: false, busy: true);
    try {
      await _persist(null);
      if (_disposed) {
        return false;
      }
      _ticker?.cancel();
      state = const SessionStatus(restoring: false);
      // Cancel is intentionally NOT a command to pause or start music.
      return true;
    } catch (error) {
      if (!_disposed) {
        state = SessionStatus(active: old, restoring: false,
          remainingMs: old.remainingMs(_now),
          error: 'Unable to cancel session: $error');
      }
      return false;
    }
  }

  void _tick() {
    if (_disposed || state.busy || state.restoring || _completing) {
      return;
    }
    final session = state.active;
    if (session == null) {
      return;
    }
    final remaining = session.remainingMs(_now);
    if (remaining <= 0 && !session.paused) {
      unawaited(_complete(session));
    } else if (remaining != state.remainingMs) {
      state = SessionStatus(active: session, restoring: false,
          remainingMs: remaining);
    }
  }

  Future<void> _complete(ListeningSession session) async {
    if (_completing) {
      return;
    }
    _completing = true;
    _ticker?.cancel();
    // A restored, long-expired deadline pauses immediately; a live deadline
    // fades gently. Never resumes audio during restoration.
    final missedByMs = (_now - session.deadlineMs).clamp(0, 86400000);
    state = const SessionStatus(restoring: false, busy: true);
    try {
      if (session.endBehavior == SessionEndBehavior.fadeAndPause) {
        await ref.read(sessionAudioDriverProvider).fadeAndPause(
          fade: missedByMs < 3000,
        );
      }
      // Keep the expired deadline durable until the audio action finishes.
      // If the process dies during the fade, restoration can retry the stop
      // instead of losing the session before playback was silenced.
      await _persist(null);
      if (!_disposed) state = const SessionStatus(restoring: false);
    } catch (error) {
      if (!_disposed) {
        state = SessionStatus(restoring: false,
            error: 'Session finished, but audio or storage needs attention: $error');
      }
    } finally {
      _completing = false;
    }
  }
}
