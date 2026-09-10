// Unit tests for SettingsController — uses the in-memory
// SharedPreferences mock provided by the package.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_os/features/settings/application/settings_controller.dart';

ProviderContainer _container() => ProviderContainer();

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults match UserPreferences()', () async {
    final c = _container();
    addTearDown(c.dispose);
    final s = await c.read(settingsControllerProvider.future);
    expect(s.notificationsEnabled, true);
    expect(s.nudgeTime, const TimeOfDay(hour: 21, minute: 0));
    expect(s.dailyWarningThresholdPct, 70);
    expect(s.themeMode, ThemeMode.system);
    expect(s.timezone, isNull);
  });

  test('setNotificationsEnabled toggles the value', () async {
    final c = _container();
    addTearDown(c.dispose);
    await c.read(settingsControllerProvider.future);
    await c.read(settingsControllerProvider.notifier).setNotificationsEnabled(false);
    final s = await c.read(settingsControllerProvider.future);
    expect(s.notificationsEnabled, false);
  });

  test('threshold is clamped to 50..100', () async {
    final c = _container();
    addTearDown(c.dispose);
    await c.read(settingsControllerProvider.future);
    final n = c.read(settingsControllerProvider.notifier);
    await n.setDailyWarningThresholdPct(20);
    expect((await c.read(settingsControllerProvider.future)).dailyWarningThresholdPct, 50);
    await n.setDailyWarningThresholdPct(200);
    expect((await c.read(settingsControllerProvider.future)).dailyWarningThresholdPct, 100);
    await n.setDailyWarningThresholdPct(75);
    expect((await c.read(settingsControllerProvider.future)).dailyWarningThresholdPct, 75);
  });

  test('theme mode round-trips through persistence', () async {
    SharedPreferences.setMockInitialValues({'focus_os.theme_mode': 'dark'});
    final c = _container();
    addTearDown(c.dispose);
    final s = await c.read(settingsControllerProvider.future);
    expect(s.themeMode, ThemeMode.dark);

    await c.read(settingsControllerProvider.notifier).setThemeMode(ThemeMode.light);
    final after = await c.read(settingsControllerProvider.future);
    expect(after.themeMode, ThemeMode.light);
  });

  test('setTimezone stores and clearTimezone removes it', () async {
    final c = _container();
    addTearDown(c.dispose);
    await c.read(settingsControllerProvider.future);
    await c.read(settingsControllerProvider.notifier).setTimezone('Africa/Cairo');
    expect((await c.read(settingsControllerProvider.future)).timezone, 'Africa/Cairo');
    await c.read(settingsControllerProvider.notifier).setTimezone(null);
    expect((await c.read(settingsControllerProvider.future)).timezone, isNull);
  });
}