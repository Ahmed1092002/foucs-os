import 'dart:async';

import '../../../core/time/time_source.dart';

/// State of an in-flight study session. See docs/14-business-rules.md R-S2/R-S3.
enum SessionStatus { idle, running, paused, completed, cancelled }

/// Immutable snapshot consumed by the UI.
///
/// `elapsedSecondsAt(now)` is **derived**, not stored. The wall clock is
/// consulted on every read. This is the single rule the whole product's
/// credibility rides on — see docs/14-business-rules.md → R-S2, R-S3.
class SessionState {
  final String sessionId;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int pausedIntervalsSeconds;
  final int plannedDurationSeconds;
  final String? goalText;

  /// Non-null only while paused; tracks when the current pause started so
  /// `elapsedSecondsAt` can freeze the displayed value while paused.
  final DateTime? pausedSince;

  const SessionState({
    required this.sessionId,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    required this.pausedIntervalsSeconds,
    required this.plannedDurationSeconds,
    this.goalText,
    this.pausedSince,
  });

  /// Elapsed seconds, excluding paused intervals.
  int elapsedSecondsAt(DateTime now) {
    switch (status) {
      case SessionStatus.idle:
        return 0;
      case SessionStatus.running:
      case SessionStatus.paused:
        final end = status == SessionStatus.paused
            ? (pausedSince ?? now)
            : now;
        return ((end.difference(startedAt).inMilliseconds ~/ 1000) -
                pausedIntervalsSeconds)
            .clamp(0, 1 << 30);
      case SessionStatus.completed:
      case SessionStatus.cancelled:
        if (endedAt == null) return 0;
        return ((endedAt!.difference(startedAt).inMilliseconds ~/ 1000) -
                pausedIntervalsSeconds)
            .clamp(0, 1 << 30);
    }
  }

  SessionState copyWith({
    SessionStatus? status,
    DateTime? endedAt,
    int? pausedIntervalsSeconds,
    DateTime? pausedSince,
    String? goalText,
  }) {
    return SessionState(
      sessionId: sessionId,
      status: status ?? this.status,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      pausedIntervalsSeconds:
          pausedIntervalsSeconds ?? this.pausedIntervalsSeconds,
      plannedDurationSeconds: plannedDurationSeconds,
      goalText: goalText ?? this.goalText,
      pausedSince: pausedSince ?? this.pausedSince,
    );
  }
}

/// The timer. One instance per active session.
///
/// Behavior contract (exhaustive):
/// - start() → running, startedAt = now
/// - pause() while running → paused, pausedSince = now
/// - resume() while paused → running, pausedIntervals += (now − pausedSince)
/// - complete() from running OR paused → completed, endedAt = now,
///   actualDurationSeconds computed from timestamps
/// - cancel() from any non-terminal state → cancelled, endedAt = now
/// - calling start/pause/resume/complete/cancel in the wrong state is a no-op
///   and logs (we don't throw — UI code can call defensively)
///
/// This class NEVER increments a counter. The UI's tick is purely cosmetic
/// and re-derives from elapsedSecondsAt() each frame.
class SessionTimer {
  SessionTimer({
    required TimeSource clock,
    void Function(SessionState)? onChange,
  })  : _clock = clock,
        _onChange = onChange;

  final TimeSource _clock;
  final void Function(SessionState)? _onChange;
  final _controller = StreamController<SessionState>.broadcast();

  SessionState? _state;
  SessionState? get state => _state;
  Stream<SessionState> get stream => _controller.stream;

  void _emit(SessionState? s) {
    if (s != null) {
      _state = s;
      _controller.add(s);
      _onChange?.call(s);
    } else {
      _state = null;
    }
  }

  void dispose() => _controller.close();

  /// Start a fresh session.
  void start({
    required String sessionId,
    required int plannedDurationSeconds,
    DateTime? now,
    String? goalText,
  }) {
    if (_state != null && _state!.status != SessionStatus.idle) {
      _log('start ignored: timer is ${_state!.status}');
      return;
    }
    final t = now ?? _clock.now();
    _emit(SessionState(
      sessionId: sessionId,
      status: SessionStatus.running,
      startedAt: t,
      endedAt: null,
      pausedIntervalsSeconds: 0,
      plannedDurationSeconds: plannedDurationSeconds,
      goalText: goalText,
    ));
  }

  void pause({DateTime? now}) {
    final s = _state;
    if (s == null || s.status != SessionStatus.running) {
      _log('pause ignored: not running');
      return;
    }
    final t = now ?? _clock.now();
    _emit(s.copyWith(status: SessionStatus.paused, pausedSince: t));
  }

  void resume({DateTime? now}) {
    final s = _state;
    if (s == null || s.status != SessionStatus.paused) {
      _log('resume ignored: not paused');
      return;
    }
    final t = now ?? _clock.now();
    final pausedSince = s.pausedSince;
    if (pausedSince == null) {
      // Defensive: treat missing pause-start as zero-length pause.
      _emit(s.copyWith(status: SessionStatus.running, pausedSince: null));
      return;
    }
    final additionalPause =
        t.difference(pausedSince).inSeconds.clamp(0, 24 * 60 * 60);
    _emit(s.copyWith(
      status: SessionStatus.running,
      pausedSince: null,
      pausedIntervalsSeconds: s.pausedIntervalsSeconds + additionalPause,
    ));
  }

  /// Compute and return the final [SessionState]. Caller should persist it.
  SessionState? complete({DateTime? now}) {
    final s = _state;
    if (s == null ||
        s.status == SessionStatus.completed ||
        s.status == SessionStatus.cancelled) {
      _log('complete ignored: terminal or no session');
      return _state;
    }
    final t = now ?? _clock.now();
    var pausedIntervals = s.pausedIntervalsSeconds;
    if (s.status == SessionStatus.paused && s.pausedSince != null) {
      pausedIntervals +=
          t.difference(s.pausedSince!).inSeconds.clamp(0, 24 * 60 * 60);
    }
    _emit(s.copyWith(
      status: SessionStatus.completed,
      endedAt: t,
      pausedSince: null,
      pausedIntervalsSeconds: pausedIntervals,
    ));
    return _state;
  }

  SessionState? cancel({DateTime? now}) {
    final s = _state;
    if (s == null ||
        s.status == SessionStatus.completed ||
        s.status == SessionStatus.cancelled) {
      return _state;
    }
    final t = now ?? _clock.now();
    var pausedIntervals = s.pausedIntervalsSeconds;
    if (s.status == SessionStatus.paused && s.pausedSince != null) {
      pausedIntervals +=
          t.difference(s.pausedSince!).inSeconds.clamp(0, 24 * 60 * 60);
    }
    _emit(s.copyWith(
      status: SessionStatus.cancelled,
      endedAt: t,
      pausedSince: null,
      pausedIntervalsSeconds: pausedIntervals,
    ));
    return _state;
  }

  /// Recover an orphaned session after a process kill / OS suspend.
  /// If the orphan has been "running" for [staleAfter] or longer, it's
  /// treated as completed at `startedAt + elapsed`.
  SessionState? recoverOrphan({
    required String sessionId,
    required int plannedDurationSeconds,
    required DateTime orphanStartedAt,
    int orphanPausedSeconds = 0,
    Duration staleAfter = const Duration(hours: 1),
    DateTime? now,
  }) {
    final t = now ?? _clock.now();
    final elapsed = t.difference(orphanStartedAt);
    final stale = elapsed >= staleAfter;
    _emit(SessionState(
      sessionId: sessionId,
      status: stale ? SessionStatus.completed : SessionStatus.running,
      startedAt: orphanStartedAt,
      endedAt: stale ? t : null,
      pausedIntervalsSeconds: orphanPausedSeconds,
      plannedDurationSeconds: plannedDurationSeconds,
    ));
    return _state;
  }

  void _log(String msg) {
    // ignore: avoid_print
    print('[SessionTimer] $msg');
  }
}