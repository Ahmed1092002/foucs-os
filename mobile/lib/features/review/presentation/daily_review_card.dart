import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/stats.dart';
import '../../../core/di/providers.dart';

/// "How did today go?" auto-summary card. V1 makes it tappable so the
/// user can record their end-of-day review.
class DailyReviewCard extends ConsumerWidget {
  const DailyReviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(_todaySummaryProvider);
    final streak = ref.watch(_streakProvider);

    return summary.when(
      data: (s) {
        final scheme = Theme.of(context).colorScheme;
        final planned = s.totalPlannedSeconds;
        final actual = s.totalActualSeconds;
        final ratio = planned == 0 ? null : (actual / planned).clamp(0.0, 1.5);
        final message = _composeMessage(planned, actual);

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.go('/review'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_available, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text("Today's recap",
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Icon(Icons.edit_outlined,
                          size: 18, color: scheme.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  if (ratio != null) ...[
                    LinearProgressIndicator(
                      value: ratio > 1.0 ? 1.0 : ratio,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planned == 0
                          ? 'No plan today.'
                          : 'Planned ${_fmt(planned)} • Actual ${_fmt(actual)}'
                              ' • ${(ratio * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const _Skeleton(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  /// Composed in a non-guilt-tripping voice. Even a short day is a real day.
  String _composeMessage(int planned, int actual) {
    if (planned == 0 && actual == 0) {
      return 'Nothing planned, nothing studied yet today.';
    }
    if (planned == 0 && actual > 0) {
      return 'You studied ${_fmt(actual)} today — unplanned, but real.';
    }
    if (actual == 0 && planned > 0) {
      return 'You planned ${_fmt(planned)} for today.\nNo sessions completed yet.';
    }
    if (actual < planned) {
      return 'You completed ${_fmt(actual)} of your ${_fmt(planned)} plan.';
    }
    if (actual == planned) {
      return 'You hit your ${_fmt(actual)} plan exactly. Nicely paced.';
    }
    return 'You went over today\'s plan: ${_fmt(actual)} of ${_fmt(planned)}.';
  }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 16,
              width: 140,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _todaySummaryProvider = FutureProvider<StatsSummaryEntity>(
  (ref) => ref.watch(statisticsRepositoryProvider).summary(StatsRange.today),
);
final _streakProvider = FutureProvider<StreakEntity>(
  (ref) => ref.watch(statisticsRepositoryProvider).streak(),
);