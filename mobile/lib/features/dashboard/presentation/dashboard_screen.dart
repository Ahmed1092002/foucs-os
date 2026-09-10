import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/entities.dart';
import '../../../core/domain/plan.dart';
import '../../../core/domain/stats.dart';
import '../../../shared/widgets/duration_text.dart';
import '../../auth/application/auth_controller.dart';
import '../../review/presentation/daily_review_card.dart';
import '../../sessions/application/sessions_controller.dart';
import '../../sessions/domain/session_timer.dart';

/// Today (date-only) in the device's local timezone.
DateTime _todayLocal() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

final _todaySummaryProvider = FutureProvider<StatsSummaryEntity>(
  (ref) => ref.watch(statisticsRepositoryProvider).summary(StatsRange.today),
);
final _streakProvider = FutureProvider<StreakEntity>(
  (ref) => ref.watch(statisticsRepositoryProvider).streak(),
);
final _todayPlanProvider = FutureProvider<DailyPlanEntity>(
  (ref) => ref
      .watch(dailyPlansRepositoryProvider)
      .getForDate(_todayLocal()),
);
final _todaySubjectsProvider = FutureProvider<List<SubjectEntity>>(
  (ref) => ref.watch(subjectsRepositoryProvider).list(),
);
final _todaySessionsProvider = FutureProvider<List<SessionEntity>>(
  (ref) async {
    final from = _todayLocal();
    final to = from.add(const Duration(days: 1));
    return ref
        .watch(sessionsRepositoryProvider)
        .list(limit: 50);
  },
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final activeSession = ref.watch(sessionsControllerProvider);
    final summary = ref.watch(_todaySummaryProvider);
    final streak = ref.watch(_streakProvider);
    final plan = ref.watch(_todayPlanProvider);
    final subjects = ref.watch(_todaySubjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus OS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeSession != null)
            _ActiveSessionBanner(session: activeSession),
          if (activeSession != null) const SizedBox(height: 16),
          _StatsHeader(summary: summary, streak: streak),
          const SizedBox(height: 16),
          const DailyReviewCard(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Today\'s plan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/planner'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Manage areas & subjects')),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => context.go('/areas'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Today's plan",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _PlanList(plan: plan, subjects: subjects),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/quick-start'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Quick Start'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.summary, required this.streak});
  final AsyncValue<StatsSummaryEntity> summary;
  final AsyncValue<StreakEntity> streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Today',
                    style: Theme.of(context).textTheme.titleMedium),
                streak.when(
                  data: (s) => s.current > 0
                      ? Chip(
                          avatar: const Icon(Icons.local_fire_department,
                              size: 16, color: Colors.orange),
                          label: Text('${s.current}d streak'),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            summary.when(
              data: (s) => Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      label: 'Planned',
                      seconds: s.totalPlannedSeconds,
                    ),
                  ),
                  Expanded(
                    child: _StatCell(
                      label: 'Completed',
                      seconds: s.totalActualSeconds,
                    ),
                  ),
                  Expanded(
                    child: _StatCell(
                      label: 'Sessions',
                      seconds: null,
                      count: s.sessionsCompleted,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text(
                'Stats unavailable: $e',
                style: TextStyle(color: scheme.error),
              ),
            ),
            const SizedBox(height: 8),
            summary.maybeWhen(
              data: (s) {
                if (s.totalPlannedSeconds == 0) return const SizedBox.shrink();
                final remaining =
                    (s.totalPlannedSeconds - s.totalActualSeconds).clamp(0, 1 << 30);
                final pct = (s.totalActualSeconds / s.totalPlannedSeconds)
                    .clamp(0.0, 1.0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: pct.toDouble(),
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Remaining today: ${_fmt(remaining)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, this.seconds, this.count});
  final String label;
  final int? seconds;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (seconds != null)
          DurationText(seconds: seconds!, style: Theme.of(context).textTheme.headlineSmall)
        else
          Text('$count', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({required this.plan, required this.subjects});
  final AsyncValue<DailyPlanEntity> plan;
  final AsyncValue<List<SubjectEntity>> subjects;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return plan.when(
      data: (p) {
        if (p.items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No plan for today.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          );
        }
        return subjects.when(
          data: (subs) {
            final byId = {for (final s in subs) s.id: s};
            return Column(
              children: [
                for (final item in p.items)
                  _PlanItemRow(
                    item: item,
                    subject: byId[item.subjectId],
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Text('$e'),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text('$e'),
    );
  }
}

class _PlanItemRow extends StatelessWidget {
  const _PlanItemRow({required this.item, required this.subject});
  final PlanItemEntity item;
  final SubjectEntity? subject;

  @override
  Widget build(BuildContext context) {
    final name = subject?.name ?? 'Unknown subject';
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle_outlined, size: 18),
          const SizedBox(width: 8),
          Text(item.startTime,
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Text('${item.durationSeconds ~/ 60}m'),
        ],
      ),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner({required this.session});
  final SessionState session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/session/active'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.timer, color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session ${session.status == SessionStatus.paused ? 'paused' : 'in progress'}',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (session.goalText != null)
                      Text(
                        session.goalText!,
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}