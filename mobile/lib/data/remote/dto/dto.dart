/// DTOs mirror the backend wire format. Mappers translate these into
/// domain entities (kept as plain Dart classes for Phase 1 to avoid the
/// codegen knot; freezed will replace them in a later cleanup pass).

class UserDto {
  final String id;
  final String email;
  final String timezone;
  final DateTime createdAt;

  const UserDto({
    required this.id,
    required this.email,
    required this.timezone,
    required this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> j) => UserDto(
        id: j['id'] as String,
        email: j['email'] as String,
        timezone: j['timezone'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class AuthTokensDto {
  final String accessToken;
  final String refreshToken;
  const AuthTokensDto({required this.accessToken, required this.refreshToken});

  factory AuthTokensDto.fromJson(Map<String, dynamic> j) => AuthTokensDto(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
      );
}

class AuthResultDto {
  final UserDto user;
  final AuthTokensDto tokens;
  const AuthResultDto({required this.user, required this.tokens});

  factory AuthResultDto.fromJson(Map<String, dynamic> j) => AuthResultDto(
        user: UserDto.fromJson(j['user'] as Map<String, dynamic>),
        tokens: AuthTokensDto.fromJson(j['tokens'] as Map<String, dynamic>),
      );
}

class AreaDto {
  final String id;
  final String userId;
  final String name;
  final String color;
  final String? icon;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AreaDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    required this.icon,
    required this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AreaDto.fromJson(Map<String, dynamic> j) => AreaDto(
        id: j['id'] as String,
        userId: j['userId'] as String,
        name: j['name'] as String,
        color: j['color'] as String,
        icon: j['icon'] as String?,
        archivedAt: j['archivedAt'] != null
            ? DateTime.parse(j['archivedAt'] as String)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class SubjectDto {
  final String id;
  final String userId;
  final String areaId;
  final String name;
  final String? description;
  final String? color;
  final double targetHours;
  final String status;
  final int priority;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubjectDto({
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

  factory SubjectDto.fromJson(Map<String, dynamic> j) => SubjectDto(
        id: j['id'] as String,
        userId: j['userId'] as String,
        areaId: j['areaId'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        color: j['color'] as String?,
        targetHours: double.parse(j['targetHours'].toString()),
        status: j['status'] as String,
        priority: j['priority'] as int,
        deadline:
            j['deadline'] != null ? DateTime.parse(j['deadline'] as String) : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class SessionDto {
  final String id;
  final String subjectId;
  final String? topic;
  final int plannedDurationSeconds;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? actualDurationSeconds;
  final int pausedIntervalsSeconds;
  final String state;
  final String? goalText;
  final String? goalResult;
  final int? focusRating;
  final int? energyRating;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SessionDto({
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

  factory SessionDto.fromJson(Map<String, dynamic> j) => SessionDto(
        id: j['id'] as String,
        subjectId: j['subjectId'] as String,
        topic: j['topic'] as String?,
        plannedDurationSeconds: j['plannedDurationSeconds'] as int,
        startedAt: DateTime.parse(j['startedAt'] as String),
        endedAt: j['endedAt'] != null ? DateTime.parse(j['endedAt'] as String) : null,
        actualDurationSeconds: j['actualDurationSeconds'] as int?,
        pausedIntervalsSeconds: (j['pausedIntervalsSeconds'] as int?) ?? 0,
        state: j['state'] as String,
        goalText: j['goalText'] as String?,
        goalResult: j['goalResult'] as String?,
        focusRating: j['focusRating'] as int?,
        energyRating: j['energyRating'] as int?,
        notes: j['notes'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class CourseDto {
  final String id;
  final String userId;
  final String subjectId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ModuleDto> modules;
  const CourseDto({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.modules = const [],
  });

  factory CourseDto.fromJson(Map<String, dynamic> j) => CourseDto(
        id: j['id'] as String,
        userId: j['userId'] as String,
        subjectId: j['subjectId'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        modules: (j['modules'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(ModuleDto.fromJson)
            .toList(),
      );
}

class ModuleDto {
  final String id;
  final String courseId;
  final String name;
  final String? description;
  final int orderIndex;
  final List<LessonDto> lessons;
  const ModuleDto({
    required this.id,
    required this.courseId,
    required this.name,
    required this.description,
    required this.orderIndex,
    this.lessons = const [],
  });

  factory ModuleDto.fromJson(Map<String, dynamic> j) => ModuleDto(
        id: j['id'] as String,
        courseId: j['courseId'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        orderIndex: j['orderIndex'] as int,
        lessons: (j['lessons'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(LessonDto.fromJson)
            .toList(),
      );
}

class LessonDto {
  final String id;
  final String moduleId;
  final String name;
  final String? description;
  final String status;
  final int orderIndex;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LessonDto({
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

  factory LessonDto.fromJson(Map<String, dynamic> j) => LessonDto(
        id: j['id'] as String,
        moduleId: j['moduleId'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        status: j['status'] as String,
        orderIndex: j['orderIndex'] as int,
        completedAt: j['completedAt'] != null
            ? DateTime.parse(j['completedAt'] as String)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class SubjectProgressDto {
  final String subjectId;
  final double completedHours;
  final double targetHours;
  final double percentTime;
  final int totalLessons;
  final int completedLessons;
  final double percentLessons;
  final double percentComplete;

  const SubjectProgressDto({
    required this.subjectId,
    required this.completedHours,
    required this.targetHours,
    required this.percentTime,
    required this.totalLessons,
    required this.completedLessons,
    required this.percentLessons,
    required this.percentComplete,
  });

  factory SubjectProgressDto.fromJson(Map<String, dynamic> j) =>
      SubjectProgressDto(
        subjectId: j['subjectId'] as String,
        completedHours: (j['completedHours'] as num).toDouble(),
        targetHours: (j['targetHours'] as num).toDouble(),
        percentTime: (j['percentTime'] as num).toDouble(),
        totalLessons: j['totalLessons'] as int,
        completedLessons: j['completedLessons'] as int,
        percentLessons: (j['percentLessons'] as num).toDouble(),
        percentComplete: (j['percentComplete'] as num).toDouble(),
      );
}

class DailyReviewDto {
  final String id;
  final String userId;
  final DateTime reviewDate;
  final int? productivityRating;
  final int? energyRating;
  final int? focusRating;
  final String? wentWell;
  final String? blockedBy;
  final DateTime createdAt;

  const DailyReviewDto({
    required this.id,
    required this.userId,
    required this.reviewDate,
    required this.productivityRating,
    required this.energyRating,
    required this.focusRating,
    required this.wentWell,
    required this.blockedBy,
    required this.createdAt,
  });

  factory DailyReviewDto.fromJson(Map<String, dynamic> j) => DailyReviewDto(
        id: j['id'] as String,
        userId: j['userId'] as String,
        reviewDate: DateTime.parse(j['reviewDate'] as String),
        productivityRating: j['productivityRating'] as int?,
        energyRating: j['energyRating'] as int?,
        focusRating: j['focusRating'] as int?,
        wentWell: j['wentWell'] as String?,
        blockedBy: j['blockedBy'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class DailyPlanItemDto {
  final String id;
  final String dailyPlanId;
  final String subjectId;
  final DateTime startTime;
  final DateTime endTime;
  final int? orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyPlanItemDto({
    required this.id,
    required this.dailyPlanId,
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyPlanItemDto.fromJson(Map<String, dynamic> j) => DailyPlanItemDto(
        id: j['id'] as String,
        dailyPlanId: j['dailyPlanId'] as String,
        subjectId: j['subjectId'] as String,
        startTime: DateTime.parse(j['startTime'] as String),
        endTime: DateTime.parse(j['endTime'] as String),
        orderIndex: j['orderIndex'] as int?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class DailyPlanDto {
  final String id;
  final String userId;
  final DateTime planDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DailyPlanItemDto> items;

  const DailyPlanDto({
    required this.id,
    required this.userId,
    required this.planDate,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory DailyPlanDto.fromJson(Map<String, dynamic> j) => DailyPlanDto(
        id: j['id'] as String,
        userId: j['userId'] as String,
        planDate: DateTime.parse(j['planDate'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        items: (j['items'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(DailyPlanItemDto.fromJson)
            .toList(),
      );
}

class SyncPullResponseDto {
  final DateTime serverTime;
  final DateTime since;
  final List<AreaDto> areas;
  final List<SubjectDto> subjects;
  final List<SessionDto> sessions;
  final List<DailyPlanDto> dailyPlans;
  final List<DailyReviewDto> dailyReviews;
  final List<CourseDto> courses;
  final List<ModuleDto> modules;
  final List<LessonDto> lessons;

  const SyncPullResponseDto({
    required this.serverTime,
    required this.since,
    required this.areas,
    required this.subjects,
    required this.sessions,
    required this.dailyPlans,
    required this.dailyReviews,
    required this.courses,
    required this.modules,
    required this.lessons,
  });

  factory SyncPullResponseDto.fromJson(Map<String, dynamic> j) =>
      SyncPullResponseDto(
        serverTime: DateTime.parse(j['serverTime'] as String),
        since: DateTime.parse(j['since'] as String),
        areas: (j['areas'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(AreaDto.fromJson)
            .toList(),
        subjects: (j['subjects'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(SubjectDto.fromJson)
            .toList(),
        sessions: (j['sessions'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(SessionDto.fromJson)
            .toList(),
        dailyPlans: (j['dailyPlans'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(DailyPlanDto.fromJson)
            .toList(),
        dailyReviews: (j['dailyReviews'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(DailyReviewDto.fromJson)
            .toList(),
        courses: (j['courses'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(CourseDto.fromJson)
            .toList(),
        modules: (j['modules'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(ModuleDto.fromJson)
            .toList(),
        lessons: (j['lessons'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(LessonDto.fromJson)
            .toList(),
      );
}