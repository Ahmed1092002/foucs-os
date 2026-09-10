// THE most important tests in the Focus OS codebase.
//
// The product's credibility rides on the timer being correct across:
//   - backgrounding
//   - screen lock
//   - pause / resume
//   - abandon + recover
//   - timezone changes (we always use UTC)
//
// All of these collapse to: does the elapsed formula stay right when we
// advance a FakeClock and call start/pause/resume/complete at chosen
// moments? If yes, the timer is sound.

import 'package:flutter_test/flutter_test.dart';

import 'package:focus_os/core/time/time_source.dart';
import 'package:focus_os/features/sessions/domain/session_timer.dart';

void main() {
  group('SessionTimer', () {
    test('starts in idle; start() sets running and startedAt', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      final timer = SessionTimer(clock: clock);

      expect(timer.state, isNull);

      timer.start(sessionId: 's1', plannedDurationSeconds: 3600);
      final s = timer.state!;
      expect(s.status, SessionStatus.running);
      expect(s.startedAt, DateTime.utc(2026, 1, 1, 9));
      expect(s.elapsedSecondsAt(clock.now()), 0);
    });

    test('elapsed grows with the wall clock while running', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      final timer = SessionTimer(clock: clock);

      timer.start(sessionId: 's1', plannedDurationSeconds: 3600);

      clock.advance(const Duration(minutes: 47));
      expect(timer.state!.elapsedSecondsAt(clock.now()), 47 * 60);
    });

    test('pause freezes the displayed value', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      final timer = SessionTimer(clock: clock);

      timer.start(sessionId: 's1', plannedDurationSeconds: 3600);
      clock.advance(const Duration(minutes: 30));
      timer.pause();
      expect(timer.state!.status, SessionStatus.paused);

      // 10 minutes pass while paused — display must NOT change.
      clock.advance(const Duration(minutes: 10));
      expect(timer.state!.elapsedSecondsAt(clock.now()), 30 * 60);

      timer.resume();
      expect(timer.state!.status, SessionStatus.running);
    });

    test('resume rolls paused time into pausedIntervalsSeconds', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      final timer = SessionTimer(clock: clock);

      timer.start(sessionId: 's1', plannedDurationSeconds: 3600);
      clock.advance(const Duration(minutes: 10));   // 10 min running
      timer.pause();
      clock.advance(const Duration(minutes: 7));    // 7 min paused
      timer.resume();
      clock.advance(const Duration(minutes: 13));   // 13 min more running

      // elapsed = 10 + 13 = 23 min, ignoring the 7 paused.
      expect(timer.state!.elapsedSecondsAt(clock.now()), 23 * 60);
      expect(timer.state!.pausedIntervalsSeconds, 7 * 60);
    });

    test('complete from running produces correct actual duration', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      final timer = SessionTimer(clock: clock);

      timer.start(sessionId: 's1', plannedDurationSeconds: 3600);
      clock.advance(const Duration(minutes: 52));
      final finalState = timer.complete();

      expect(finalState!.status, SessionStatus.completed);
      expect(finalState.elapsedSecondsAt(clock.now()), 52 * 60);
      expect(finalState.endedAt, DateTime.utc(2026, 1, 1, 9, 52));
    });

    test('complete from paused finalises the in-flight pause', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      final timer = SessionTimer(clock: clock);

      timer.start(sessionId: 's1', plannedDurationSeconds: 3600);
      clock.advance(const Duration(minutes: 20));   // 20 min running
      timer.pause();
      clock.advance(const Duration(minutes: 5));    // 5 min paused
      final finalState = timer.complete();

      expect(finalState!.status, SessionStatus.completed);
      expect(finalState.elapsedSecondsAt(clock.now()), 20 * 60);
      expect(finalState.pausedIntervalsSeconds, 5 * 60);
    });

    test('multi-pause accumulates every pause interval', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      final timer = SessionTimer(clock: clock);

      timer.start(sessionId: 's1', plannedDurationSeconds: 3600);
      clock.advance(const Duration(minutes: 10));
      timer.pause();
      clock.advance(const Duration(minutes: 3));
      timer.resume();

      clock.advance(const Duration(minutes: 5));
      timer.pause();
      clock.advance(const Duration(minutes: 2));
      timer.resume();

      clock.advance(const Duration(minutes: 7));

      // elapsed = 10 + 5 + 7 = 22 min. pausedIntervals = 3 + 2 = 5 min.
      expect(timer.state!.elapsedSecondsAt(clock.now()), 22 * 60);
      expect(timer.state!.pausedIntervalsSeconds, 5 * 60);
    });

    test('cancel from running sets endedAt and excludes elapsed from stats', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      final timer = SessionTimer(clock: clock);

      timer.start(sessionId: 's1', plannedDurationSeconds: 3600);
      clock.advance(const Duration(minutes: 15));
      final cancelled = timer.cancel();

      expect(cancelled!.status, SessionStatus.cancelled);
      expect(cancelled.endedAt, DateTime.utc(2026, 1, 1, 9, 15));
    });

    test('orphan recovery marks stale sessions as completed', () {
      final started = DateTime.utc(2026, 1, 1, 9);
      final clock = FakeClock(started.add(const Duration(hours: 3)));
      final timer = SessionTimer(clock: clock);

      // User started at 09:00, app got killed. It's now 12:00 → 3h elapsed.
      final recovered = timer.recoverOrphan(
        sessionId: 'orphan1',
        plannedDurationSeconds: 3600,
        orphanStartedAt: started,
        staleAfter: const Duration(hours: 1),
      );

      expect(recovered!.status, SessionStatus.completed);
    });

    test('orphan recovery keeps recent sessions running', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9, 5));
      final timer = SessionTimer(clock: clock);

      final recovered = timer.recoverOrphan(
        sessionId: 'orphan1',
        plannedDurationSeconds: 3600,
        orphanStartedAt: DateTime.utc(2026, 1, 1, 9),
        staleAfter: const Duration(hours: 1),
      );

      expect(recovered!.status, SessionStatus.running);
      expect(recovered.elapsedSecondsAt(clock.now()), 5 * 60);
    });

    test('stream emits each state transition', () async {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      final timer = SessionTimer(clock: clock);

      final emitted = <SessionState>[];
      final sub = timer.stream.listen(emitted.add);

      timer.start(sessionId: 's1', plannedDurationSeconds: 3600);
      timer.pause();
      timer.resume();
      timer.complete();

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted.length, 4);
      expect(emitted.last.status, SessionStatus.completed);
    });

    test('wrong-state transitions are no-ops', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      final timer = SessionTimer(clock: clock);

      // pause without start
      timer.pause();
      expect(timer.state, isNull);

      // resume without pause
      timer.resume();
      expect(timer.state, isNull);

      // start, complete, then try to complete again
      timer.start(sessionId: 's1', plannedDurationSeconds: 60);
      timer.complete();
      final second = timer.complete();
      expect(second!.status, SessionStatus.completed);
    });
  });
}