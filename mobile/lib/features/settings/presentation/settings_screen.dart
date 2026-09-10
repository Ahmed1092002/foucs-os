import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/di/providers.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _syncing = false;
  String? _syncResult;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final settingsAsync = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) => ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Signed in as'),
              subtitle: Text(auth.user?.email ?? '—'),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Timezone'),
              subtitle: Text(s.timezone ?? 'Device default'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _editTimezone,
            ),
            const Divider(),
            ListTile(
              title: Text('Notifications',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Enable'),
              subtitle: const Text('Session reminders + end-of-day review nudge.'),
              value: s.notificationsEnabled,
              onChanged: (v) => _onToggleNotifications(s, v),
            ),
            ListTile(
              leading: const Icon(Icons.alarm),
              title: const Text('Daily review nudge'),
              subtitle: Text(
                'Reminder at ${s.nudgeTime.format(context)} if you haven\'t recorded a review.',
              ),
              enabled: s.notificationsEnabled,
              onTap: s.notificationsEnabled ? () => _pickNudgeTime(s) : null,
              trailing: const Icon(Icons.chevron_right),
            ),
            const Divider(),
            ListTile(
              title: Text('Daily plan warning',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber),
              title: const Text('Warn if planned hours ≥'),
              subtitle: Text('${s.dailyWarningThresholdPct}% of target load'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Slider(
                value: s.dailyWarningThresholdPct.toDouble(),
                min: 50,
                max: 100,
                divisions: 10,
                label: '${s.dailyWarningThresholdPct}%',
                onChanged: (v) => ref
                    .read(settingsControllerProvider.notifier)
                    .setDailyWarningThresholdPct(v.round()),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text('Appearance',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: s.themeMode,
              onChanged: (v) => _setTheme(v!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: s.themeMode,
              onChanged: (v) => _setTheme(v!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: s.themeMode,
              onChanged: (v) => _setTheme(v!),
            ),
            const Divider(),
            ListTile(
              leading: _syncing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync),
              title: const Text('Sync now'),
              subtitle: const Text('Push any queued changes to the server.'),
              onTap: _syncing ? null : _syncNow,
            ),
            if (_syncResult != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_syncResult!,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onToggleNotifications(UserPreferences s, bool v) async {
    await ref.read(settingsControllerProvider.notifier).setNotificationsEnabled(v);
    final notif = ref.read(notificationServiceProvider);
    if (!v) {
      await notif.cancelAll();
    } else {
      // Re-schedule today's nudge.
      await _scheduleNudge(s.nudgeTime);
    }
  }

  Future<void> _pickNudgeTime(UserPreferences s) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: s.nudgeTime,
    );
    if (picked == null) return;
    await ref.read(settingsControllerProvider.notifier).setNudgeTime(picked);
    await _scheduleNudge(picked);
  }

  Future<void> _setTheme(ThemeMode m) async {
    await ref.read(settingsControllerProvider.notifier).setThemeMode(m);
  }

  Future<void> _editTimezone() async {
    final s = ref.read(settingsControllerProvider).value;
    final current = s?.timezone ?? DateTime.now().timeZoneName;
    final controller = TextEditingController(text: current);
    final newTz = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Timezone'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'IANA timezone',
            helperText: 'e.g. Africa/Cairo, Europe/Berlin, UTC',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTz == null) return;
    await ref.read(settingsControllerProvider.notifier).setTimezone(
          newTz.isEmpty ? null : newTz,
        );
  }

  Future<void> _scheduleNudge(TimeOfDay t) async {
    final notif = ref.read(notificationServiceProvider);
    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    await notif.cancel(2000);
    await notif.scheduleDailyNudge(
      id: 2000,
      title: 'Daily review',
      body: 'Tap to record what went well and what blocked you.',
      whenLocal: when,
    );
  }

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _syncResult = null;
    });
    try {
      final sync = ref.read(syncServiceProvider);
      // 1) Push local outbox
      final pushed = await sync.drainOutbox();
      // 2) Pull server changes since last pull
      final settings = ref.read(settingsControllerProvider);
      final lastPulled = settings.value?.lastPulledAt;
      final serverTime = await sync.pull(since: lastPulled);
      // 3) Persist the new lastPulledAt
      await ref.read(settingsControllerProvider.notifier).setLastPulledAt(serverTime);
      setState(() => _syncResult = 'Pushed $pushed change(s). Pulled from server.');
    } catch (e) {
      setState(() => _syncResult = 'Sync failed: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }
}