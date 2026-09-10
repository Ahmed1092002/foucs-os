import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/courses.dart';

/// Family-keyed controller for a single subject's courses.
class CoursesController
    extends FamilyAsyncNotifier<List<CourseEntity>, String> {
  @override
  Future<List<CourseEntity>> build(String subjectId) {
    return ref.read(coursesRepositoryProvider).list(subjectId: subjectId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => future);
  }

  Future<CourseEntity> create({required String name, String? description}) async {
    final created = await ref.read(coursesRepositoryProvider).create(
          subjectId: arg,
          name: name,
          description: description,
        );
    await refresh();
    return created;
  }

  Future<void> delete(String courseId) async {
    await ref.read(coursesRepositoryProvider).delete(courseId);
    await refresh();
  }
}

final coursesControllerProvider =
    AsyncNotifierProvider.family<CoursesController, List<CourseEntity>, String>(
  CoursesController.new,
);

/// Single course + its modules/lessons, refetched on demand.
final courseDetailProvider =
    FutureProvider.family<CourseEntity, String>((ref, id) async {
  return ref.watch(coursesRepositoryProvider).getOne(id);
});

/// Subject-level progress (R-S11).
final subjectProgressProvider =
    FutureProvider.family<SubjectProgressEntity, String>((ref, id) async {
  return ref.watch(coursesRepositoryProvider).subjectProgress(id);
});

/// Lightweight lesson-status setter that also invalidates the parent course.
class LessonsController extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String courseId) async {}

  Future<LessonEntity> setStatus({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required LessonStatus status,
  }) async {
    final updated = await ref.read(coursesRepositoryProvider).updateLesson(
          courseId,
          moduleId,
          lessonId,
          status: status,
        );
    ref.invalidate(courseDetailProvider(courseId));
    ref.invalidate(subjectProgressProvider);
    state = const AsyncData(null);
    return updated;
  }

  Future<void> addLesson({
    required String courseId,
    required String moduleId,
    required String name,
    String? description,
  }) async {
    await ref.read(coursesRepositoryProvider).addLesson(
          courseId,
          moduleId,
          name: name,
          description: description,
        );
    ref.invalidate(courseDetailProvider(courseId));
  }

  Future<void> addModule({
    required String courseId,
    required String name,
    String? description,
  }) async {
    await ref.read(coursesRepositoryProvider).addModule(
          courseId,
          name: name,
          description: description,
        );
    ref.invalidate(courseDetailProvider(courseId));
  }

  Future<void> deleteModule({
    required String courseId,
    required String moduleId,
  }) async {
    await ref.read(coursesRepositoryProvider).deleteModule(courseId, moduleId);
    ref.invalidate(courseDetailProvider(courseId));
  }
}

final lessonsControllerProvider =
    AsyncNotifierProvider.family<LessonsController, void, String>(
  LessonsController.new,
);