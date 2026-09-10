/// Abstract time source. Production binds to [SystemClock]; tests bind to
/// [FakeClock]. All duration math in the app MUST depend on this, never on
/// [DateTime.now] directly.
///
/// See docs/14-business-rules.md → R-S16.
abstract class TimeSource {
  DateTime now();
}

class SystemClock implements TimeSource {
  const SystemClock();
  @override
  DateTime now() => DateTime.now().toUtc();
}

/// Hand-cranked clock for unit tests.
///
/// Example:
/// ```dart
/// final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
/// clock.advance(const Duration(minutes: 47));
/// expect(clock.now(), DateTime.utc(2026, 1, 1, 9, 47));
/// ```
class FakeClock implements TimeSource {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) {
    _now = _now.add(d);
  }

  void setTo(DateTime t) {
    _now = t.toUtc();
  }
}