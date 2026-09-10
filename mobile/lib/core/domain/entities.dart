/// Pure domain entities. No Flutter, no Drift, no JSON.
/// These are the lingua franca between layers.

class UserEntity {
  final String id;
  final String email;
  final String timezone;
  final DateTime createdAt;
  const UserEntity({
    required this.id,
    required this.email,
    required this.timezone,
    required this.createdAt,
  });
}

class AreaEntity {
  final String id;
  final String userId;
  final String name;
  final String color;
  final String? icon;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AreaEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    required this.icon,
    required this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isArchived => archivedAt != null;
}

class SubjectEntity {
  final String id;
  final String userId;
  final String areaId;
  final String name;
  final String? description;
  final String? color;
  final double targetHours;
  final String status; // active | paused | done | archived
  final int priority;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubjectEntity({
    required this.id,
    required this.userId,
    required this.areaId,
    required this.name,
    required this.description,
    required this.color,
    required this.targetHours,
    required this.status,
    required this.priority,
    required this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isArchived => status == 'archived';
}

class SessionEntity {
  final String id;
  final String subjectId;
  final String? topic;
  final int plannedDurationSeconds;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? actualDurationSeconds;
  final int pausedIntervalsSeconds;
  final String state; // running | paused | completed | cancelled
  final String? goalText;
  final String? goalResult;
  final int? focusRating;
  final int? energyRating;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SessionEntity({
    required this.id,
    required this.subjectId,
    required this.topic,
    required this.plannedDurationSeconds,
    required this.startedAt,
    required this.endedAt,
    required this.actualDurationSeconds,
    required this.pausedIntervalsSeconds,
    required this.state,
    required this.goalText,
    required this.goalResult,
    required this.focusRating,
    required this.energyRating,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => state == 'completed';
  bool get isCancelled => state == 'cancelled';
  bool get isActive => state == 'running' || state == 'paused';
}