import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/entities.dart';
import '../../../core/time/time_source.dart';
import '../../../data/local/daos/sessions_dao.dart';
import '../data/sessions_repository.dart';
import '../domain/session_timer.dart';

/// Owns the active [SessionTimer] and exposes a reactive [SessionState]
/// stream via a Riverpod [StreamProvider]. Also handles persistence:
/// every state transition writes to Drift via [SessionsDao] and pushes
/// through the network in the background.
class SessionsController extends Notifier<SessionState?> {
  late final SessionsRepository _repo;
  late final SessionsDao _dao;
  late final TimeSource _clock;
  SessionTimer? _timer;
  StreamSubscription<SessionState>? _sub;

  @override
  SessionState? build() {
    _repo = ref.read(sessionsRepositoryProvider);
    _dao = ref.read(sessionsDaoProvider);
    _clock = ref.read(timeSourceProvider);
    return null;
  }

  void _ensureTimer() {
    if (_timer != null) return;
    _timer = SessionTimer(
      clock: _clock,
      onChange: (s) {
        state = s;
        _persist(s);
      },
    );
    _sub = _timer!.stream.listen((s) => state = s);
  }

  Future<void> start({
    required String subjectId,
    required int plannedDurationSeconds,
    String? topic,
    String? goalText,
  }) async {
    _ensureTimer();
    final startedAt = _clock.now();
    final userId = await _userId();
    // Persist locally FIRST so we never lose the session, even if the
    // network is down.
    final local = await _dao.create(
      userId: userId,
      subjectId: subjectId,
      plannedDurationSeconds: plannedDurationSeconds,
      startedAt: startedAt,
      topic: topic,
      goalText: goalText,
      clock: _clock,
    );
    _timer!.start(
      sessionId: local.id,
      plannedDurationSeconds: plannedDurationSeconds,
      now: startedAt,
      goalText: goalText,
    );
    // Reflect goalText on the in-memory timer state.
    state = _timer!.state!.copyWith(goalText: goalText);

    // Best-effort network push; if it fails, the outbox queue handles retry.
    unawaited(_safePush(() => _repo.create(
          id: local.id,
          subjectId: subjectId,
          plannedDurationSeconds: plannedDurationSeconds,
          startedAt: startedAt,
          topic: topic,
          goalText: goalText,
        )));
  }

  void pause() {
    _timer?.pause(now: _clock.now());
  }

  void resume() {
    _timer?.resume(now: _clock.now());
  }

  Future<SessionState?> complete() async {
    final s = _timer?.complete(now: _clock.now());
    if (s == null) return null;
    await _dao.complete(
      s.sessionId,
      endedAt: s.endedAt!,
      actualDurationSeconds: s.elapsedSecondsAt(_clock.now()),
      pausedIntervalsSeconds: s.pausedIntervalsSeconds,
    );
    unawaited(_safePush(() => _repo.complete(
          s.sessionId,
          actualDurationSeconds: s.elapsedSecondsAt(_clock.now()),
          pausedIntervalsSeconds: s.pausedIntervalsSeconds,
          endedAt: s.endedAt!,
        )));
    return s;
  }

  Future<SessionState?> cancel() async {
    final s = _timer?.cancel(now: _clock.now());
    if (s == null) return null;
    await _dao.cancel(s.sessionId);
    unawaited(_safePush(() => _repo.cancel(s.sessionId)));
    return s;
  }

  Future<void> _persist(SessionState s) async {
    await _dao.patchState(
      s.sessionId,
      state: s.status.name,
      pausedIntervalsSeconds: s.pausedIntervalsSeconds,
      endedAt: s.endedAt,
    );
    if (s.status == SessionStatus.running) {
      unawaited(_safePush(() => _repo.patch(s.sessionId, state: 'running')));
    } else if (s.status == SessionStatus.paused) {
      unawaited(_safePush(() => _repo.patch(
            s.sessionId,
            state: 'paused',
            pausedIntervalsSeconds: s.pausedIntervalsSeconds,
          )));
    }
  }

  Future<String> _userId() async {
    final t = ref.read(tokenStorageProvider);
    final id = await t.readUserId();
    if (id == null) throw StateError('No logged-in user');
    return id;
  }

  Future<void> _safePush(Future<Object?> Function() op) async {
    try {
      await op();
    } catch (_) {
      // Sync service retries from the outbox on next tick.
    }
  }
}

final sessionsControllerProvider =
    NotifierProvider<SessionsController, SessionState?>(
  SessionsController.new,
);

/// Read-only provider for completed session history. Backs the History tab.
final sessionsHistoryProvider =
    FutureProvider.family<List<SessionEntity>, int>((ref, limit) async {
  return ref.read(sessionsRepositoryProvider).list(limit: limit);
});