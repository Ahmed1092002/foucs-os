// Pure-Dart unit tests for course/lesson progress math.
//
// These mirror the backend's `subjectProgress` formula (docs/14 R-S11):
//     percentComplete = 0.5 * percentTime + 0.5 * percentLessons
// where percentTime = completedHours / targetHours and percentLessons is the
// fraction of lessons marked 'completed'. Both terms clamp at 1.0.
// When neither time target nor lessons exist, the result is 0.

import 'package:flutter_test/flutter_test.dart';

class _Progress {
  final double completedHours;
  final double targetHours;
  final int totalLessons;
  final int completedLessons;
  _Progress({
    required this.completedHours,
    required this.targetHours,
    required this.totalLessons,
    required this.completedLessons,
  });
}

double computePercentComplete(_Progress p) {
  final percentTime = p.targetHours == 0
      ? 0.0
      : (p.completedHours / p.targetHours).clamp(0.0, 1.0);
  final percentLessons = p.totalLessons == 0
      ? 0.0
      : (p.completedLessons / p.totalLessons).clamp(0.0, 1.0);
  if (p.targetHours == 0 && p.totalLessons == 0) return 0;
  return 0.5 * percentTime + 0.5 * percentLessons;
}

void main() {
  group('Subject progress math (R-S11)', () {
    test('empty subject: 0%', () {
      final p = _Progress(
          completedHours: 0, targetHours: 0, totalLessons: 0, completedLessons: 0);
      expect(computePercentComplete(p), 0);
    });

    test('lessons done but no time target: 25% (lessons only, no time contribution)', () {
      final p = _Progress(
          completedHours: 0,
          targetHours: 0,
          totalLessons: 4,
          completedLessons: 2);
      // 0 + 0.5 * 0.5 = 0.25
      expect(computePercentComplete(p), 0.25);
    });

    test('time-only: completed target fully → 50%', () {
      final p = _Progress(
          completedHours: 40,
          targetHours: 40,
          totalLessons: 0,
          completedLessons: 0);
      expect(computePercentComplete(p), 0.5);
    });

    test('both halves contribute: 50% time + 50% lessons = 50%', () {
      final p = _Progress(
          completedHours: 20,
          targetHours: 40,
          totalLessons: 4,
          completedLessons: 2);
      expect(computePercentComplete(p), 0.5);
    });

    test('overplanned time still clamps to 1.0 on the time side', () {
      final p = _Progress(
          completedHours: 100,
          targetHours: 40,
          totalLessons: 4,
          completedLessons: 4);
      // 0.5 * 1.0 + 0.5 * 1.0 = 1.0
      expect(computePercentComplete(p), 1.0);
    });

    test('quarter of everything → 25%', () {
      final p = _Progress(
          completedHours: 10,
          targetHours: 40,
          totalLessons: 4,
          completedLessons: 1);
      expect(computePercentComplete(p), 0.25);
    });
  });
}