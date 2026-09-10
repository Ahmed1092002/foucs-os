class CourseEntity {
  final String id;
  final String userId;
  final String subjectId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ModuleEntity> modules;
  const CourseEntity({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.modules = const [],
  });

  /// R-S11 simplified for the course-level summary.
  int get totalLessons => modules.fold(0, (s, m) => s + m.lessons.length);
  int get completedLessons =>
      modules.fold(0, (s, m) => s + m.lessons.where((l) => l.isCompleted).length);
  double get percentLessonsComplete =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;
}

class ModuleEntity {
  final String id;
  final String courseId;
  final String name;
  final String? description;
  final int orderIndex;
  final List<LessonEntity> lessons;
  const ModuleEntity({
    required this.id,
    required this.courseId,
    required this.name,
    required this.description,
    required this.orderIndex,
    this.lessons = const [],
  });
}

enum LessonStatus { notStarted, inProgress, completed }

extension LessonStatusWire on LessonStatus {
  String get wire => switch (this) {
        LessonStatus.notStarted => 'not_started',
        LessonStatus.inProgress => 'in_progress',
        LessonStatus.completed => 'completed',
      };

  static LessonStatus fromWire(String s) => switch (s) {
        'in_progress' => LessonStatus.inProgress,
        'completed' => LessonStatus.completed,
        _ => LessonStatus.notStarted,
      };
}

class LessonEntity {
  final String id;
  final String moduleId;
  final String name;
  final String? description;
  final LessonStatus status;
  final int orderIndex;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LessonEntity({
    required this.id,
    required this.moduleId,
    required this.name,
    required this.description,
    required this.status,
    required this.orderIndex,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == LessonStatus.completed;
  bool get isInProgress => status == LessonStatus.inProgress;
  bool get isNotStarted => status == LessonStatus.notStarted;
}

class SubjectProgressEntity {
  final String subjectId;
  final double completedHours;
  final double targetHours;
  final int totalLessons;
  final int completedLessons;
  final double percentComplete;

  const SubjectProgressEntity({
    required this.subjectId,
    required this.completedHours,
    required this.targetHours,
    required this.totalLessons,
    required this.completedLessons,
    required this.percentComplete,
  });
}