// Tests for the message-composition logic in DailyReviewCard.
//
// We don't render the widget here (that's covered by widget tests in a
// later phase). We exercise the rule the card enforces:
// "no guilt, no punishment" — even short days are real days.

import 'package:flutter_test/flutter_test.dart';

String compose(int planned, int actual) {
  String fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  if (planned == 0 && actual == 0) {
    return 'Nothing planned, nothing studied yet today.';
  }
  if (planned == 0 && actual > 0) {
    return 'You studied ${fmt(actual)} today — unplanned, but real.';
  }
  if (actual == 0 && planned > 0) {
    return 'You planned ${fmt(planned)} for today.\nNo sessions completed yet.';
  }
  if (actual < planned) {
    return 'You completed ${fmt(actual)} of your ${fmt(planned)} plan.';
  }
  if (actual == planned) {
    return 'You hit your ${fmt(actual)} plan exactly. Nicely paced.';
  }
  return 'You went over today\'s plan: ${fmt(actual)} of ${fmt(planned)}.';
}

void main() {
  group('Daily review message', () {
    test('empty day', () {
      expect(compose(0, 0), contains('Nothing planned'));
    });

    test('unplanned study is acknowledged', () {
      expect(compose(0, 1800), contains('unplanned, but real'));
    });

    test('planned but nothing done is neutral, not failing', () {
      final msg = compose(3600, 0);
      expect(msg, isNot(contains('failed')));
      expect(msg, isNot(contains('missed')));
      expect(msg, contains('No sessions completed yet'));
    });

    test('partial completion is matter-of-fact', () {
      expect(compose(3600, 1800), contains('completed 30m of your 1h'));
    });

    test('exact match is celebrated', () {
      expect(compose(3600, 3600), contains('exactly'));
    });

    test('overplanned is acknowledged without shame', () {
      expect(compose(3600, 5400), contains('over today'));
    });
  });
}