import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_failure.dart';
import '../../core/time/time_source.dart';
import '../../features/areas/data/areas_repository.dart';
import '../../features/courses/data/courses_repository.dart';
import '../../features/planner/data/daily_plans_repository.dart';
import '../../features/review/data/daily_reviews_repository.dart';
import '../../features/subjects/data/subjects_repository.dart';
import '../../features/sessions/data/sessions_repository.dart';
import '../local/database.dart';
import '../local/daos/sessions_dao.dart';
import '../local/tables/tables.dart';
import '../remote/api_client.dart';
import '../remote/dto/dto.dart';

/// Push pending mutations from the Drift outbox to the backend.
///
/// Phase 4 covers all three entities: areas, subjects, sessions.
/// Failure policy: best-effort with bounded retries. Rows that fail
/// repeatedly are flagged [SyncStatus.conflict] for the user to resolve
/// from a Settings screen (out of scope for MVP).
class SyncService {
  SyncService({
    required this.db,
    required this.dao,
    required this.areasRepo,
    required this.subjectsRepo,
    required this.sessionsRepo,
    required this.coursesRepo,
    required this.dailyPlansRepo,
    required this.dailyReviewsRepo,
    required this.apiClient,
    required this.timeSource,
  });
  final Database db;
  final SessionsDao dao;
  final AreasRepository areasRepo;
  final SubjectsRepository subjectsRepo;
  final SessionsRepository sessionsRepo;
  final CoursesRepository coursesRepo;
  final DailyPlansRepository dailyPlansRepo;
  final DailyReviewsRepository dailyReviewsRepo;
  final ApiClient apiClient;
  final TimeSource timeSource;

  /// Drain everything pending. Returns the number of items pushed.
  Future<int> drainOutbox() async {
    final pending = await db.select(db.outboxEntries).get();
    var pushed = 0;
    for (final row in pending) {
      try {
        await _pushOne(row.entity, row.op, row.entityId, row.payload);
        await _markSynced(row.entity, row.entityId);
        // Successfully pushed — drop the outbox row so we don't retry.
        await (db.delete(db.outboxEntries)..where((t) => t.id.equals(row.id))).go();
        pushed++;
      } on AppFailure {
        await (db.update(db.outboxEntries)..where((t) => t.id.equals(row.id)))
            .write(OutboxEntriesCompanion(attempts: Value(row.attempts + 1)));
      }
    }
    return pushed;
  }

  Future<void> _markSynced(String entity, String entityId) async {
    if (entity == 'area') {
      await (db.update(db.areas)..where((t) => t.id.equals(entityId))).write(
        const AreasCompanion(syncStatus: Value(SyncStatus.synced)),
      );
    } else if (entity == 'subject') {
      await (db.update(db.subjects)..where((t) => t.id.equals(entityId))).write(
        const SubjectsCompanion(syncStatus: Value(SyncStatus.synced)),
      );
    } else if (entity == 'session') {
      await dao.markSynced(entityId);
    }
  }

  Future<void> _pushOne(
      String entity, String op, String entityId, String payloadJson) async {
    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
    switch (entity) {
      case 'area':
        switch (op) {
          case 'create':
            await areasRepo.create(
              name: payload['name'] as String,
              color: payload['color'] as String,
              icon: payload['icon'] as String?,
            );
            break;
          case 'update':
            await areasRepo.update(
              entityId,
              name: payload['name'] as String?,
              color: payload['color'] as String?,
              icon: payload['icon'] as String?,
              archived: payload['archived'] as bool?,
            );
            break;
        }
        break;
      case 'subject':
        switch (op) {
          case 'create':
            await subjectsRepo.create(
              areaId: payload['areaId'] as String,
              name: payload['name'] as String,
              description: payload['description'] as String?,
              color: payload['color'] as String?,
              targetHours: (payload['targetHours'] as num).toDouble(),
              priority: payload['priority'] as int? ?? 0,
              deadline: payload['deadline'] != null
                  ? DateTime.parse(payload['deadline'] as String)
                  : null,
            );
            break;
          case 'update':
            await subjectsRepo.update(
              entityId,
              name: payload['name'] as String?,
              description: payload['description'] as String?,
              color: payload['color'] as String?,
              targetHours: (payload['targetHours'] as num?)?.toDouble(),
              priority: payload['priority'] as int?,
              deadline: payload['deadline'] != null
                  ? DateTime.parse(payload['deadline'] as String)
                  : null,
              status: payload['status'] as String?,
            );
            break;
        }
        break;
      case 'session':
        switch (op) {
          case 'create':
            await sessionsRepo.create(
              id: payload['id'] as String,
              subjectId: payload['subjectId'] as String,
              plannedDurationSeconds: payload['plannedDurationSeconds'] as int,
              startedAt: DateTime.parse(payload['startedAt'] as String),
              topic: payload['topic'] as String?,
              goalText: payload['goalText'] as String?,
            );
            break;
          case 'update':
            await sessionsRepo.patch(
              entityId,
              state: payload['state'] as String?,
              pausedIntervalsSeconds: payload['pausedIntervalsSeconds'] as int?,
              endedAt: payload['endedAt'] != null
                  ? DateTime.parse(payload['endedAt'] as String)
                  : null,
            );
            break;
          case 'complete':
            await sessionsRepo.complete(
              entityId,
              actualDurationSeconds: payload['actualDurationSeconds'] as int,
              pausedIntervalsSeconds: payload['pausedIntervalsSeconds'] as int,
              endedAt: DateTime.parse(payload['endedAt'] as String),
              goalResult: payload['goalResult'] as String?,
              focusRating: payload['focusRating'] as int?,
              energyRating: payload['energyRating'] as int?,
              notes: payload['notes'] as String?,
            );
            break;
          case 'cancel':
            await sessionsRepo.cancel(entityId);
            break;
        }
        break;
    }
  }

  /// Pull all server-side changes since `since` and upsert into local Drift.
  ///
  /// Returns the server's `serverTime` so the caller can persist it as the
  /// next `since` value. Conflict resolution: last-writer-wins by `updatedAt`.
  Future<DateTime> pull({DateTime? since}) async {
    final response = await apiClient.pull(since: since);
    await _applyPull(response);
    return response.serverTime;
  }

  Future<void> _applyPull(SyncPullResponseDto response) async {
    // Areas
    for (final a in response.areas) {
      await _upsertArea(a);
    }
    // Subjects
    for (final s in response.subjects) {
      await _upsertSubject(s);
    }
    // Courses (modules + lessons nested inside)
    for (final c in response.courses) {
      await coursesRepo.upsertCourse(c);
    }
    // Modules (also included in courses, but pull separately for flat sync)
    for (final m in response.modules) {
      await coursesRepo.upsertModule(m);
    }
    // Lessons
    for (final l in response.lessons) {
      await coursesRepo.upsertLesson(l);
    }
    // Sessions
    for (final s in response.sessions) {
      await _upsertSession(s);
    }
    // Daily Plans
    for (final p in response.dailyPlans) {
      await dailyPlansRepo.upsertPlan(p);
    }
    // Daily Reviews
    for (final r in response.dailyReviews) {
      await dailyReviewsRepo.upsertReview(r);
    }
  }

  Future<void> _upsertArea(AreaDto a) async {
    final existing = await (db.select(db.areas)..where((t) => t.id.equals(a.id))).getSingleOrNull();
    if (existing == null) {
      await db.into(db.areas).insert(AreasCompanion(
        id: Value(a.id),
        userId: Value(a.userId),
        name: Value(a.name),
        color: Value(a.color),
        icon: Value(a.icon),
        archivedAt: Value(a.archivedAt),
        createdAt: Value(a.createdAt),
        updatedAt: Value(a.updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ));
    } else if (a.updatedAt.isAfter(existing.updatedAt)) {
      await (db.update(db.areas)..where((t) => t.id.equals(a.id))).write(AreasCompanion(
        name: Value(a.name),
        color: Value(a.color),
        icon: Value(a.icon),
        archivedAt: Value(a.archivedAt),
        updatedAt: Value(a.updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ));
    }
  }

  Future<void> _upsertSubject(SubjectDto s) async {
    final existing = await (db.select(db.subjects)..where((t) => t.id.equals(s.id))).getSingleOrNull();
    if (existing == null) {
      await db.into(db.subjects).insert(SubjectsCompanion(
        id: Value(s.id),
        userId: Value(s.userId),
        areaId: Value(s.areaId),
        name: Value(s.name),
        description: Value(s.description),
        color: Value(s.color),
        targetHours: Value(s.targetHours),
        status: Value(s.status),
        priority: Value(s.priority),
        deadline: Value(s.deadline),
        createdAt: Value(s.createdAt),
        updatedAt: Value(s.updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ));
    } else if (s.updatedAt.isAfter(existing.updatedAt)) {
      await (db.update(db.subjects)..where((t) => t.id.equals(s.id))).write(SubjectsCompanion(
        name: Value(s.name),
        description: Value(s.description),
        color: Value(s.color),
        targetHours: Value(s.targetHours),
        status: Value(s.status),
        priority: Value(s.priority),
        deadline: Value(s.deadline),
        updatedAt: Value(s.updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ));
    }
  }

  Future<void> _upsertSession(SessionDto s) async {
    final existing = await (db.select(db.studySessions)..where((t) => t.id.equals(s.id))).getSingleOrNull();
    if (existing == null) {
      await db.into(db.studySessions).insert(StudySessionsCompanion(
        id: Value(s.id),
        userId: Value(''), // will be set by repo
        subjectId: Value(s.subjectId),
        topic: Value(s.topic),
        plannedDurationSeconds: Value(s.plannedDurationSeconds),
        actualDurationSeconds: Value(s.actualDurationSeconds),
        pausedIntervalsSeconds: Value(s.pausedIntervalsSeconds),
        startedAt: Value(s.startedAt),
        endedAt: Value(s.endedAt),
        state: Value(s.state),
        goalText: Value(s.goalText),
        goalResult: Value(s.goalResult),
        focusRating: Value(s.focusRating),
        energyRating: Value(s.energyRating),
        notes: Value(s.notes),
        createdAt: Value(s.createdAt),
        updatedAt: Value(s.updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ));
    } else if (s.updatedAt.isAfter(existing.updatedAt)) {
      await (db.update(db.studySessions)..where((t) => t.id.equals(s.id))).write(StudySessionsCompanion(
        subjectId: Value(s.subjectId),
        topic: Value(s.topic),
        plannedDurationSeconds: Value(s.plannedDurationSeconds),
        actualDurationSeconds: Value(s.actualDurationSeconds),
        pausedIntervalsSeconds: Value(s.pausedIntervalsSeconds),
        startedAt: Value(s.startedAt),
        endedAt: Value(s.endedAt),
        state: Value(s.state),
        goalText: Value(s.goalText),
        goalResult: Value(s.goalResult),
        focusRating: Value(s.focusRating),
        energyRating: Value(s.energyRating),
        notes: Value(s.notes),
        updatedAt: Value(s.updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ));
    }
  }
}