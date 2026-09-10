// Pure-Dart unit tests for stats derivation logic.
//
// The backend computes stats via SQL, but the same formulas must hold
// client-side so the dashboard renders meaningful numbers even offline.
// These tests lock down the math.

import 'package:flutter_test/flutter_test.dart';

class FakeSummary {
  final int totalActualSeconds;
  final int totalPlannedSeconds;
  final int sessionsCompleted;
  final double? completionRate;
  const FakeSummary({
    required this.totalActualSeconds,
    required this.totalPlannedSeconds,
    required this.sessionsCompleted,
    this.completionRate,
  });
  static FakeSummary from({
    required int totalActual,
    required int totalPlanned,
    required int sessionsCompleted,
  }) {
    final rate = totalPlanned == 0
        ? null
        : (totalActual / totalPlanned).clamp(0.0, 1.0);
    return FakeSummary(
      totalActualSeconds: totalActual,
      totalPlannedSeconds: totalPlanned,
      sessionsCompleted: sessionsCompleted,
      completionRate: rate,
    );
  }
}

void main() {
  group('Stats math', () {
    test('completionRate is null when there is no plan', () {
      final s = FakeSummary.from(totalActual: 1800, totalPlanned: 0, sessionsCompleted: 1);
      expect(s.completionRate, isNull);
    });

    test('completionRate = actual / planned when in range', () {
      final s = FakeSummary.from(totalActual: 1800, totalPlanned: 3600, sessionsCompleted: 1);
      expect(s.completionRate, 0.5);
    });

    test('completionRate clamps at 1.0 even when overplanned', () {
      final s = FakeSummary.from(totalActual: 5000, totalPlanned: 1800, sessionsCompleted: 3);
      expect(s.completionRate, 1.0);
    });

    test('zero actual, non-zero plan → rate = 0', () {
      final s = FakeSummary.from(totalActual: 0, totalPlanned: 3600, sessionsCompleted: 0);
      expect(s.completionRate, 0.0);
    });
  });

  group('HH:MM parsing', () {
    // Helper that mirrors the dashboard's _extractHhMm — kept here as a
    // regression guard for the planner endpoint's Time serialisation.
    String extractHhMm(String s) {
      final tIdx = s.indexOf('T');
      if (tIdx < 0) return s;
      return s.substring(tIdx + 1, tIdx + 6);
    }

    test('extracts HH:MM from Prisma\'s 1970-01-01T09:30:00Z', () {
      expect(extractHhMm('1970-01-01T09:30:00.000Z'), '09:30');
    });

    test('passes through plain HH:MM strings', () {
      expect(extractHhMm('14:00'), '14:00');
    });
  });
}