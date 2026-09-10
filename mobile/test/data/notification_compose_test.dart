// Tests for the pure-Dart pieces of NotificationService:
//   - composeSessionReminder()
//   - composeDailyNudge()
//   - hhmmToDateTime()
//
// Plugin-touching methods (init, schedule, cancel) aren't unit-testable
// without platform-channel mocks; they're exercised in widget tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_os/data/notifications/notification_service.dart';

void main() {
  group('composeSessionReminder', () {
    test('uses subject name + lead label', () {
      final r = composeSessionReminder(
        subjectName: 'React',
        durationMinutes: 60,
        lead: const Duration(minutes: 10),
      );
      expect(r.title, 'React starts in 10 min');
      expect(r.body, contains('60-minute session'));
    });

    test('rounds hours when lead is over an hour', () {
      final r = composeSessionReminder(
        subjectName: 'DevOps',
        durationMinutes: 90,
        lead: const Duration(minutes: 75),
      );
      expect(r.title, contains('in 1h'));
    });

    test('"now" lead shows literal now', () {
      final r = composeSessionReminder(
        subjectName: 'X',
        durationMinutes: 30,
        lead: Duration.zero,
      );
      expect(r.title, contains('now'));
    });
  });

  group('composeDailyNudge', () {
    test('empty plan → "no plan was set" message', () {
      final m = composeDailyNudge(
        plannedSeconds: 0,
        actualSeconds: 0,
        thresholdPct: 70,
      );
      expect(m, contains('No plan was set'));
    });

    test('met threshold → empty (no nudge)', () {
      final m = composeDailyNudge(
        plannedSeconds: 3600,
        actualSeconds: 2700, // 75%
        thresholdPct: 70,
      );
      expect(m, '');
    });

    test('under threshold → encouraging message', () {
      final m = composeDailyNudge(
        plannedSeconds: 3600,
        actualSeconds: 900, // 25%
        thresholdPct: 70,
      );
      expect(m, contains('25%'));
      expect(m, contains('fresh'));
    });
  });

  group('hhmmToDateTime', () {
    test('parses HH:MM on a given date', () {
      final d = hhmmToDateTime(DateTime(2026, 9, 7), '14:30');
      expect(d, DateTime(2026, 9, 7, 14, 30));
    });
  });
}