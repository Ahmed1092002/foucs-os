import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/entities.dart';
import '../data/subjects_repository.dart';

/// Family provider keyed by areaId. `null` means "all areas".
final subjectsControllerProvider = AsyncNotifierProvider.family<
    SubjectsController, List<SubjectEntity>, String?>(
  SubjectsController.new,
);

class SubjectsController
    extends FamilyAsyncNotifier<List<SubjectEntity>, String?> {
  @override
  Future<List<SubjectEntity>> build(String? areaId) async {
    return ref.read(subjectsRepositoryProvider).list(areaId: areaId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => future);
  }

  Future<SubjectEntity> create({
    required String areaId,
    required String name,
    String? description,
    String? color,
    double targetHours = 0,
    int priority = 0,
    DateTime? deadline,
  }) async {
    final created = await ref.read(subjectsRepositoryProvider).create(
          areaId: areaId,
          name: name,
          description: description,
          color: color,
          targetHours: targetHours,
          priority: priority,
          deadline: deadline,
        );
    await refresh();
    return created;
  }

  Future<void> delete(String id) async {
    await ref.read(subjectsRepositoryProvider).delete(id);
    await refresh();
  }
}