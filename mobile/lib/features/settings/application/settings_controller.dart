import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-controllable app preferences.
///
/// Persisted via `shared_preferences`. The keys are namespaced with
/// `focus_os.` so they don't collide with future settings.
class UserPreferences {
  static const _kNotif = 'focus_os.notifications_enabled';
  static const _kNudgeHour = 'focus_os.nudge_hour';
  static const _kNudgeMinute = 'focus_os.nudge_minute';
  static const _kWarnThreshold = 'focus_os.daily_warn_threshold';
  static const _kThemeMode = 'focus_os.theme_mode';
  static const _kTimezone = 'focus_os.timezone';
  static const _kLastPulledAt = 'focus_os.last_pulled_at';

  final bool notificationsEnabled;
  final TimeOfDay nudgeTime;
  final int dailyWarningThresholdPct; // 50..100
  final ThemeMode themeMode;
  final String? timezone; // IANA, null = device default
  final DateTime? lastPulledAt; // ISO string persisted

  const UserPreferences({
    this.notificationsEnabled = true,
    this.nudgeTime = const TimeOfDay(hour: 21, minute: 0),
    this.dailyWarningThresholdPct = 70,
    this.themeMode = ThemeMode.system,
    this.timezone,
    this.lastPulledAt,
  });

  UserPreferences copyWith({
    bool? notificationsEnabled,
    TimeOfDay? nudgeTime,
    int? dailyWarningThresholdPct,
    ThemeMode? themeMode,
    String? timezone,
    bool clearTimezone = false,
    DateTime? lastPulledAt,
    bool clearLastPulledAt = false,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      nudgeTime: nudgeTime ?? this.nudgeTime,
      dailyWarningThresholdPct:
          dailyWarningThresholdPct ?? this.dailyWarningThresholdPct,
      themeMode: themeMode ?? this.themeMode,
      timezone: clearTimezone ? null : (timezone ?? this.timezone),
      lastPulledAt: clearLastPulledAt ? null : (lastPulledAt ?? this.lastPulledAt),
    );
  }

  static Future<UserPreferences> load(SharedPreferences prefs) async {
    return UserPreferences(
      notificationsEnabled: prefs.getBool(_kNotif) ?? true,
      nudgeTime: TimeOfDay(
        hour: prefs.getInt(_kNudgeHour) ?? 21,
        minute: prefs.getInt(_kNudgeMinute) ?? 0,
      ),
      dailyWarningThresholdPct: prefs.getInt(_kWarnThreshold) ?? 70,
      themeMode: _parseThemeMode(prefs.getString(_kThemeMode)),
      timezone: prefs.getString(_kTimezone),
      lastPulledAt: prefs.getString(_kLastPulledAt) != null
          ? DateTime.parse(prefs.getString(_kLastPulledAt)!)
          : null,
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setBool(_kNotif, notificationsEnabled);
    await prefs.setInt(_kNudgeHour, nudgeTime.hour);
    await prefs.setInt(_kNudgeMinute, nudgeTime.minute);
    await prefs.setInt(_kWarnThreshold, dailyWarningThresholdPct);
    await prefs.setString(_kThemeMode, themeModeToString(themeMode));
    if (timezone == null) {
      await prefs.remove(_kTimezone);
    } else {
      await prefs.setString(_kTimezone, timezone!);
    }
    if (lastPulledAt == null) {
      await prefs.remove(_kLastPulledAt);
    } else {
      await prefs.setString(_kLastPulledAt, lastPulledAt!.toIso8601String());
    }
  }

  static ThemeMode _parseThemeMode(String? s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

String themeModeToString(ThemeMode m) => switch (m) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

/// AsyncNotifier exposing [UserPreferences] with persisted storage.
class SettingsController extends AsyncNotifier<UserPreferences> {
  late SharedPreferences _prefs;

  @override
  Future<UserPreferences> build() async {
    _prefs = await SharedPreferences.getInstance();
    return UserPreferences.load(_prefs);
  }

  Future<void> _set(UserPreferences next) async {
    state = AsyncData(next);
    await next.save(_prefs);
  }

  Future<void> setNotificationsEnabled(bool v) async {
    final cur = state.value ?? const UserPreferences();
    await _set(cur.copyWith(notificationsEnabled: v));
  }

  Future<void> setNudgeTime(TimeOfDay t) async {
    final cur = state.value ?? const UserPreferences();
    await _set(cur.copyWith(nudgeTime: t));
  }

  Future<void> setDailyWarningThresholdPct(int pct) async {
    final cur = state.value ?? const UserPreferences();
    await _set(cur.copyWith(
      dailyWarningThresholdPct: pct.clamp(50, 100),
    ));
  }

  Future<void> setThemeMode(ThemeMode m) async {
    final cur = state.value ?? const UserPreferences();
    await _set(cur.copyWith(themeMode: m));
  }

  Future<void> setTimezone(String? tz) async {
    final cur = state.value ?? const UserPreferences();
    await _set(cur.copyWith(timezone: tz, clearTimezone: tz == null));
  }

  Future<void> setLastPulledAt(DateTime dt) async {
    final cur = state.value ?? const UserPreferences();
    await _set(cur.copyWith(lastPulledAt: dt));
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, UserPreferences>(
  SettingsController.new,
);