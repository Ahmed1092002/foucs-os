enum StatsRange { today, week, month, all }

extension StatsRangeApi on StatsRange {
  String get wire => switch (this) {
        StatsRange.today => 'today',
        StatsRange.week => 'week',
        StatsRange.month => 'month',
        StatsRange.all => 'all',
      };
}

class StatsSummaryEntity {
  final StatsRange range;
  final DateTime from;
  final DateTime to;
  final int totalActualSeconds;
  final int totalPlannedSeconds;
  final int sessionsCompleted;
  final double? completionRate; // null when no plan

  const StatsSummaryEntity({
    required this.range,
    required this.from,
    required this.to,
    required this.totalActualSeconds,
    required this.totalPlannedSeconds,
    required this.sessionsCompleted,
    required this.completionRate,
  });
}

class SubjectStatEntity {
  final String subjectId;
  final String name;
  final String? color;
  final int actualSeconds;
  final int sessions;
  const SubjectStatEntity({
    required this.subjectId,
    required this.name,
    required this.color,
    required this.actualSeconds,
    required this.sessions,
  });
}

class StreakEntity {
  final int current;
  final int longest;
  final DateTime? lastStudyDate;
  const StreakEntity({
    required this.current,
    required this.longest,
    required this.lastStudyDate,
  });
}

class DailyTotalEntity {
  final DateTime date;
  final int plannedSeconds;
  final int actualSeconds;
  const DailyTotalEntity({
    required this.date,
    required this.plannedSeconds,
    required this.actualSeconds,
  });
}