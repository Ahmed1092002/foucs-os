import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities.dart';
import '../../../shared/widgets/duration_text.dart';
import '../../sessions/application/sessions_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(sessionsHistoryProvider(100));
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: asyncHistory.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No sessions yet.\nComplete one to see it here.',
                    textAlign: TextAlign.center),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sessionsHistoryProvider(100)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _SessionTile(session: sessions[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});
  final SessionEntity session;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final actual = session.actualDurationSeconds ?? 0;
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        title: Text(session.topic ?? 'Session'),
        subtitle: Text('${_fmt(session.startedAt)} • '
            'Planned ${session.plannedDurationSeconds ~/ 60}m • '
            'Actual ${actual ~/ 60}m'),
        trailing: session.isCancelled
            ? const Chip(label: Text('Cancelled'))
            : session.isCompleted
                ? Icon(Icons.check_circle,
                    color: theme.colorScheme.primary)
                : const Icon(Icons.timer_outlined),
        leading: DurationText(
          seconds: actual,
          style: theme.textTheme.titleLarge,
        ),
      ),
    );
  }
}