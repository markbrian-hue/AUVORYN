/// Counts only progress from the real player, not elapsed wall-clock time.
class ListeningCheckpoint {
  const ListeningCheckpoint(this.songId, this.listenedMs, this.qualifiedPlay);
  final String songId;
  final int listenedMs;
  final bool qualifiedPlay;
}

class ListeningTracker {
  ListeningTracker(this.onCheckpoint);
  final void Function(ListeningCheckpoint) onCheckpoint;
  String? _song;
  int? _position, _at;
  int _session = 0, _pending = 0;
  bool _qualified = false, _pendingQualified = false;
  void sample({
    required String? songId,
    required int positionMs,
    required int nowMs,
    required bool playing,
    required bool ready,
  }) {
    if (_song != songId) {
      flush();
      _song = songId;
      _session = 0;
      _qualified = false;
      _position = null;
      _at = null;
    }
    if (songId == null || !playing || !ready) {
      flush();
      _position = null;
      _at = null;
      return;
    }
    final oldPosition = _position, oldTime = _at;
    _position = positionMs;
    _at = nowMs;
    if (oldPosition == null || oldTime == null) {
      return;
    }
    final delta = positionMs - oldPosition, elapsed = nowMs - oldTime;
    if (delta < -250) {
      flush();
      _session = 0;
      _qualified = false;
      return;
    }
    if (delta <= 0 || elapsed <= 0 || delta > elapsed + 1200) {
      return;
    }
    final credited = delta.clamp(0, elapsed + 200).toInt();
    _session += credited;
    _pending += credited;
    if (!_qualified && _session >= 10000) {
      _qualified = true;
      _pendingQualified = true;
    }
    if (_pending >= 5000 || _pendingQualified) {
      flush();
    }
  }

  void flush() {
    if (_song != null && (_pending > 0 || _pendingQualified)) {
      onCheckpoint(ListeningCheckpoint(_song!, _pending, _pendingQualified));
      _pending = 0;
      _pendingQualified = false;
    }
  }

  /// Explicit seeks must not be mistaken for short intervals of listening.
  /// Preserve the session's earned play qualification, but rebase progress.
  void discontinuity() {
    flush();
    _position = null;
    _at = null;
  }

  void reset() {
    _song = null;
    _position = null;
    _at = null;
    _session = 0;
    _pending = 0;
    _qualified = false;
    _pendingQualified = false;
  }
}
