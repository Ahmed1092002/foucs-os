class PlanItemEntity {
  final String id;
  final String dailyPlanId;
  final String subjectId;
  final String startTime;       // 'HH:MM'
  final int durationSeconds;
  final int orderIndex;
  const PlanItemEntity({
    required this.id,
    required this.dailyPlanId,
    required this.subjectId,
    required this.startTime,
    required this.durationSeconds,
    required this.orderIndex,
  });
}

class DailyPlanEntity {
  final String id;
  final String userId;
  final DateTime planDate;
  final List<PlanItemEntity> items;
  const DailyPlanEntity({
    required this.id,
    required this.userId,
    required this.planDate,
    required this.items,
  });

  int get totalPlannedSeconds =>
      items.fold(0, (sum, item) => sum + item.durationSeconds);
}