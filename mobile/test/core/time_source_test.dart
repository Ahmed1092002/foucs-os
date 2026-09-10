// Tests for the abstract TimeSource.
//
// The whole timer math (R-S2, R-S3) depends on TimeSource, so it's the
// first thing we lock down. The real SessionTimer tests will come in
// Phase 2; this verifies the seam itself.

import 'package:flutter_test/flutter_test.dart';

import 'package:focus_os/core/time/time_source.dart';

void main() {
  group('FakeClock', () {
    test('returns the initial value', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      expect(clock.now(), DateTime.utc(2026, 1, 1, 9));
    });

    test('advance() moves time forward by the given duration', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      clock.advance(const Duration(minutes: 47));
      expect(clock.now(), DateTime.utc(2026, 1, 1, 9, 47));
    });

    test('advance() composes across multiple calls', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      clock.advance(const Duration(minutes: 30));
      clock.advance(const Duration(minutes: 17));
      expect(clock.now(), DateTime.utc(2026, 1, 1, 9, 47));
    });

    test('setTo() normalizes to UTC', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
      clock.setTo(DateTime(2026, 6, 15, 14, 30));
      expect(clock.now().isUtc, isTrue);
    });
  });

  group('SystemClock', () {
    test('now() returns a UTC instant', () {
      const clock = SystemClock();
      expect(clock.now().isUtc, isTrue);
    });
  });
}