import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/stats.dart';
import '../../../core/di/providers.dart';
import '../../../shared/widgets/duration_text.dart';
import '../../../shared/widgets/empty_state.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});
  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  StatsRange _range = StatsRange.week;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(_summaryProvider(_range));
    final bySubject = ref.watch(_bySubjectProvider(_range));
    final streak = ref.watch(_streakProvider);
    final byDay = ref.watch(_byDayProvider(_range));

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<StatsRange>(
            segments: const [
              ButtonSegment(value: StatsRange.today, label: Text('Today')),
              ButtonSegment(value: StatsRange.week, label: Text('Week')),
              ButtonSegment(value: StatsRange.month, label: Text('Month')),
              ButtonSegment(value: StatsRange.all, label: Text('All')),
            ],
            selected: {_range},
            onSelectionChanged: (s) => setState(() => _range = s.first),
          ),
          const SizedBox(height: 16),
          summary.when(
            data: (s) => _SummaryCard(summary: s),
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 16),
          _ChartCard(byDayAsync: byDay, range: _range),
          const SizedBox(height: 16),
          streak.when(
            data: (s) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current streak: ${s.current}d'),
                          Text('Longest streak: ${s.longest}d',
                              style: Theme.of(context).textTheme.bodySmall),
                          if (s.lastStudyDate != null)
                            Text('Last study: ${s.lastStudyDate!.toLocal().toString().split(' ').first}',
                                style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Text('By subject', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          bySubject.when(
            data: (rows) {
              if (rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No completed sessions in this range.'),
                );
              }
              final maxSeconds = rows.first.actualSeconds;
              return Column(
                children: [
                  for (final row in rows)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _parseColor(row.color),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(row.name),
                                  Text('${row.sessions} session(s)',
                                      style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: DurationText(
                                seconds: row.actualSeconds,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (maxSeconds > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(
                        value: maxSeconds == 0 ? 0 : row_pct(rows.first.actualSeconds, maxSeconds),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
    );
  }

  double row_pct(int actual, int max) => actual / max;
  Color _parseColor(String? hex) {
    if (hex == null) return Theme.of(context).colorScheme.primary;
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

final _summaryProvider = FutureProvider.family<StatsSummaryEntity, StatsRange>(
  (ref, range) => ref.watch(statisticsRepositoryProvider).summary(range),
);
final _bySubjectProvider = FutureProvider.family<List<SubjectStatEntity>, StatsRange>(
  (ref, range) => ref.watch(statisticsRepositoryProvider).bySubject(range),
);
final _streakProvider = FutureProvider<StreakEntity>(
  (ref) => ref.watch(statisticsRepositoryProvider).streak(),
);

/// Range-dependent: today uses today, week uses last 7 days, month uses last 30,
/// all uses last 90 (the chart would be unreadable past that).
final _byDayProvider = FutureProvider.family<List<DailyTotalEntity>, StatsRange>(
  (ref, range) async {
    final repo = ref.watch(statisticsRepositoryProvider);
    final to = DateTime.now();
    final from = switch (range) {
      StatsRange.today => DateTime(to.year, to.month, to.day),
      StatsRange.week => to.subtract(const Duration(days: 6)),
      StatsRange.month => to.subtract(const Duration(days: 29)),
      StatsRange.all => to.subtract(const Duration(days: 89)),
    };
    return repo.byDay(from, to);
  },
);

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final StatsSummaryEntity summary;

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Metric(label: 'Planned', value: _fmt(summary.totalPlannedSeconds))),
                Expanded(child: _Metric(label: 'Actual', value: _fmt(summary.totalActualSeconds))),
                Expanded(child: _Metric(label: 'Sessions', value: '${summary.sessionsCompleted}')),
              ],
            ),
            const SizedBox(height: 12),
            if (summary.completionRate != null) ...[
              LinearProgressIndicator(value: summary.completionRate),
              const SizedBox(height: 4),
              Text(
                'Completion: ${(summary.completionRate! * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else
              Text(
                'No plan in this range.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.byDayAsync, required this.range});
  final AsyncValue<List<DailyTotalEntity>> byDayAsync;
  final StatsRange range;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Daily study time',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Icon(Icons.show_chart, color: scheme.primary),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: byDayAsync.when(
                data: (days) {
                  if (days.isEmpty) {
                    return const EmptyState(
                      icon: Icons.bar_chart,
                      title: 'No data',
                      message: 'No activity in this range yet.',
                    );
                  }
                  return LineChart(_buildChartData(days, scheme));
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(List<DailyTotalEntity> days, ColorScheme scheme) {
    final spots = <FlSpot>[];
    final maxSec = <int>[for (final d in days) d.actualSeconds];
    final maxV = ((maxSec.isEmpty ? 0 : maxSec.reduce((a, b) => a > b ? a : b))
        .clamp(3600, 1 << 30)).toDouble();
    for (var i = 0; i < days.length; i++) {
      spots.add(FlSpot(i.toDouble(), (days[i].actualSeconds / 3600).toDouble()));
    }
    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: (maxV / 4).clamp(0.5, 24),
            getTitlesWidget: (value, meta) => Text(
              '${value.toStringAsFixed(0)}h',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: (days.length / 5).clamp(1, 30).toDouble(),
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= days.length) return const SizedBox.shrink();
              final d = days[i].date;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${d.month}/${d.day}',
                    style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: ((days.length - 1).clamp(1, 1 << 30)).toDouble(),
      minY: 0,
      maxY: maxV,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: scheme.primary,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: scheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}