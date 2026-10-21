enum SessionKind { focus, sleep }
enum SessionEndBehavior { keepPlaying, fadeAndPause }

/// Persisted absolute deadline allows correct countdowns after backgrounding.
class ListeningSession {
  const ListeningSession({
    required this.id,
    required this.kind,
    required this.durationMs,
    required this.endBehavior,
    required this.deadlineMs,
    required this.remainingOnPauseMs,
    this.sceneId,
    this.paused = false,
  });

  final String id;
  final SessionKind kind;
  final int durationMs;
  final SessionEndBehavior endBehavior;
  final int deadlineMs;
  final int remainingOnPauseMs;
  final String? sceneId;
  final bool paused;

  int remainingMs(int nowMs) =>
      paused ? remainingOnPauseMs : (deadlineMs - nowMs).clamp(0, durationMs);

  ListeningSession pause(int nowMs) => copyWith(
        paused: true,
        remainingOnPauseMs: remainingMs(nowMs),
      );

  ListeningSession resume(int nowMs) => copyWith(
        paused: false,
        deadlineMs: nowMs + remainingOnPauseMs,
      );

  ListeningSession copyWith({
    bool? paused,
    int? deadlineMs,
    int? remainingOnPauseMs,
  }) => ListeningSession(
        id: id,
        kind: kind,
        durationMs: durationMs,
        endBehavior: endBehavior,
        deadlineMs: deadlineMs ?? this.deadlineMs,
        remainingOnPauseMs: remainingOnPauseMs ?? this.remainingOnPauseMs,
        sceneId: sceneId,
        paused: paused ?? this.paused,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'durationMs': durationMs,
        'endBehavior': endBehavior.name,
        'deadlineMs': deadlineMs,
        'remainingOnPauseMs': remainingOnPauseMs,
        'sceneId': sceneId,
        'paused': paused,
      };

  factory ListeningSession.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final duration = json['durationMs'];
    final deadline = json['deadlineMs'];
    final remaining = json['remainingOnPauseMs'];
    if (id is! String || id.isEmpty || duration is! int ||
        duration < 60000 || duration > 14400000 ||
        deadline is! int || remaining is! int ||
        remaining < 0 || remaining > duration) {
      throw const FormatException('Invalid saved session.');
    }
    return ListeningSession(
      id: id,
      kind: SessionKind.values.firstWhere(
        (v) => v.name == json['kind'], orElse: () => SessionKind.focus),
      durationMs: duration,
      endBehavior: SessionEndBehavior.values.firstWhere(
        (v) => v.name == json['endBehavior'],
        orElse: () => SessionEndBehavior.keepPlaying),
      deadlineMs: deadline,
      remainingOnPauseMs: remaining,
      sceneId: json['sceneId'] is String ? json['sceneId'] as String : null,
      paused: json['paused'] == true,
    );
  }
}
