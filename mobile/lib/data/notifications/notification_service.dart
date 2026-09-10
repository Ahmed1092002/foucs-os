import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Two Android notification channels — split so the user can mute nudges
/// without losing session reminders.
class NotificationChannels {
  static const sessionReminder = AndroidNotificationChannel(
    'session_reminder',
    'Session reminders',
    description: 'Heads-up before a planned study session starts.',
    importance: Importance.high,
  );
  static const dailyNudge = AndroidNotificationChannel(
    'daily_nudge',
    'Daily nudges',
    description: 'Gentle end-of-day check-ins if you fell short of your plan.',
    importance: Importance.defaultImportance,
  );
}

/// Wraps `flutter_local_notifications` behind a small surface so the rest
/// of the app doesn't depend on the plugin.
///
/// All scheduling helpers are pure (TZ-based math) → unit-testable.
/// The plugin calls (`show`, `zonedSchedule`, `cancelAll`) are isolated to
/// `show*` methods and gated by a `bool _ready` flag.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  bool get ready => _ready;

  /// Call once at app start. Safe to call multiple times.
  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
    } catch (_) {
      // Plugin already initialized by another path; safe to ignore.
    }
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: initSettings);

    // Create channels on Android 8+.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(NotificationChannels.sessionReminder);
      await android.createNotificationChannel(NotificationChannels.dailyNudge);
    }
    _ready = true;
  }

  /// Schedule a "session starts in N minutes" notification.
  Future<void> scheduleSessionReminder({
    required int id,
    required String title,
    required String body,
    required DateTime whenLocal,
    Duration lead = const Duration(minutes: 10),
  }) async {
    if (!_ready) return;
    final fireAt = whenLocal.subtract(lead);
    if (fireAt.isBefore(DateTime.now())) return; // don't schedule in the past
    final scheduled = tz.TZDateTime.from(fireAt, tz.local);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Schedule an end-of-day nudge if completion < threshold.
  Future<void> scheduleDailyNudge({
    required int id,
    required String title,
    required String body,
    required DateTime whenLocal,
  }) async {
    if (!_ready) return;
    if (whenLocal.isBefore(DateTime.now())) return;
    final scheduled = tz.TZDateTime.from(whenLocal, tz.local);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'session_reminder',
        'Session reminders',
        channelDescription: 'Heads-up before a planned study session starts.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(presentSound: true, presentBadge: true),
    );
  }

  /// Debug helper. Never call from production code.
  @visibleForTesting
  FlutterLocalNotificationsPlugin get debugPlugin => _plugin;
}

/// Compose the "session starts in N minutes" title and body for a plan item.
/// Pure function — no plugin calls.
({String title, String body}) composeSessionReminder({
  required String subjectName,
  required int durationMinutes,
  required Duration lead,
}) {
  final leadLabel = lead.inMinutes == 0
      ? 'now'
      : lead.inMinutes < 60
          ? 'in ${lead.inMinutes} min'
          : 'in ${(lead.inMinutes / 60).round()}h';
  return (
    title: '$subjectName starts $leadLabel',
    body: 'A $durationMinutes-minute session is on your plan.',
  );
}

/// Compose the end-of-day nudge if actual < threshold of planned.
String composeDailyNudge({
  required int plannedSeconds,
  required int actualSeconds,
  required int thresholdPct,
}) {
  if (plannedSeconds == 0) {
    return 'No plan was set today — that is also valid.';
  }
  final ratio = actualSeconds / plannedSeconds;
  if (ratio * 100 >= thresholdPct) return ''; // we did enough; no nudge
  final pct = (ratio * 100).round();
  return 'You reached $pct% of today\'s plan. Tomorrow is fresh.';
}

/// Convert "HH:MM" + date into a local DateTime.
DateTime hhmmToDateTime(DateTime date, String hhmm) {
  final parts = hhmm.split(':');
  return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
}