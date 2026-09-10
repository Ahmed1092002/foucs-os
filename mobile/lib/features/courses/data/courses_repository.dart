import 'package:dio/dio.dart';

import '../../../core/domain/courses.dart';
import '../../../core/error/app_failure.dart';
import '../../../data/remote/api_client.dart';
import '../../../data/remote/dto/dto.dart';

class CoursesRepository {
  CoursesRepository(this._api);
  final ApiClient _api;

  Future<List<CourseEntity>> list({String? subjectId}) async {
    try {
      final resp = await _api.get<List<dynamic>>(
        '/courses',
        query: subjectId != null ? {'subjectId': subjectId} : null,
      );
      return (resp.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(CourseDto.fromJson)
          .map(_toCourseEntity)
          .toList();
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<CourseEntity> getOne(String id) async {
    try {
      final resp = await _api.get<Map<String, dynamic>>('/courses/$id');
      return _toCourseEntity(CourseDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<CourseEntity> create({
    required String subjectId,
    required String name,
    String? description,
  }) async {
    try {
      final resp = await _api.post<Map<String, dynamic>>(
        '/courses',
        body: {
          'subjectId': subjectId,
          'name': name,
          if (description != null) 'description': description,
        },
      );
      return _toCourseEntity(CourseDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<CourseEntity> update(String id, {String? name, String? description}) async {
    try {
      final resp = await _api.patch<Map<String, dynamic>>(
        '/courses/$id',
        body: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
        },
      );
      return _toCourseEntity(CourseDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete('/courses/$id');
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  // ---- modules ----

  Future<List<ModuleEntity>> listModules(String courseId) async {
    try {
      final resp = await _api.get<List<dynamic>>('/courses/$courseId/modules');
      return (resp.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(ModuleDto.fromJson)
          .map(_toModuleEntity)
          .toList();
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<ModuleEntity> addModule(String courseId,
      {required String name, String? description}) async {
    try {
      final resp = await _api.post<Map<String, dynamic>>(
        '/courses/$courseId/modules',
        body: {'name': name, if (description != null) 'description': description},
      );
      return _toModuleEntity(ModuleDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<ModuleEntity> updateModule(String courseId, String moduleId,
      {String? name, String? description, int? orderIndex}) async {
    try {
      final resp = await _api.patch<Map<String, dynamic>>(
        '/courses/$courseId/modules/$moduleId',
        body: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (orderIndex != null) 'orderIndex': orderIndex,
        },
      );
      return _toModuleEntity(ModuleDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<void> deleteModule(String courseId, String moduleId) async {
    try {
      await _api.delete('/courses/$courseId/modules/$moduleId');
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  // ---- lessons ----

  Future<List<LessonEntity>> listLessons(String courseId, String moduleId) async {
    try {
      final resp = await _api.get<List<dynamic>>(
          '/courses/$courseId/modules/$moduleId/lessons');
      return (resp.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(LessonDto.fromJson)
          .map(_toLessonEntity)
          .toList();
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<LessonEntity> addLesson(String courseId, String moduleId,
      {required String name, String? description}) async {
    try {
      final resp = await _api.post<Map<String, dynamic>>(
        '/courses/$courseId/modules/$moduleId/lessons',
        body: {'name': name, if (description != null) 'description': description},
      );
      return _toLessonEntity(LessonDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<LessonEntity> updateLesson(
    String courseId,
    String moduleId,
    String lessonId, {
    String? name,
    String? description,
    int? orderIndex,
    LessonStatus? status,
  }) async {
    try {
      final resp = await _api.patch<Map<String, dynamic>>(
        '/courses/$courseId/modules/$moduleId/lessons/$lessonId',
        body: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (orderIndex != null) 'orderIndex': orderIndex,
          if (status != null) 'status': status.wire,
        },
      );
      return _toLessonEntity(LessonDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<void> deleteLesson(
      String courseId, String moduleId, String lessonId) async {
    try {
      await _api.delete('/courses/$courseId/modules/$moduleId/lessons/$lessonId');
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  // ---- upsert for sync ----

  /// Upsert course from sync pull. No API call — writes to local Drift directly
  /// via the database injection. For now we'll need the repo to take the database
  /// in constructor; but since this is a remote-only repo, we instead use a
  /// different pattern: the SyncService calls repository methods that write to
  /// the local DB. We'll add those methods here that use the same database.
  Future<void> upsertCourse(CourseDto dto) async {
    // Note: this repo is remote-only; we need the database instance.
    // For now, just implement the logic — the actual DB write will be done
    // by SyncService using the database directly (see SyncService._applyPull).
    // This method exists as a placeholder for when we unify the pattern.
    // No-op for remote repo; SyncService handles upsert directly.
  }

  Future<void> upsertModule(ModuleDto dto) async {
    // No-op for remote repo.
  }

  Future<void> upsertLesson(LessonDto dto) async {
    // No-op for remote repo.
  }

  // ---- progress ----

  Future<SubjectProgressEntity> subjectProgress(String subjectId) async {
    try {
      final resp = await _api.get<Map<String, dynamic>>(
        '/subjects/$subjectId/progress',
      );
      final d = SubjectProgressDto.fromJson(resp.data!);
      return SubjectProgressEntity(
        subjectId: d.subjectId,
        completedHours: d.completedHours,
        targetHours: d.targetHours,
        totalLessons: d.totalLessons,
        completedLessons: d.completedLessons,
        percentComplete: d.percentComplete,
      );
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  // ---- mappers ----

  CourseEntity _toCourseEntity(CourseDto d) => CourseEntity(
        id: d.id,
        userId: d.userId,
        subjectId: d.subjectId,
        name: d.name,
        description: d.description,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
        modules: d.modules.map(_toModuleEntity).toList(),
      );

  ModuleEntity _toModuleEntity(ModuleDto d) => ModuleEntity(
        id: d.id,
        courseId: d.courseId,
        name: d.name,
        description: d.description,
        orderIndex: d.orderIndex,
        lessons: d.lessons.map(_toLessonEntity).toList(),
      );

  LessonEntity _toLessonEntity(LessonDto d) => LessonEntity(
        id: d.id,
        moduleId: d.moduleId,
        name: d.name,
        description: d.description,
        status: LessonStatusWire.fromWire(d.status),
        orderIndex: d.orderIndex,
        completedAt: d.completedAt,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
      );
}